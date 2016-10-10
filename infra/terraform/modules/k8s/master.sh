#!/bin/bash -v

export KUBE_LOGGING_DESTINATION=elasticsearch
export KUBE_ENABLE_NODE_LOGGING=true

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni nginx
curl -sSL https://get.docker.com/ | sh
systemctl start docker

kubeadm init --token=${k8stoken}

kubectl apply -f https://git.io/weave-kube
daemonset "weave-net" created

sleep 10

git clone https://github.com/kubernetes/kubernetes

kubectl create -f kubernetes/cluster/addons/fluentd-elasticsearch/kibana-controller.yaml
kubectl create -f kubernetes/cluster/addons/fluentd-elasticsearch/kibana-service.yaml

kubectl create -f kubernetes/cluster/addons/fluentd-elasticsearch/es-controller.yaml
kubectl create -f kubernetes/cluster/addons/fluentd-elasticsearch/es-service.yaml

kubectl create -f kubernetes/cluster/addons/dashboard/dashboard-controller.yaml
kubectl create -f kubernetes/cluster/addons/dashboard/dashboard-service.yaml

kubectl proxy --port=8011 --api-prefix=/k8s-jf2js8 &

# expose kibana
cat <<EOF > /etc/nginx/sites-available/default
server {
listen 80;

   root /usr/share/nginx;
   index index.html index.htm;
   server_name localhost;

   location / {
      proxy_pass http://localhost:8011;
  }
}
EOF

/etc/init.d/nginx restart
