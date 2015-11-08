#!/bin/bash

REDCELL_ROOT=$(pwd)/..
source $REDCELL_ROOT/gce/config-env.sh

for node in $(seq 0 $NUM_MESOS_MASTER); do MESOS_MASTER_TAGS[$node]="${MESOS_MASTER_TAG}-$node"; done

function mesos-down {
    # Delete agents group.
    if gcloud compute instance-groups managed describe "${MESOS_AGENT_TAG}-group" --project "${PROJECT}" --zone "${ZONE}" &>/dev/null; then
        gcloud compute instance-groups managed delete --zone "${ZONE}" \
               --project "${PROJECT}" \
               --quiet \
               "${MESOS_AGENT_TAG}-group"
    fi

    # Delete agent instances template.
    local template_name="${MESOS_AGENT_TAG}-template"
    if gcloud compute instance-templates describe --project "${PROJECT}" "$template_name" &>/dev/null; then
        gcloud compute instance-templates delete \
               --project "${PROJECT}" \
               --quiet \
               "${template_name}"
    fi

    for i in "${!MESOS_MASTER_TAGS[@]}"; do
        # Delete master instances.
        if gcloud compute instances describe "${MESOS_MASTER_TAGS[$i]}" --zone "${ZONE}" --project "${PROJECT}" &>/dev/null; then
            gcloud compute instances delete \
                   --project "${PROJECT}" \
                   --quiet \
                   --delete-disks all \
                   --zone "${ZONE}" \
                   "${MESOS_MASTER_TAGS[$i]}"
        fi

        # Delete master disks.
        if gcloud compute disks describe "${MESOS_MASTER_TAGS[$i]}"-pd --zone "${ZONE}" --project "${PROJECT}" &>/dev/null; then
            gcloud compute instances delete \
                   --project "${PROJECT}" \
                   --quiet \
                   --delete-disks all \
                   --zone "${ZONE}" \
                   "${MESOS_MASTER_TAGS[$i]}-pd"
        fi

        # Delete static IP addresses.
        if gcloud compute addresses describe "${MESOS_MASTER_TAGS[$i]}-ip" --region "${REGION}" --project "${PROJECT}" &>/dev/null; then
            gcloud compute addresses delete \
                   --project "${PROJECT}" \
                   --region "${REGION}" \
                   --quiet \
                   "${MESOS_MASTER_TAGS[$i]}-ip"
        fi
    done
    
    local agents=( $(gcloud compute instances list --zone="${ZONE}" --regexp="${MESOS_AGENT_NAME}.*" --format=yaml | egrep "^name" | cut -d ' ' -f 2) )
    for i in "${!agents[@]}"; do
        gcloud compute instances delete \
               --project "${PROJECT}" \
               --quiet \
               --delete-disks boot \
               --zone "${ZONE}" \
               "${agents[$i]}"
    done

    if gcloud compute firewall-rules describe --project "${PROJECT}" "${MESOS_MASTER_TAG}-https" &>/dev/null; then
        gcloud compute firewall-rules delete  \
               --project "${PROJECT}" \
               --quiet \
               "${MESOS_MASTER_TAG}-https"
    fi

    if gcloud compute firewall-rules describe --project "${PROJECT}" "${MESOS_AGENT_TAG}-all" &>/dev/null; then
        gcloud compute firewall-rules delete  \
               --project "${PROJECT}" \
               --quiet \
               "${MESOS_AGENT_TAG}-all"
    fi
}

mesos-down
