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
