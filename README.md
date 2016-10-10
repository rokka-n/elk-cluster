# ELK example

Code to create an ELK (Elasticsearch, Logstash, Kibana) stack that allows a user to search by IP and Status code in nginx access logs.

# Create k8s cluster

Export var for token:

```
export K8STOKEN=$(python -c 'import random; print "%0x.%0x" % (random.SystemRandom().getrandbits(3*8), random.SystemRandom().getrandbits(8*8))')
```

Generate ssh key:

```
ssh-keygen -f k8s-test
```

Run plan and then apply with terraform:

```
terraform plan -var k8stoken="$K8STOKEN" -var k8s-ssh-key="$(cat k8s-test.pub)"
```

After apply you should see output with the DNS name:

```
Outputs:

master_dns = ec2-54-209-90-109.compute-1.amazonaws.com
```

Login with the key created above, you should see kubernetes cluster running:
(may take few min to download all docker images)

```
$ ssh ubuntu@$(terraform output master_dns) -i k8s-test

ubuntu@ip-10-200-2-196:~$ kubectl cluster-info

Kubernetes master is running at http://localhost:8080
```

# Kibana/ES

After terraform run is completed, kibana and k8s dashboards become available at the master DNS.

```
MASTER_DNS=$(terraform output master_dns)
echo $MASTER_DNS

Open in browser:
Dashboard: http://$MASTER_DNS/k8s-jf2js8/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/workload?namespace=default
Kibana: http://$MASTER_DNS/k8s-jf2js8/api/v1/proxy/namespaces/kube-system/services/kibana-logging/#/settings/indices/?_g=()
```

# TODO

Make nginx cluster to send logs to ES

Create ES/Kibana as standalone services, not as k8s addons

Security and authentication for k8s dashboard

Access to Kibana via ELB
