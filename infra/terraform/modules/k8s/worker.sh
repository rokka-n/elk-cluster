#!/bin/bash -v

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
curl -sSL https://get.docker.com/ | sh
systemctl start docker

# TODO: discovery IP of master node, wait till it is alive by probing periodically
export MASTER_IP="blah"

for i in {1..50}; do kubeadm join --token=${k8stoken} ${MASTER_IP} && break || sleep 15; done
