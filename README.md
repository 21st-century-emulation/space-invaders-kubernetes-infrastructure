# 21st Century 8080 - Kubernetes Config

This repository contains the helm chart to install all of the 8080 emulator components into an existing kubernetes cluster.

## Pre-requisites

In order to install the emulator you will need the following:

1. An existing kubernetes cluster with sufficient space for ~200 pods. It's highly recommended that you make use of a top tier cloud provider like [IBM](https://www.ibm.com/cloud/kubernetes-service) to keep performance high
2. (kubectl)[https://kubernetes.io/docs/tasks/tools/]
3. (helm 3)[https://helm.sh/docs/intro/install/]

## Usage

There is a single shell script which can be used to provision an entire cluster from scratch or to upgrade an existing cluster.

```bash
DB_PASSWORD=hunter2 NAMESPACE=emulator ./install.sh
```
