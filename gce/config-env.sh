CLOUD=gce
ZONE=${ZONE:-europe-west1-d}
REGION=${ZONE%-*}

PROJECT=${PROJECT:-ognitio-infrastructure}

NETWORK=${NETWORK:-redcell}

INSTANCE_PREFIX=${INSTANCE_PREFIX:-mesos}

MESOS_VERSION=0.25.0

# Debian only is currently supported.
OS_DISTRIBUTION=${OS_DISTRIBUTION:-debian}

CLUSTER_IP_RANGE="${CLUSTER_IP_RANGE:-10.240.0.0/16}"
APP_CLUSTER_IP_RANGE="${APP_CLUSTER_IP_RANGE:10.0.0.0/16}"

MESOS_MASTER_NAME=${INSTANCE_PREFIX}-master
MESOS_MASTER_TAG=${INSTANCE_PREFIX}-master
MESOS_MASTER_TYPE=${MESOS_MASTER_TYPE:-n1-standard-1}
MESOS_MASTER_DISK_SIZE=${MESOS_MASTER_DISK_SIZE:-20GB}
MESOS_MASTER_DISK_TYPE=${MESOS_MASTER_DISK_TYPE:-pd-ssd}
MESOS_MASTER_IMAGE=${MESOS_MASTER_IMAGE:-debian-8}
NUM_MESOS_MASTER=${NUM_MESOS_MASTER:-1}

MESOS_AGENT_NAME=${INSTANCE_PREFIX}-agent
MESOS_AGENT_TAG=${INSTANCE_PREFIX}-agent

# Mesos DNS environment configuration.
# Important: The number of dns replicas must not exceed the number of
# mesos masters present in the cluster as they coexist with the latter.
ENABLE_DNS=${ENABLE_CLUSTER_DNS:-true}
DNS_DOMAIN="mesos"
DNS_REPLICAS=1

ENABLE_CLUSTER_MONITORING=${ENABLE_CLUSTER_MONITORING:-true}
ELASTICSEARCH_LOGGING_REPLICAS=1
INFLUXDB_REPLICAS=1

ENABLE_MARATHON=${ENABLE_MARATHON:-true}
