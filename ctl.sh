#!/bin/bash

#NODE_EXPORTER
NODE_EXPORTER_TOLERATION=''

NODE_EXPORTER_LABELS=("node-role/system" "node-role/monitoring" "node-role/ingress" "node-role/frontend" "node-role/logging" "dedicated")
if kubectl -n monitoring get ds node-exporter; then
  for i in "${NODE_EXPORTER_LABELS[@]}"; do
    if ! kubectl -n monitoring get ds node-exporter -o go-template='{{range .spec.template.spec.tolerations}}{{if and .key .operator }}{{if and (eq .key "'$i'") (eq .operator "Exists")}}YES{{end}}{{end}}{{end}}' | grep YES > /dev/null; then
      NODE_EXPORTER_TOLERATION=$NODE_EXPORTER_TOLERATION' | .spec.template.spec.tolerations = .spec.template.spec.tolerations + [{"effect":"NoExecute","key":"'$i'","operator":"Exists"}]'
    fi
  done

  NODE_EXPORTER_TOLERATION=$(echo $NODE_EXPORTER_TOLERATION | cut -c 3-)
  if [ -n "$NODE_EXPORTER_TOLERATION" ]; then
    kubectl get ds/node-exporter -n monitoring -o json |jq "$NODE_EXPORTER_TOLERATION" | kubectl apply -f -
  fi
fi

#FLUENT
FLUENT_TOLERATION=''

FLUENT_LABELS=("node-role/system" "node-role/monitoring" "node-role/ingress" "node-role/frontend" "node-role/logging" "dedicated")
if kubectl -n kube-logging get ds fluentd; then
  for i in "${FLUENT_LABELS[@]}"; do
    if ! kubectl -n kube-logging get ds fluentd -o go-template='{{range .spec.template.spec.tolerations}}{{if and .key .operator }}{{if and (eq .key "'$i'") (eq .operator "Exists")}}YES{{end}}{{end}}{{end}}' | grep YES > /dev/null; then
      FLUENT_TOLERATION=$FLUENT_TOLERATION' | .spec.template.spec.tolerations = .spec.template.spec.tolerations + [{"effect":"NoExecute","key":"'$i'","operator":"Exists"}]'
    fi
  done

  FLUENT_TOLERATION=$(echo $FLUENT_TOLERATION | cut -c 3-)
  if [ -n "$FLUENT_TOLERATION" ]; then
    kubectl get ds/fluentd -n kube-logging -o json |jq "$FLUENT_TOLERATION" | kubectl apply -f -
  fi
fi 

