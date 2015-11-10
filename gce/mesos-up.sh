#!/bin/bash

REDCELL_ROOT=$(pwd)/..
source $REDCELL_ROOT/gce/config-env.sh
source $REDCELL_ROOT/gce/inventory-file-util.sh

ADMIN_PRIVATE_KEY="${HOME}/.ssh/${PROJECT}"

GCLOUD_CMD="gcloud compute"

function wait-for-jobs {
    local fail=0
    local job
    for job in $(jobs -p); do
        wait "${job}" || fail=$((fail + 1))
    done
    if (( fail != 0 )); then
        echo -e "\033[0;31m${fail} commands failed.  Exiting.\033[0m" >&2
    fi
}

function mesos-up {
    if ! $GCLOUD_CMD networks --project "${PROJECT}" describe "${NETWORK}" &>/dev/null; then
        echo -e "\033[0;32mCreating new network: ${NETWORK}\033[0m"
        $GCLOUD_CMD networks create --project "${PROJECT}" "${NETWORK}" \
               --range "${CLUSTER_IP_RANGE}"
    fi

    if ! $GCLOUD_CMD firewall-rules --project "${PROJECT}" describe "${NETWORK}-default-internal" &>/dev/null; then
        $GCLOUD_CMD firewall-rules create "${NETWORK}-default-internal" \
               --project "${PROJECT}" \
               --network "${NETWORK}" \
               --source-ranges "10.0.0.0/8" \
               --allow "tcp:1-65535,udp:1-65535,icmp" &
    fi

    if ! $GCLOUD_CMD firewall-rules describe --project "${PROJECT}" "${NETWORK}-default-ssh" &>/dev/null; then
        $GCLOUD_CMD firewall-rules create "${NETWORK}-default-ssh" \
               --project "${PROJECT}" \
               --network "${NETWORK}" \
               --source-ranges "0.0.0.0/0" \
               --allow "tcp:22" &
    fi

    echo -e "\033[0;32mStarting master and configuring firewalls.\033[0m"

    local -a mesos_master_tags
    for i in $(seq 1 $NUM_MESOS_MASTER); do mesos_master_tags[$i]="${MESOS_MASTER_TAG}-$i"; done

    # TODO(rzagabe): The following firewall rule might need to be reviewed.
    $GCLOUD_CMD firewall-rules create "${MESOS_MASTER_TAG}-https" \
           --project "${PROJECT}" \
           --network "${NETWORK}" \
           --target-tags "$(IFS=$','; echo "${mesos_master_tags[*]}")" \
           --allow tcp:443 &

    echo -e "\033[0;32mCreating mesos masters.\033[0m"

    for i in $(seq 1 $NUM_MESOS_MASTER); do
        $GCLOUD_CMD disks create "${mesos_master_tags[$i]}-pd" \
               --project "${PROJECT}" \
               --zone "${ZONE}" \
               --type "${MESOS_MASTER_DISK_TYPE}" \
               --size "${MESOS_MASTER_DISK_SIZE}"


        # $GCLOUD_CMD addresses create "${mesos_master_tags[$i]}-ip" \
        #        --project "${PROJECT}" \
        #        --region "${REGION}" -q

        # MASTER_RESERVED_IP=$($GCLOUD_CMD addresses describe "${mesos_master_tags[$i]}-ip" \
        #                             --project "${PROJECT}" \
        #                             --region "${REGION}" -q --format yaml | awk '/^address:/ { print $2 }')

        local preemptible_master=""
        if [[ "${PREEMPTIBLE_MASTER}" == true ]]; then
            preemptible_master="--preemptible --maintenance-policy TERMINATE"
        fi

        # --address "${MASTER_RESERVED_IP}" \
        $GCLOUD_CMD instances create "${mesos_master_tags[$i]}" \
               --project "${PROJECT}" \
               --zone "${ZONE}" \
               --machine-type "${MESOS_MASTER_TYPE}" \
               --image "${MESOS_MASTER_IMAGE}" \
               --tags "${mesos_master_tags[$i]}" \
               --network "${NETWORK}" \
               --can-ip-forward \
               --metadata-from-file startup-script=configure-instance.sh \
               --metadata admin_key="$(cat $ADMIN_PRIVATE_KEY.pub)" \
               --disk "name=${mesos_master_tags[$i]}-pd,device-name=master-pd,mode=rw,boot=no,auto-delete=no" &
    done

    $GCLOUD_CMD firewall-rules create "${MESOS_AGENT_TAG}-all" \
           --project "${PROJECT}" \
           --network "${NETWORK}" \
           --source-ranges "${CLUSTER_IP_RANGE}" \
           --target-tags "${MESOS_AGENT_TAG}" \
           --allow tcp,udp,icmp,esp,ah,sctp &

    wait-for-jobs

    echo -e "\033[0;32mCreating mesos agents.\033[0m"

    local template_name="${MESOS_AGENT_TAG}-template"

    local preemptible_agent=""
    if [[ "${PREEMPTIBLE_AGENT}" == true ]]; then
        preemptible_agent="--preemptible --maintenance-policy TERMINATE"
    fi
    
    $GCLOUD_CMD instance-templates create "$template_name" \
           --project "${PROJECT}" \
           --machine-type "${MESOS_AGENT_TYPE}" \
           --boot-disk-type "${MESOS_AGENT_DISK_TYPE}" \
           --boot-disk-size "${MESOS_AGENT_DISK_SIZE}" \
           --image "${MESOS_AGENT_IMAGE}" \
           --tags "${MESOS_AGENT_TAG}" \
           --metadata-from-file startup-script=configure-instance.sh \
           --metadata admin_key="$(cat $ADMIN_PRIVATE_KEY.pub)" \
           --network "${NETWORK}" \
           $preemptible_agent \
           --can-ip-forward >&2

    $GCLOUD_CMD instance-groups managed \
           create "${MESOS_AGENT_TAG}-group" \
           --project "${PROJECT}" \
           --zone "${ZONE}" \
           --base-instance-name "${MESOS_AGENT_TAG}" \
           --size "${NUM_CLUSTER_AGENTS}" \
           --template "$template_name" || true;

    $GCLOUD_CMD instance-groups managed wait-until-stable \
           "${MESOS_AGENT_TAG}-group" \
           --zone "${ZONE}" \
           --project "${PROJECT}" || true;

    # Generate Ansible inventory file
    echo -e "\033[0;32mGenerate Ansible inventory file: $PROJECT\033[0m"
    generate-inventory-file $REDCELL_ROOT/ansible/hosts

    sleep 10

    cd $REDCELL_ROOT/ansible
    ansible-playbook -u admin --private-key="${ADMIN_PRIVATE_KEY}" install.yml

    local master_external_ips=($($GCLOUD_CMD instances list --zone="${ZONE}" --regexp="${MESOS_MASTER_NAME}.*" --format=yaml | grep -i natip | sed 's/^ *//' | cut -d ' ' -f 2))
    echo -e "\033[0;32m${PROJECT} cluster is running. The masters are running at:"
    echo -e "\033[0;33m$(IFS=$','; echo "${master_external_ips[*]}")"
    echo -e "\033[0;32mThe admin keypair is located in $ADMIN_PRIVATE_KEY\033[0m"
}

# Generate admin private key
ssh-keygen -b 2048 -t rsa -f $ADMIN_PRIVATE_KEY -q -N ""

# Run mesos cluster
mesos-up
