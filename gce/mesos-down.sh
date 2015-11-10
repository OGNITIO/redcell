#!/bin/bash

REDCELL_ROOT=$(pwd)/..
source $REDCELL_ROOT/gce/config-env.sh

GCLOUD_CMD="gcloud compute"

function mesos-down {
    # Delete agents group.
    if $GCLOUD_CMD instance-groups managed describe "${MESOS_AGENT_TAG}-group" --project "${PROJECT}" --zone "${ZONE}" &>/dev/null; then
        $GCLOUD_CMD instance-groups managed delete --zone "${ZONE}" \
               --project "${PROJECT}" \
               --quiet \
               "${MESOS_AGENT_TAG}-group"
    fi

    # Delete agent instances template.
    local template_name="${MESOS_AGENT_TAG}-template"
    if $GCLOUD_CMD instance-templates describe --project "${PROJECT}" "$template_name" &>/dev/null; then
        $GCLOUD_CMD instance-templates delete \
               --project "${PROJECT}" \
               --quiet \
               "${template_name}"
    fi

    local -a mesos_master_tags
    for node in $(seq 0 $NUM_MESOS_MASTER); do mesos_master_tags[$node]="${MESOS_MASTER_TAG}-$node"; done

    for i in "${!mesos_master_tags[@]}"; do
        # Delete master instances.
        if $GCLOUD_CMD instances describe "${mesos_master_tags[$i]}" --zone "${ZONE}" --project "${PROJECT}" &>/dev/null; then
            $GCLOUD_CMD instances delete \
                   --project "${PROJECT}" \
                   --quiet \
                   --delete-disks all \
                   --zone "${ZONE}" \
                   "${mesos_master_tags[$i]}"
        fi

        # Delete master disks.
        if $GCLOUD_CMD disks describe "${mesos_master_tags[$i]}"-pd --zone "${ZONE}" --project "${PROJECT}" &>/dev/null; then
            $GCLOUD_CMD instances delete \
                   --project "${PROJECT}" \
                   --quiet \
                   --delete-disks all \
                   --zone "${ZONE}" \
                   "${mesos_master_tags[$i]}-pd"
        fi

        # Delete static IP addresses.
        if $GCLOUD_CMD addresses describe "${mesos_master_tags[$i]}-ip" --region "${REGION}" --project "${PROJECT}" &>/dev/null; then
            $GCLOUD_CMD addresses delete \
                   --project "${PROJECT}" \
                   --region "${REGION}" \
                   --quiet \
                   "${mesos_master_tags[$i]}-ip"
        fi
    done
    
    local agents=( $($GCLOUD_CMD instances list --zone="${ZONE}" --regexp="${MESOS_AGENT_NAME}.*" --format=yaml | egrep "^name" | cut -d ' ' -f 2) )
    for i in "${!agents[@]}"; do
        $GCLOUD_CMD instances delete \
               --project "${PROJECT}" \
               --quiet \
               --delete-disks boot \
               --zone "${ZONE}" \
               "${agents[$i]}"
    done

    if $GCLOUD_CMD firewall-rules describe --project "${PROJECT}" "${MESOS_MASTER_TAG}-https" &>/dev/null; then
        $GCLOUD_CMD firewall-rules delete  \
               --project "${PROJECT}" \
               --quiet \
               "${MESOS_MASTER_TAG}-https"
    fi

    if $GCLOUD_CMD firewall-rules describe --project "${PROJECT}" "${MESOS_AGENT_TAG}-all" &>/dev/null; then
        $GCLOUD_CMD firewall-rules delete  \
               --project "${PROJECT}" \
               --quiet \
               "${MESOS_AGENT_TAG}-all"
    fi

    echo -e "\033[0;32m${PROJECT} cluster is down.\033[0m"
}

# Shutdown mesos cluster
mesos-down
