---
title: "Kubernetes on the Cheap - Part 1"
date: 2019-11-16T17:49:17-08:00
draft: false
toc: false
images:
tags: 
  - untagged
---

How to run Kubernetes for less than $6 per month?

I wanted to play around with Kubernetes for personal learning, and even some personal projects. I wanted to deploy a website with a live backend, but I didn't really want to be bound to cPanel, or terrible performance issues on shared hosting providers. This was also an opportunity for me to learn more about deploying an application end2end and managing it myself. This post details the exact steps to deploy a Kubernetes cluster to Google Cloud Platform, and run a single, low-utilization application for about $5/mo. It includes all the pitfalls, gotchas, shortcuts, workarounds, optimizations, etc in order to make it work, step by step.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Create a GCP Account & Project](#create-a-gcp-account--project)
- [Create a GKE Cluster](#create-a-gke-cluster)
  - [Pre-emptible Instances](#pre-emptible-instances)
- [Optimizations](#optimizations)
  - [fluentd-gcp-scaler](#fluentd-gcp-scaler)
  - [kube-dns-autoscaler](#kube-dns-autoscaler)
- [Resource Utilization Overview](#resource-utilization-overview)
- [Deploy Nginx Ingress](#deploy-nginx-ingress)
- [Create a firewall rule to allow traffic to the nodes](#create-a-firewall-rule-to-allow-traffic-to-the-nodes)
- [Deploy a simple app](#deploy-a-simple-app)
- [Conclusion](#conclusion)

## Create a GCP Account & Project

1. You can create or select a GCP Project from the [Project Selector Page](https://console.cloud.google.com/projectselector2/home/dashboard).
2. Make sure that billing is enabled for your Google Cloud Platform project. [Learn how to confirm billing is enabled for your project](https://cloud.google.com/billing/docs/how-to/modify-project). 

For this article, I've created a new project called `kubernetes-on-the-cheap`. For the remainder of the article, I'll be showing you `gcloud` or `kubectl` commands to run instead of walking through how to do this from the UI, though it's also pretty simple from the UI, it just requires a few more steps and screenshots.

Unless otherwise noted, all commands listed will be run from the GCP Cloud Shell.

To reduce repetition, I've aliased `kubectl` to `k`

```bash
alias k=kubectl
```

or

```bash
echo "alias k=kubectl" >> $HOME/.bashrc
```

## Create a GKE Cluster

GKE (Google Kubernetes Engine) is actually FREE on GCP... well the master nodes are. You can create a cluster without any worker nodes at no cost. That's the next step. First, navigate to [https://console.cloud.google.com/kubernetes/list?project=kubernetes-on-the-cheap](https://console.cloud.google.com/kubernetes/list?project=kubernetes-on-the-cheap) but replacing the `project` with your own project name. Google has to enable the `Kubernetes Engine API`, and it takes a few minutes.

Here's the command to run, but you'll have to fill in a few things yourself. The important part to note here is that this creates a single-zone GKE cluster (for the master nodes). If you don't do this, when you create node groups, you'll be forced to have a minimum of 3 nodes (1 per zone). I couldn't find a way around there. You can read more about this in [the docs](https://cloud.google.com/kubernetes-engine/docs/concepts/regional-clusters). The main downside is that when the cluster upgrades, you won't be able to access the control plane. The data plane (where your apps run) is unaffected.

Most of the next commands can be run from the google cloud console via their website.

Run this locally, and copy the output (or visit the website below to get your home IP address)

```bash
MY_HOME_IP="$(curl https://ifconfig.co/ip)"
echo "MY_HOME_IP=${MY_HOME_IP}"
```

Run this from the Cloud Shell console

```bash
PROJECT_NAME="kubernetes-on-the-cheap"
REGION="us-west1"
ZONE_ID="a"
ZONE="${REGION}-${ZONE_ID}"

gcloud beta container \
  --project "${PROJECT_NAME}" \
  clusters create "hobby-1" \
  --zone "${ZONE}" \
  --no-enable-basic-auth \
  --release-channel "regular" \
  --machine-type "g1-small" \
  --image-type "COS" \
  --disk-type "pd-standard" \
  --disk-size "30" \
  --metadata disable-legacy-endpoints=true \
  --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
  --preemptible \
  --num-nodes "1" \
  --enable-stackdriver-kubernetes \
  --enable-ip-alias \
  --network "projects/${PROJECT_NAME}/global/networks/default" \
  --subnetwork "projects/${PROJECT_NAME}/regions/${REGION}/subnetworks/default" \
  --default-max-pods-per-node "110" \
  --enable-master-authorized-networks \
  --master-authorized-networks "${MY_HOME_IP}/32" \
  --addons HorizontalPodAutoscaling \
  --enable-autoupgrade \
  --enable-autorepair \
  --maintenance-window-start "2019-11-15T10:00:00Z" \
  --maintenance-window-end "2019-11-15T14:00:00Z" \
  --maintenance-window-recurrence "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH"
```

* `--project` - change this to your project name
* `hobby-1` - change this to a cluster name of your choosing
* `--zone "us-west1-a"` - I chose `us-west1-a` because it's the cheapest region in the US (`us-central1` is the same low price), and that's also where I live. I don't plan on running anything that would have any significant performance impact for users from say the east coast, so this is not much of concern. I'll talk more about this in the next section, [Zones, Regions, and other networking to consider](#zones-regions-and-other-network-to-consider).
* `--no-enable-basic-auth` - _REASONABLE DEFAULT_
* `--release-chanel "regular"` -  I chose to keep my cluster regularly upgraded, since this was a hobby cluster, I don't really mind, and it's may also later become a good exercise in managing availability.
* `--machine-type "g1-small"` - [a `g1-small` is $5.11 per month when pre-emptible](https://cloud.google.com/compute/vm-instance-pricing#sharedcore). More on [pre-emptible instances below](#pre-emptible-instances). As of this post, the `f1-micro` is too small to run while also enabling the stackdriver addon.
* `--image-type "COS"` - _REASONABLE DEFAULT_
* `--disk-type "pd-standard"` - _REASONABLE DEFAULT_
* `--disk-size 30` - _REASONABLE DEFAULT_
* `--metadata disable-legacy-endpoints=true` - this was a default setting for clusters > `1.12`
* `--scopes ...` - _REASONABLE DEFAULT_
* `--preemptible` - This is important, as stated above, the cost is significantly less. More on [pre-emptible instances below](#pre-emptible-instances)
* `--no-nodes "1"` - This will create 3 nodes (1 per zone) in the default node pool. We'll delete that node pool as soon as the cluster comes up, so don't worry about this much.
* `--enable-stackdriver-kubernetes` - Stackdriver is [mostly free](https://cloud.google.com/stackdriver/), if you use it sparingly, so let's enable this so we can monitor our cluster.
* `--enable-ip-alias` - _REASONABLE DEFAULT_
* `--network ...` - _REQUIRED_
* `--subnetwork ...` - _REQUIRED_
* `--default-max-pods-per-node "110"` - _REASONABLE DEFAULT_
* `--enable-master-authorized-networks` - This is to restrict who can access the master nodes (K8s API). The next setting will use your home IP address.
* `--master-authorized-networks "${MY_HOME_IP}/32"` - Restrict access to the K8s API to your home IP address. This can be updated on demand, and [I'll show you how to do that later](#updating-cluster-authorized-networks).
* `--addons HorizontalPodAutoscaling` - This is not needed, since you probably won't use it, but doesn't hurt.
* `--enable-autoupgrade` - I checked this cause with a regional cluster, I don't really want to upgrade manually.
* `--enable-autorepair` - Seems like a good idea.
* `--maintennce-window-*` - Choose what's right for you. For my purposes, I expect more traffic during the weekend, so I'm restricting maintence to 2AM on the weekdays.

This command will immediately create a cluster and a node pool with 3 nodes in it. That's a bit too much for my liking, so let's delete the default node pool, and recreate it so that there's only 1 node in it.

### Pre-emptible Instances

You can read more about preemptible instances from the offical docs:

[https://cloud.google.com/compute/docs/instances/preemptible](https://cloud.google.com/compute/docs/instances/preemptible)

## Optimizations

When the cluster comes up, you'll already have quite a few deployed pods on the cluster. If this was a large cluster, the defaults would probably be fine. But we are on a budget! So we need to modify some of these.

Some of this can be found in google's docs [small-cluster-tuning](https://cloud.google.com/kubernetes-engine/docs/how-to/small-cluster-tuning).

First, you'll need to authenticate to the cluster to run kubectl commands.

```bash
gcloud container clusters get-credentials hobby-1 --zone us-west1-a --project kubernetes-on-the-cheap
```

Here we can get a quick glance at what's running, and it's actual usage. Note that cpu/mem requests can and usually are greater than idle usage. The kubernetes schedule will refuse to deploy pods if the sum of requested resources is greater than the allocatable amount for that resource.

```txt
k -n kube-system top pods
NAME                                                        CPU(cores)   MEMORY(bytes)
event-exporter-v0.2.5-7df89f4b8f-bh7gj                      1m           16Mi
fluentd-gcp-scaler-54ccb89d5-x9w4n                          0m           32Mi
fluentd-gcp-v3.1.1-tmzdc                                    11m          134Mi
heapster-dbf95c595-5zg5m                                    1m           34Mi
kube-dns-5877696fb4-hwwtt                                   2m           27Mi
kube-dns-autoscaler-85f8bdb54-jhvsj                         1m           3Mi
kube-proxy-gke-hobby-1-default-pool-d97956f1-dzjm           1m           11Mi
metrics-server-v0.3.1-8d4c5db46-np6pl                       1m           16Mi
prometheus-to-sd-z2kw7                                      1m           11Mi
stackdriver-metadata-agent-cluster-level-684c9bb574-vkjhw   4m           17Mi
```

We'll be able to recover some of this (detailed below). But the rest is outside of our control, since these are GKE addons. Any modification to them simply gets reverted.

### fluentd-gcp-scaler

This is part of the StackDriver addon.

I believe this is similar to a `VerticalPodAutoscaler`, which I don't need, so here's how to disable it. Thankfully this is one of the deployments that doesn't mind being scaled to 0.

```bash
k -n kube-system scale deployment fluentd-gcp-scaler --replicas=0
```

### kube-dns-autoscaler

I don't need kube-dns to scale, so here's how to disable this.

```bash
k -n kube-system scale deployment kube-dns-autoscaler --replicas=0
```

## Resource Utilization Overview

| Resource |  Real | Requested | Allocatable | Remaining (Req-Alloc) |
|----------|------:|----------:|------------:|----------------------:|
| CPU      |   20m |      339m |        940m |                  601m |
| Mem      | 269Mi |     488Mi |      1220Mi |                 732Mi |

Much of this is coming from StackDriver addon pods. Maybe in another post, I'll look into an alternative solution, but for now, the remainder is more than enough for a small backend webserver.

## Deploy Nginx Ingress

Loadbalancers in GCP have a minimum of $0.60/day or $18/mo charge, so to avoid creating one, we need to setup nginx ingress in a special way.

If nginx ingress controller is set to use the host network, it can bind on port 80 and 443. This means that if we can create a route to any given node on the cluster, 80 and 443 will route to nginx.

The following manifests are derived from the [manifests online](https://kubernetes.github.io/ingress-nginx/deploy/), but differ in the following ways:

- No `service` resource is necessary (or desired)
- Remove the reference in the controller args to the `service` resource (that we aren't deploying)
- Set CPU/Mem resource requests
- Changing from `deployment` to `daemonset`
- Set `hostNetwork: true` and `dnsPolicy: ClusterFirstWithHostNet`

Run this to deploy the nginx ingress controller:

```bash
kubectl apply -f https://ghostsquad.me/files/nginx-ingress-controller.yaml
```

## Create a firewall rule to allow traffic to the nodes

```bash
TARGET_TAG=$(gcloud compute instances list --format=json | jq -r '.[0].tags.items[0]')

gcloud compute \
  --project=kubernetes-on-the-cheap \
  firewall-rules create http-ingress \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:80,tcp:443 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=$TARGET_TAG
```

## Deploy a simple app

```bash
EXT_IP=$(gcloud compute instances list --format=json | jq -r '.[0].networkInterfaces[0].accessConfigs[0].natIP')
echo $EXT_IP
HOST="test.${EXT_IP}.xip.io"
echo $HOST

curl https://ghostsquad.me/files/hello.yaml -o hello.yaml
sed -i "s/__HOST__/${HOST}/g" hello.yaml
kubectl apply -f hello.yaml
```

This works, but we have one major issue, and that's the node IP address will change every 24 hours because the instance is pre-emptible. (and also this means the `host` in the ingress will need to be updated every 24 hours)

We'll address this in the next part of this series!

## Conclusion

We've deployed a cluster to GKE running a single node. We deployed nginx ingress to run on the host network to avoid creating a load balancer, and we deployed a simple test application.

The problems which we need to address in the next part are:

- Setting up domain that points to the cluster, so that we don't have to update the ingress
- Setting up [external-dns](https://github.com/kubernetes-sigs/external-dns) to automatically update our domain with the list of IPs of hosts (when the get pre-empted)
- Setup [node-termination-handler](k8s-node-termination-handler) to further improve shutdowns
- Setup [SpotInst](https://spotinst.com/pricing/) in order to handle rolling instances on a regular basis in a controlled way, and scaling the cluster temporarily while doing so.
