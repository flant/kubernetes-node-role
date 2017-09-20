#!/bin/bash

KUBE_SYSTEM=$(kubectl get node -l node-role/system -o name |wc -l)
if ! kubectl -n kube-system get deploy kube-dns -o go-template='{{range .spec.template.spec.tolerations}}{{if and .key .operator }}{{if and (eq .key "node-role/system") (eq .operator "Exists")}}YES{{end}}{{end}}{{end}}' | grep YES > /dev/null; then
  DNS_TOLERATION=' | .spec.template.spec.tolerations = .spec.template.spec.tolerations + [{"effect":"NoExecute","key":"node-role/system","operator":"Exists"}]'
else
  DNS_TOLERATION=''
fi
if [[ $KUBE_SYSTEM -gt 0 ]]; then
  kubectl get deploy kube-dns -n kube-system  -o json |jq '.spec.template.spec.affinity ={"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"beta.kubernetes.io/arch","operator":"In","values":["amd64"]},{"key":"node-role/system","operator":"Exists"}]}]}}} | .spec.replicas ='"${KUBE_SYSTEM} ${DNS_TOLERATION}" | kubectl apply -f -
else
   kubectl get deploy kube-dns -n kube-system  -o json |jq '.spec.template.spec.affinity ={"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"beta.kubernetes.io/arch","operator":"In","values":["amd64"]}]}]}}} | .spec.replicas =1 '"${DNS_TOLERATION}" | kubectl apply -f -
fi


#PROXY
PROXY_TOLERATION=''

PROXY_LABELS=("node-role/system" "node-role/monitoring" "node-role/ingress" "node-role/frontend" "node-role/logging" "dedicated")
for i in "${PROXY_LABELS[@]}"; do
  if ! kubectl -n kube-system get ds kube-proxy -o go-template='{{range .spec.template.spec.tolerations}}{{if and .key .operator }}{{if and (eq .key "'$i'") (eq .operator "Exists")}}YES{{end}}{{end}}{{end}}' | grep YES > /dev/null; then
    PROXY_TOLERATION=$PROXY_TOLERATION' | .spec.template.spec.tolerations = .spec.template.spec.tolerations + [{"effect":"NoExecute","key":"'$i'","operator":"Exists"}]'
  fi
done

PROXY_TOLERATION=$(echo $PROXY_TOLERATION | cut -c 3-)
if [ -n "$PROXY_TOLERATION" ]; then
  kubectl get ds/kube-proxy -n kube-system -o json |jq "$PROXY_TOLERATION" | kubectl apply -f -
fi

#FLANNEL
FLANNEL_TOLERATION=''

FLANNEL_LABELS=("node-role/system" "node-role/monitoring" "node-role/ingress" "node-role/frontend" "node-role/logging" "dedicated")
for i in "${FLANNEL_LABELS[@]}"; do
  if ! kubectl -n kube-system get ds kube-flannel-ds -o go-template='{{range .spec.template.spec.tolerations}}{{if and .key .operator }}{{if and (eq .key "'$i'") (eq .operator "Exists")}}YES{{end}}{{end}}{{end}}' | grep YES > /dev/null; then
    FLANNEL_TOLERATION=$FLANNEL_TOLERATION' | .spec.template.spec.tolerations = .spec.template.spec.tolerations + [{"effect":"NoExecute","key":"'$i'","operator":"Exists"}]'
  fi
done

FLANNEL_TOLERATION=$(echo $FLANNEL_TOLERATION | cut -c 3-)
if [ -n "$FLANNEL_TOLERATION" ]; then
  kubectl get ds/kube-flannel-ds -n kube-system -o json |jq "$FLANNEL_TOLERATION" | kubectl apply -f -
fi


