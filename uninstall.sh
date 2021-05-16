#! /bin/bash
set -e

helm uninstall kibana -n monitoring
helm uninstall elasticsearch -n monitoring
helm uninstall emulator -n emulator
kubectl delete namespace monitoring
kubectl delete namespace emulator

linkerd jaeger uninstall | kubectl delete -f -
linkerd viz uninstall | kubectl delete -f -
linkerd install --ignore-cluster | kubectl delete -f -