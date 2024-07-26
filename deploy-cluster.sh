#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

export CONFIG_DIR=${CONFIG_DIR:-"${PWD}/config"}

export KIND_IMAGE=${KIND_IMAGE:-"kindest/node:v1.30.2@sha256:ecfe5841b9bee4fe9690f49c118c33629fa345e3350a0c67a5a34482a99d6bba"}
export KIND_NET=${KIND_NET:-"kind"}
export KIND_DISABLE_CNI=${KIND_DISABLE_CNI:-"false"}
export KIND_DISABLE_CNI=${KIND_DISABLE_CNI,,}
export HA_CLUSTER=${HA_CLUSTER:-"false"}

export ENABLE_APISNOOP=${ENABLE_APISNOOP:-"true"}
export ENABLE_APISNOOP=${ENABLE_APISNOOP,,}

echo "HA_CLUSTER: ${HA_CLUSTER}"
echo "ENABLE_APISNOOP: ${ENABLE_APISNOOP}"
echo "CONFIG_DIR: ${CONFIG_DIR}"

source "./lib/init.sh"

deploy::kind
[ ! "$ENABLE_APISNOOP" = "true" ] || deploy::apisnoop
check::kind::cni

[ ! "$HA_CLUSTER" = "true" ] || kubectl taint node --all node-role.kubernetes.io/control-plane:NoSchedule-
[ ! "$ENABLE_APISNOOP" = "true" ] || kubectl -n apisnoop wait --for=condition=Ready --selector="app.kubernetes.io/name=snoopdb" --timeout=600s pod
[ ! "$ENABLE_APISNOOP" = "true" ] || kubectl -n apisnoop wait --for=condition=Ready --selector="app.kubernetes.io/name=auditlogger" --timeout=600s pod
