#!/bin/bash

set -e

ca=$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 -w 0)
token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
server=https://kubernetes.default.svc
echo "
apiVersion: v1
kind: Config
clusters:
- name: default-cluster
  cluster:
    certificate-authority-data: ${ca}
    server: ${server}
contexts:
- name: default-context
  context:
    cluster: default-cluster
    namespace: istio-system
    user: default-user
current-context: default-context
users:
- name: default-user
  user:
    token: ${token}
" > sa.kubeconfig
kubectl config --kubeconfig=sa.kubeconfig use-context default-context 

versions=$(kubectl get --ignore-not-found=true deploy istio-galley -n istio-system  -o=jsonpath='{$.spec.template.spec.containers[*].image}')
if [[ $versions == *"1.4"* ]]; then
	kubectl delete --wait=true --timeout=20s deployment istio-galley -n istio-system
	kubectl delete --wait=true --timeout=20s serviceaccount istio-reader-service-account -n istio-system
	kubectl delete --wait=true --timeout=20s clusterrolebinding istio-reader
fi

# The webhook isn't always cleaned up after delete, so we need to delete on every install/upgrade
kubectl delete --ignore-not-found=true --wait=true --timeout=20s validatingwebhookconfigurations.admissionregistration.k8s.io istio-galley
sleep 2 # ensure webhook is gone or we get conflict errors

echo "istio webhook cleanup complete"
