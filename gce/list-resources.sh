#!/bin/bash

REDCELL_ROOT=$(pwd)/..
source $REDCELL_ROOT/gce/config-env.sh

gcloud compute instance-templates list --regexp="${INSTANCE_PREFIX}.*"
gcloud compute instance-groups list ${ZONE:+"--zone=${ZONE}"} --regexp="${INSTANCE_PREFIX}.*"
gcloud compute instances list ${ZONE:+"--zone=${ZONE}"} --regexp="${INSTANCE_PREFIX}.*"

gcloud compute disks list ${ZONE:+"--zone=${ZONE}"} --regexp="${INSTANCE_PREFIX}.*"
gcloud compute addresses list ${REGION:+"--region=${REGION}"} --regexp="a.*|${INSTANCE_PREFIX}.*"
