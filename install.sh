#! /bin/bash
if [[ -z "${GRAFANA_CHART_VERSION}" ]]; then
  GRAFANA_CHART_VERSION="6.8.0"
fi

# Add helm repos and update
helm repo add elastic https://helm.elastic.co
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Create all relevant namespaces if they don't exist
kubectl apply -f namespaces/emulator.yaml
kubectl apply -f namespaces/monitoring.yaml

# Install linkerd
linkerd check
if [[ $? -ne 0 ]]; then
  linkerd install | kubectl apply -f -
  kubectl wait --timeout=600s --for=condition=ready pod -l linkerd.io/workload-ns=linkerd -n linkerd
  linkerd viz install | kubectl apply -f -
  linkerd jaeger install | kubectl apply -f -
  kubectl wait --timeout=600s --for=condition=ready pod -l linkerd.io/extension=jaeger -n linkerd-jaeger
  kubectl wait --timeout=600s --for=condition=ready pod -l linkerd.io/extension=viz -n linkerd-viz
  linkerd check
fi

# Install elasticsearch for log storage and indexing (no persistence because yolo)
helm upgrade --install elasticsearch -n monitoring elastic/elasticsearch --set persistence.enabled=false
kubectl wait --timeout=600s --for=condition=ready pod -l app=elasticsearch-master -n monitoring

# Install kibana as a frontend for the elasticsearch instance
helm upgrade --install kibana -n monitoring elastic/kibana --set service.type=LoadBalancer
kubectl wait --timeout=600s --for=condition=ready pod -l app=kibana -n monitoring
KIBANA_IP=`kubectl get svc kibana-kibana -n monitoring --output jsonpath='{.status.loadBalancer.ingress[0].ip}'`

# Install fluentd for log aggregation
kubectl apply -f ./vendor/fluentd-config-map.yaml
kubectl apply -f ./vendor/fluentd-rbac.yaml
kubectl wait --timeout=600s --for=condition=ready pod -l k8s-app=fluentd-logging -n kube-system

# Install the actual application
helm upgrade --install emulator -n emulator -f helm/values.yaml ./helm
kubectl wait --timeout=600s --for=condition=ready pod -l app=space-invaders-ui -n emulator
SPACE_INVADERS_UI_IP=`kubectl get svc space-invaders-ui-service -n emulator --output jsonpath='{.status.loadBalancer.ingress[0].ip}'`

echo "Usage:"
echo "- Run linkerd viz dashboard to view the in cluster stats"
echo "- Visit http://${KIBANA_IP}:5601 to see the kibana log viewer"
echo "- Visit http://${SPACE_INVADERS_UI_IP} to see the space invaders UI"
echo "- Run curl -X POST -F 'romForm=@~/invaders.rom' http://${SPACE_INVADERS_UI_IP}/api/v1/cpu/start to start the application"