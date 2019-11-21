---
title: "Kubernetes on the Cheap - Part 2"
date: 2019-11-18T09:47:28-08:00
draft: false
toc: false
images:
tags: 
  - untagged
---

If you haven't read [part 1]({{< relref "posts/kubernetes-on-the-cheap-part-1.md" >}}) yet, that's a good place to start.

In the last post, we were left with a kubernetes cluster, and a test deployment that would break once every 24 hours, because of the preemptible instances we are using. So the highest priority right now is to fix that.

The next step is going to require you to own a domain. I recommend [namecheap](https://namecheap.com). You can get a `.com` for $8.88/yr for the first year, then $10.98/yr after that.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Create a DNS Zone](#create-a-dns-zone)
- [Deploy External DNS Controller](#deploy-external-dns-controller)
- [Edit the hello app to include the domain, and updated ttl](#edit-the-hello-app-to-include-the-domain-and-updated-ttl)

To make your life easier, I've variablized the commands in this post, so that you can simply set the variables, then copy/paste the commands without much trouble.

```bash
export PROJECT_NAME="kubernetes-on-the-cheap"
export CLUSTER_NAME="hobby-1"
export DOMAIN="foo.com"
```

## Create a DNS Zone

```bash
gcloud beta dns \
  managed-zones create "${DOMAIN}" \
  --description="${DOMAIN}" \
  --dns-name="${DOMAIN}."
```

## Deploy External DNS Controller

Some of these steps came from [knative](https://knative.dev/docs/serving/using-external-dns-on-gcp/)

1. Create a new service account for Cloud DNS admin role.

    ```bash
    export CLOUD_DNS_SA=cloud-dns-admin

    gcloud --project $PROJECT_NAME iam service-accounts \
        create $CLOUD_DNS_SA \
        --display-name "Service Account to support ACME DNS-01 challenge."
    ```

2. Bind the role `dns.admin` to the newly created service account.

    ```bash
    # Fully-qualified service account name also has project-id information.
    export CLOUD_DNS_SA_FQ=$CLOUD_DNS_SA@$PROJECT_NAME.iam.gserviceaccount.com

    gcloud projects add-iam-policy-binding $PROJECT_NAME \
        --member serviceAccount:$CLOUD_DNS_SA_FQ \
        --role roles/dns.admin
    ```

3. Download the secret key file for your service account.

    ```bash
    gcloud iam service-accounts keys create ~/credentials.json \
      --iam-account=$CLOUD_DNS_SA_FQ
    ```

4. Upload the service account credential to your cluster. This command uses the secret name `cloud-dns-key`, but you can choose a different name.

    ```bash
    export CLOUD_DNS_SECRET_NAME="cloud-dns-key"

    kubectl create secret generic "${CLOUD_DNS_SECRET_NAME}" \
      --from-file=credentials.json=$HOME/credentials.json
    ```
5. Deploy external dns. 
   
    ```bash
    curl {{< staticref "files/kubernetes-on-the-cheap-part-2/external-dns.yaml" >}} -o external-dns.yaml
    sed -i "s/__PROJECT_NAME__/${PROJECT_NAME}/g" external-dns.yaml
    sed -i "s/__CLUSTER_NAME__/${CLUSTER_NAME}/g" external-dns.yaml
    sed -i "s/__CLOUD_DNS_SECRET_NAME__/${CLOUD_DNS_SECRET_NAME}/g" external-dns.yaml
    kubectl apply -f external-dns.yaml
    ```

## Edit the hello app to include the domain, and updated ttl

```bash
curl {{< staticref "files/kubernetes-on-the-cheap-part-2/hello.yaml" >}} -o hello-part-2.yaml
sed -i "s/__DOMAIN__/${DOMAIN}/g" hello-part-2.yaml
kubectl apply -f hello-part-2.yaml
```


