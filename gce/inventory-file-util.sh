#!/bin/bash

REDCELL_ROOT=$(pwd)/..
source $REDCELL_ROOT/gce/config-env.sh

function add-inventory-hosts {
    local hosts=("${!1}")
    local file=$2
    for i in "${!hosts[@]}"; do
        echo -e "${hosts[$i]}" >> $file
    done
}

function generate-inventory-file {
    local master_external_ips=($(gcloud compute instances list --zone="${ZONE}" --regexp="${MESOS_MASTER_NAME}.*" --format=yaml | grep -i natip | sed 's/^ *//' | cut -d ' ' -f 2))
    local master_hostnames=($(gcloud compute instances list --zone="${ZONE}" --regexp="${MESOS_MASTER_NAME}.*" --format=yaml | egrep "^name" | cut -d ' ' -f 2))
    local agent_external_ips=($(gcloud compute instances list --zone="${ZONE}" --regexp="${MESOS_AGENT_NAME}.*" --format=yaml | grep -i natip | sed 's/^ *//' | cut -d ' ' -f 2))
    local agent_hostnames=($(gcloud compute instances list --zone="${ZONE}" --regexp="${MESOS_AGENT_NAME}.*" --format=yaml | egrep "^name" | cut -d ' ' -f 2))

    local inventory_file=$1

    local all_host_vars="cluster_name=$CLOUD"

    echo "# Ansible auto-generated inventory file (cloud: $CLOUD; project: $PROJECT)" > $inventory_file
    echo $'\n'"[all]" >> $inventory_file
    for i in "${!master_external_ips[@]}"; do
        local host_vars="mesos_mode=master mesos_master_quorum=$(((${#master_external_ips[@]}/2)+1)) cluster_name=${CLOUD}-${REGION}"
        echo -e "${master_external_ips[$i]}\t var_hostname=${master_hostnames[$i]} $host_vars" >> $inventory_file
    done
    for i in "${!agent_external_ips[@]}"; do
        mesos_attributes="mesos_attributes=os:${OS_DISTRIBUTION};machine_type:${MESOS_AGENT_TYPE};disk_type:${MESOS_AGENT_DISK_TYPE};zone:${ZONE};cloud:${CLOUD};level:0"
        weave_network="weave_network=$(IFS=$'\n'; echo "${agent_external_ips[*]}" | head -1)"
        weave_bridge_cidr="weave_bridge_cidr=10.2.0.$(($i+1))/16"

        local host_vars="$weave_bridge_cidr $mesos_attributes cluster_name=${CLOUD}-${REGION}"
        if [[ $i == 0 ]]; then
            echo -e "${agent_external_ips[$i]}\t var_hostname=${agent_hostnames[$i]} mesos_mode=slave $host_vars" >> $inventory_file
        else
            echo -e "${agent_external_ips[$i]}\t var_hostname=${agent_hostnames[$i]} mesos_mode=slave $weave_network $host_vars" >> $inventory_file
        fi
    done

    echo $'\n'"[zookeeper]" >> $inventory_file
    for i in "${!master_external_ips[@]}"; do
        echo -e "${master_external_ips[$i]}\t zoo_id=$i" >> $inventory_file
    done

    echo $'\n'"[mesos]" >> $inventory_file
    add-inventory-hosts master_external_ips[@] $inventory_file
    add-inventory-hosts agent_external_ips[@] $inventory_file

    echo $'\n'"[marathon]" >> $inventory_file
    add-inventory-hosts master_external_ips[@] $inventory_file

    echo $'\n'"[mesos-dns]" >> $inventory_file
    echo $(IFS=$'\n'; echo "${master_external_ips[*]}" | head -1) >> $inventory_file
}
