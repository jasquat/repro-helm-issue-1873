#!/bin/bash

function get_current_readiness_probe() {
  echo
  echo "readinessProbe according to kubectl get deploy: $(kubectl get deploy -n default -l release=repro-1873 -o jsonpath='{.items[*].spec.template.spec.containers[*].readinessProbe.httpGet.path}')"
  echo "readinessProbe according to helm get release: $(helm get repro-1873 | grep readinessProbePath | sort | uniq)"
}

function do_helm_update_with_readiness_probe_path() {
  echo -e "\nHELM UPGRADE $1"
  helm upgrade --install --namespace default --wait --set "readinessProbePath=$2" --timeout 40 repro-1873 .
  get_current_readiness_probe
}

function main() {
  helm delete --purge repro-1873

  do_helm_update_with_readiness_probe_path '1 Expected to Pass' '/'
  do_helm_update_with_readiness_probe_path '2 Expected to Fail' '/bad-path'
  do_helm_update_with_readiness_probe_path '3 Expected to Pass but Fails' '/'

  echo
  echo Three revisions exist in helm
  helm history repro-1873

  if kubectl rollout history deploy/repro-1873-repro-1873 --revision=3 >/dev/null 2>/dev/null; then
    echo DID NOT REPLICATE ISSUE
    echo helm was able to recover after a failed release
  else
    echo -e "\nOnly two revisions exist in kubernetes deployment"
    deployment_name=$(kubectl get deploy -n default -l release=repro-1873 -o jsonpath="{.items[0].metadata.name}")
    kubectl rollout history "deploy/$deployment_name"

    echo 'The third helm revision never had a corresponding replica set created because according to tiller logs "[kube] 2018/01/26 16:36:51 Looks like there are no changes for Deployment repro-1873-repro-1873"'
    echo These are the helm revisions represented in kubernetes replica sets
    kubectl get rs -n default -l release=repro-1873 -o jsonpath='{.items[*].metadata.annotations.deployment\.kubernetes\.io/revision}'; echo
    echo
    echo REPLICATED ISSUE
    echo helm was NOT able to recover after a failed release
  fi
}

main
