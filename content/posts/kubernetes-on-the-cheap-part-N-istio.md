---
title: "Kubernetes on the Cheap Part N Istio"
date: 2019-11-18T09:47:28-08:00
draft: true
toc: false
images:
tags: 
  - untagged
---

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Deploy Istio](#deploy-istio)

## Deploy Istio

In addition, if you enable the Istio addon, GCP will create a loadbalancer, which you'll need to delete. We also won't be able to modify resource usage. So let's deploy it ourselves.

> The general consensus is that the istio addon is meant more to be a demo, advanced users should install istio manually and use the unmanaged version. - the internet

So, we are going to install it manually. Here's the [reference documentation](https://istio.io/docs/setup/getting-started/) for further reading.

Installing IstioCTL is as simple as

```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.4.0 sh -
echo 'export PATH="$PATH:$HOME/istio-1.4.0/bin"' >> ~/.bashrc
```

> minimal: the minimal set of components necessary to use Istio’s traffic management features.

TODO: This installation could be better streamlined [https://istio.io/docs/setup/install/istioctl/#display-the-configuration-of-a-profile](https://istio.io/docs/setup/install/istioctl/#display-the-configuration-of-a-profile)

```bash
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)

istioctl manifest apply --set profile=minimal

istioctl manifest generate --set profile=minimal | kubectl delete -f -

k -n istio-system patch deployment istio-pilot --patch '{"spec":{"template":{"spec":{"$setElementOrder/containers":[{"name":"discovery"},{"name":"istio-proxy"}],"containers":[{"name":"discovery","resources":{"requests":{"cpu":"10m","memory":"100Mi"}}},{"name":"istio-proxy","resources":{"limits":null,"requests":null}}]}}}}'
```

In a later post (probably when we replace Stackdriver), we can install and play with some more components.