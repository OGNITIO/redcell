#!/bin/bash

REDCELL_ROOT=$(pwd)/..
source $REDCELL_ROOT/gce/config-env.sh
source $REDCELL_ROOT/gce/inventory-file-util.sh

for node in $(seq 1 $NUM_MESOS_MASTER); do MESOS_MASTER_TAGS[$node]="${MESOS_MASTER_TAG}-$node"; done

function wait-for-jobs {
    local fail=0
    local job
    for job in $(jobs -p); do
        wait "${job}" || fail=$((fail + 1))
    done
    if (( fail != 0 )); then
        echo -e "${color_red}${fail} commands failed.  Exiting.${color_norm}" >&2
    fi
}

function mesos-up {
    if ! gcloud compute networks --project "${PROJECT}" describe "${NETWORK}" &>/dev/null; then
        echo "Creating new network: ${NETWORK}"
        gcloud compute networks create --project "${PROJECT}" "${NETWORK}" \
               --range "${CLUSTER_IP_RANGE}"
    fi

    if ! gcloud compute firewall-rules --project "${PROJECT}" describe "${NETWORK}-default-internal" &>/dev/null; then
        gcloud compute firewall-rules create "${NETWORK}-default-internal" \
               --project "${PROJECT}" \
               --network "${NETWORK}" \
               --source-ranges "10.0.0.0/8" \
               --allow "tcp:1-65535,udp:1-65535,icmp" &
    fi

    if ! gcloud compute firewall-rules describe --project "${PROJECT}" "${NETWORK}-default-ssh" &>/dev/null; then
        gcloud compute firewall-rules create "${NETWORK}-default-ssh" \
               --project "${PROJECT}" \
               --network "${NETWORK}" \
               --source-ranges "0.0.0.0/0" \
               --allow "tcp:22" &
    fi

    echo "Starting master and configuring firewalls."

    # TODO(rzagabe): The following firewall rule might need to be reviewed.
    gcloud compute firewall-rules create "${MESOS_MASTER_TAG}-https" \
           --project "${PROJECT}" \
           --network "${NETWORK}" \
           --target-tags "$(IFS=$','; echo "${MESOS_MASTER_TAGS[*]}")" \
           --allow tcp:443 &

    echo "Creating mesos masters."

    for node in $(seq 1 $NUM_MESOS_MASTER); do
        gcloud compute disks create "${MESOS_MASTER_TAGS[$node]}-pd" \
               --project "${PROJECT}" \
               --zone "${ZONE}" \
               --type "${MESOS_MASTER_DISK_TYPE}" \
               --size "${MESOS_MASTER_DISK_SIZE}"


        # gcloud compute addresses create "${MESOS_MASTER_TAGS[$node]}-ip" \
        #        --project "${PROJECT}" \
        #        --region "${REGION}" -q

        # MASTER_RESERVED_IP=$(gcloud compute addresses describe "${MESOS_MASTER_TAGS[$node]}-ip" \
        #                             --project "${PROJECT}" \
        #                             --region "${REGION}" -q --format yaml | awk '/^address:/ { print $2 }')

        local preemptible_master=""
        if [[ "${PREEMPTIBLE_MASTER}" == true ]]; then
            preemptible_master="--preemptible --maintenance-policy TERMINATE"
        fi

        # --address "${MASTER_RESERVED_IP}" \
        gcloud compute instances create "${MESOS_MASTER_TAGS[$node]}" \
               --project "${PROJECT}" \
               --zone "${ZONE}" \
               --machine-type "${MESOS_MASTER_TYPE}" \
               --image "${MESOS_MASTER_IMAGE}" \
               --tags "${MESOS_MASTER_TAGS[$node]}" \
               --network "${NETWORK}" \
               --can-ip-forward \
               --metadata-from-file startup-script=configure-instance.sh \
               --metadata admin_key="$(cat $1)" \
               --disk "name=${MESOS_MASTER_TAGS[$node]}-pd,device-name=master-pd,mode=rw,boot=no,auto-delete=no" &
    done

    gcloud compute firewall-rules create "${MESOS_AGENT_TAG}-all" \
           --project "${PROJECT}" \
           --network "${NETWORK}" \
           --source-ranges "${CLUSTER_IP_RANGE}" \
           --target-tags "${MESOS_AGENT_TAG}" \
           --allow tcp,udp,icmp,esp,ah,sctp &

    wait-for-jobs

    echo "Creating mesos agents."

    local template_name="${MESOS_AGENT_TAG}-template"

    local preemptible_agent=""
    if [[ "${PREEMPTIBLE_AGENT}" == true ]]; then
        preemptible_agent="--preemptible --maintenance-policy TERMINATE"
    fi
    
    gcloud compute instance-templates create "$template_name" \
           --project "${PROJECT}" \
           --machine-type "${MESOS_AGENT_TYPE}" \
           --boot-disk-type "${MESOS_AGENT_DISK_TYPE}" \
           --boot-disk-size "${MESOS_AGENT_DISK_SIZE}" \
           --image "${MESOS_AGENT_IMAGE}" \
           --tags "${MESOS_AGENT_TAG}" \
           --metadata-from-file startup-script=configure-instance.sh \
           --metadata admin_key="$(cat $1)" \
           --network "${NETWORK}" \
           $preemptible_agent \
           --can-ip-forward >&2

    gcloud compute instance-groups managed \
           create "${MESOS_AGENT_TAG}-group" \
           --project "${PROJECT}" \
           --zone "${ZONE}" \
           --base-instance-name "${MESOS_AGENT_TAG}" \
           --size "${NUM_CLUSTER_AGENTS}" \
           --template "$template_name" || true;

    gcloud compute instance-groups managed wait-until-stable \
           "${MESOS_AGENT_TAG}-group" \
           --zone "${ZONE}" \
           --project "${PROJECT}" || true;

    # Generate Ansible inventory file
    generate-inventory-file $REDCELL_ROOT/ansible/hosts
}

# run mesos cluster
mesos-up $1
