#!/bin/bash

REDCELL_ROOT=$(pwd)/..
source $REDCELL_ROOT/gce/config-env.sh

function add-inventory-masters {
    local file=$1
    local include_hostname=$3
    for i in "${!MASTER_EXTERNAL_IPS[@]}"; do
        if [[ $include_hostname == "true" ]]; then
            echo "${MASTER_EXTERNAL_IPS[$i]} var_hostname=${MASTER_HOSTNAMES[$i]} $2" >> $file
        else
            echo "${MASTER_EXTERNAL_IPS[$i]} $2" >> $file
        fi
    done
}

function add-inventory-agents {
    local file=$1
    local include_hostname=$3
    for i in "${!AGENT_EXTERNAL_IPS[@]}"; do
        if [[ $include_hostname == "true" ]]; then
            echo "${AGENT_EXTERNAL_IPS[$i]} var_hostname=${AGENT_HOSTNAMES[$i]} $2" >> $file
        else
            echo "${AGENT_EXTERNAL_IPS[$i]} $2" >> $file
        fi
    done
}

function generate-inventory-file {
    echo "Generate Ansible inventory file: $PROJECT"

    MASTER_EXTERNAL_IPS=($(gcloud compute instances list --zone="${ZONE}" --regexp="${MESOS_MASTER_NAME}.*" --format=yaml | grep -i natip | sed 's/^ *//' | cut -d ' ' -f 2))
    MASTER_HOSTNAMES=($(gcloud compute instances list --zone="${ZONE}" --regexp="${MESOS_MASTER_NAME}.*" --format=yaml | egrep "^name" | cut -d ' ' -f 2))
    AGENT_EXTERNAL_IPS=($(gcloud compute instances list --zone="${ZONE}" --regexp="${MESOS_AGENT_NAME}.*" --format=yaml | grep -i natip | sed 's/^ *//' | cut -d ' ' -f 2))
    AGENT_HOSTNAMES=($(gcloud compute instances list --zone="${ZONE}" --regexp="${MESOS_AGENT_NAME}.*" --format=yaml | egrep "^name" | cut -d ' ' -f 2))

    local inventory_file=$1

    echo "# Ansible auto-generated inventory file (cloud: $CLOUD; project: $PROJECT)" > $inventory_file
    echo $'\n'"[all]" >> $inventory_file
    add-inventory-masters $inventory_file "ansible_ssh_user=rootie" true
    add-inventory-agents $inventory_file "ansible_ssh_user=rootie" true

    echo $'\n'"[zookeeper]" >> $inventory_file
    for i in "${!MASTER_EXTERNAL_IPS[@]}"; do
        echo "${MASTER_EXTERNAL_IPS[$i]} zoo_id=$i" >> $inventory_file
    done

    echo $'\n'"[mesos-master]" >> $inventory_file
    add-inventory-masters $inventory_file "ansible_ssh_user=rootie" false

    echo $'\n'"[mesos-slave]" >> $inventory_file
    for i in "${!AGENT_EXTERNAL_IPS[@]}"; do
        agent_attributes="attributes=os:${OS_DISTRIBUTION};machine_type:${MESOS_AGENT_TYPE};disk_type:${MESOS_AGENT_DISK_TYPE};zone:${ZONE};cloud:${CLOUD};level:0"
        weave_network="weave_network=$(IFS=$'\n'; echo "${AGENT_EXTERNAL_IPS[*]}" | head -1)"
        weave_bridge_cidr="weave_bridge_cidr=10.2.0.$(($i+1))/16"
        if [[ $i == 0 ]]; then
            echo "${AGENT_EXTERNAL_IPS[$i]} ansible_ssh_user=rootie $weave_bridge_cidr $agent_attributes" >> $inventory_file
        else
            echo "${AGENT_EXTERNAL_IPS[$i]} ansible_ssh_user=rootie $weave_network $weave_bridge_cidr $agent_attributes" >> $inventory_file
        fi
    done

    echo $'\n'"[marathon]" >> $inventory_file
    add-inventory-masters $inventory_file "ansible_ssh_user=rootie" false

    echo $'\n'"[mesos-dns]" >> $inventory_file
    echo $(IFS=$'\n'; echo "${MASTER_EXTERNAL_IPS[*]}" | head -1) >> $inventory_file
}
