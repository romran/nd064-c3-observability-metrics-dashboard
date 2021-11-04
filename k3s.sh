#!/bin/bash
chmod 755 /tmp/
chmod +x /tmp/vagrant-shell
    
echo "**** Begin installing k3s"
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.19.5+k3s1 K3S_KUBECONFIG_MODE="644" sh -
echo "**** End installing k3s"

echo "**** Begin installing helm"
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash 
echo "**** End installing helm"

echo "**** Begin installing prometheus"
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm repo add stable https://kubernetes-charts.storage.googleapis.com # this is deprecated
helm repo add stable https://charts.helm.sh/stable
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --kubeconfig /etc/rancher/k3s/k3s.yaml
echo "**** End installing prometheus"

echo "**** Test monitoring services"
kubectl get pods,svc --namespace=monitoring
kubectl port-forward service/prometheus-grafana --address 0.0.0.0 3000:80 -n monitoring

echo "**** Begin installing jaeger"
kubectl create namespace observability

# jaegertracing.io_jaegers_crd.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/crds/jaegertracing.io_jaegers_crd.yaml
# service_account.yaml
kubectl create -n observability -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/service_account.yaml
# role.yaml
kubectl create -n observability -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role.yaml
# role_binding.yaml
kubectl create -n observability -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role_binding.yaml
# operator.yaml
kubectl create -n observability -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/operator.yaml

# cluster_role.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/cluster_role.yaml
# cluster_role_binding.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/cluster_role_binding.yaml

echo "**** Test observability services"
kubectl get deployments jaeger-operator -n observability
kubectl get pods,svc -n observability
#kubectl proxy --address='0.0.0.0' /dev/null &
