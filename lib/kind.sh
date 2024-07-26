#!/usr/bin/env bash


deploy::kind() {
    echo "deploy::kind"

    if kind::cluster::exists "${KIND_NET}" ; then
        echo "cluster \"${KIND_NET}\" already exists"
        exit 2
    fi

    cd ${CONFIG_DIR}/kind || exit

    cat header.yaml > kind_config.yaml
    [ ! "$ENABLE_APISNOOP" = "true" ] || cat kubeadmConfigPatches.yaml >> kind_config.yaml
    cat nodes.yaml >> kind_config.yaml

    if [[ "${HA_CLUSTER}" == "true" ]]; then
      [ ! "$ENABLE_APISNOOP" = "true" ] || cat ha-cluster-apisnoop-true.yaml >> kind_config.yaml
      [ ! "$ENABLE_APISNOOP" = "false" ] || cat ha-cluster-apisnoop-false.yaml >> kind_config.yaml
    else
      [ ! "$ENABLE_APISNOOP" = "true" ] || cat cluster-apisnoop-true.yaml >> kind_config.yaml
      [ ! "$ENABLE_APISNOOP" = "false" ] || cat cluster-apisnoop-false.yaml >> kind_config.yaml
    fi

    cat kind_config.yaml
    kind create cluster --config=kind_config.yaml --image=${KIND_IMAGE}
    cd - || exit

    # Print the k8s version for verification
    kubectl version
}


kind::cluster::exists() {
  kind get clusters | grep -q "$1"
}


check::kind::cni() {
  echo "check::kind::cni"

  # wait until coredns is running
  kubectl -n kube-system wait --for=condition=Ready --selector="k8s-app=kube-dns" --timeout=600s pod
}
