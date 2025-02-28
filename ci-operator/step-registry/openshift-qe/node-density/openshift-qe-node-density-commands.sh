#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -x
cat /etc/os-release
oc config view
oc projects
python --version
pushd /tmp
python -m virtualenv ./venv_qe
source ./venv_qe/bin/activate

ES_PASSWORD=$(cat "/secret/password")
ES_USERNAME=$(cat "/secret/username")

git clone https://github.com/cloud-bulldozer/e2e-benchmarking --depth=1
pushd e2e-benchmarking/workloads/kube-burner
export WORKLOAD=node-density
current_worker_count=$(oc get nodes --no-headers -l node-role.kubernetes.io/worker --output jsonpath="{.items[?(@.status.conditions[-1].type=='Ready')].status.conditions[-1].type}" | wc -w | xargs)
export NODE_COUNT=$(($current_worker_count))
export PODS_PER_NODE=230
export POD_READY_THRESHOLD=120000ms
export GEN_CSV=true
export COMPARISON_CONFIG="clusterVersion.json podLatency.json containerMetrics.json kubelet.json etcd.json crio.json nodeMasters-max.json nodeWorkers.json"

export CLEANUP_WHEN_FINISH=true

export ES_SERVER="https://$ES_USERNAME:$ES_PASSWORD@search-ocp-qe-perf-scale-test-elk-hcm7wtsqpxy7xogbu72bor4uve.us-east-1.es.amazonaws.com"

./run.sh
