#!/bin/bash

REDCELL_ROOT=$(pwd)/..
source $REDCELL_ROOT/gce/config-env.sh

function add-inventory-masters {
    local file=$1
    local include_hostname=$3
    for i in "${!MASTER_EXTERNAL_IPS[@]}"; do
        echo -e "${MASTER_EXTERNAL_IPS[$i]}" >> $file
    done
}

function add-inventory-agents {
    local file=$1
    local include_hostname=$3
    for i in "${!AGENT_EXTERNAL_IPS[@]}"; do
        echo -e "${AGENT_EXTERNAL_IPS[$i]}" >> $file
    done
}

function generate-inventory-file {
    echo "Generate Ansible inventory file: $PROJECT"

    MASTER_EXTERNAL_IPS=($(gcloud compute instances list --zone="${ZONE}" --regexp="${MESOS_MASTER_NAME}.*" --format=yaml | grep -i natip | sed 's/^ *//' | cut -d ' ' -f 2))
    MASTER_HOSTNAMES=($(gcloud compute instances list --zone="${ZONE}" --regexp="${MESOS_MASTER_NAME}.*" --format=yaml | egrep "^name" | cut -d ' ' -f 2))
    AGENT_EXTERNAL_IPS=($(gcloud compute instances list --zone="${ZONE}" --regexp="${MESOS_AGENT_NAME}.*" --format=yaml | grep -i natip | sed 's/^ *//' | cut -d ' ' -f 2))
    AGENT_HOSTNAMES=($(gcloud compute instances list --zone="${ZONE}" --regexp="${MESOS_AGENT_NAME}.*" --format=yaml | egrep "^name" | cut -d ' ' -f 2))

    local inventory_file=$1

    local all_host_vars="cluster_name=$CLOUD"

    echo "# Ansible auto-generated inventory file (cloud: $CLOUD; project: $PROJECT)" > $inventory_file
    echo $'\n'"[all]" >> $inventory_file
    for i in "${!MASTER_EXTERNAL_IPS[@]}"; do
        local host_vars="mesos_mode=master mesos_master_quorum=$(((${#MASTER_EXTERNAL_IPS[@]}/2)+1)) cluster_name=${CLOUD}-${REGION}"
        echo -e "${MASTER_EXTERNAL_IPS[$i]}\t var_hostname=${MASTER_HOSTNAMES[$i]} $host_vars" >> $inventory_file
    done
    for i in "${!AGENT_EXTERNAL_IPS[@]}"; do
        mesos_attributes="mesos_attributes=os:${OS_DISTRIBUTION};machine_type:${MESOS_AGENT_TYPE};disk_type:${MESOS_AGENT_DISK_TYPE};zone:${ZONE};cloud:${CLOUD};level:0"
        weave_network="weave_network=$(IFS=$'\n'; echo "${AGENT_EXTERNAL_IPS[*]}" | head -1)"
        weave_bridge_cidr="weave_bridge_cidr=10.2.0.$(($i+1))/16"

        local host_vars="$weave_bridge_cidr $mesos_attributes cluster_name=${CLOUD}-${REGION}"
        if [[ $i == 0 ]]; then
            echo -e "${AGENT_EXTERNAL_IPS[$i]}\t var_hostname=${AGENT_HOSTNAMES[$i]} mesos_mode=slave $host_vars" >> $inventory_file
        else
            echo -e "${AGENT_EXTERNAL_IPS[$i]}\t var_hostname=${AGENT_HOSTNAMES[$i]} mesos_mode=slave $weave_network $host_vars" >> $inventory_file
        fi
    done

    echo $'\n'"[zookeeper]" >> $inventory_file
    for i in "${!MASTER_EXTERNAL_IPS[@]}"; do
        echo -e "${MASTER_EXTERNAL_IPS[$i]}\t zoo_id=$i" >> $inventory_file
    done

    echo $'\n'"[mesos]" >> $inventory_file
    add-inventory-masters $inventory_file
    add-inventory-agents $inventory_file

    echo $'\n'"[marathon]" >> $inventory_file
    add-inventory-masters $inventory_file

    echo $'\n'"[mesos-dns]" >> $inventory_file
    echo $(IFS=$'\n'; echo "${MASTER_EXTERNAL_IPS[*]}" | head -1) >> $inventory_file
}
