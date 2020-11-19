#!/bin/bash

# Install minikube and kubectl the same k8s minor version : v1.16.2
curl -Lo minikube https://github.com/kubernetes/minikube/releases/download/v1.5.2/minikube-linux-amd64 && chmod +x minikube && sudo mv ./minikube /usr/local/bin/
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.16.2/bin/linux/amd64/kubectl && chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/

# Run minikube and wait 
minikube start --cpus 2 --memory 4096
minikube addons enable ingress


sleep 300

# Set the release version variable for operator-sdk
RELEASE_VERSION=v0.11.0
curl -LO https://github.com/operator-framework/operator-sdk/releases/download/${RELEASE_VERSION}/operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu
curl -LO https://github.com/operator-framework/operator-sdk/releases/download/${RELEASE_VERSION}/ansible-operator-${RELEASE_VERSION}-x86_64-linux-gnu
curl -LO https://github.com/operator-framework/operator-sdk/releases/download/${RELEASE_VERSION}/helm-operator-${RELEASE_VERSION}-x86_64-linux-gnu
chmod +x operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu && sudo cp operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu /usr/local/bin/operator-sdk && rm operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu
chmod +x ansible-operator-${RELEASE_VERSION}-x86_64-linux-gnu && sudo cp ansible-operator-${RELEASE_VERSION}-x86_64-linux-gnu /usr/local/bin/ansible-operator && rm ansible-operator-${RELEASE_VERSION}-x86_64-linux-gnu
chmod +x helm-operator-${RELEASE_VERSION}-x86_64-linux-gnu && sudo cp helm-operator-${RELEASE_VERSION}-x86_64-linux-gnu /usr/local/bin/helm-operator && rm helm-operator-${RELEASE_VERSION}-x86_64-linux-gnu

# Install Prerequisites:Helm needed by operator-sdk for Helm-based Operators 
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm 

# Install Prerequisites needed by operator-sdk for Ansible-based Operators
sudo apt install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get -y install ansible
sudo apt-get -y install python-dev
pip install ansible-runner
pip install ansible-runner-http

# OLM install: release (0.11.0)
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.11.0/crds.yaml
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.11.0/olm.yaml
# OLM_VERSION=0.15.1; curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${OLM_VERSION}/install.sh | bash -s ${OLM_VERSION}


# Install Marketplace Operator
MARKETPLACE_VERSION=4.5

OPERATOR_MARKETPLACE_VERSION="release-${MARKETPLACE_VERSION}"
kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/${OPERATOR_MARKETPLACE_VERSION}/deploy/upstream/01_namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/${OPERATOR_MARKETPLACE_VERSION}/deploy/upstream/03_operatorsource.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/${OPERATOR_MARKETPLACE_VERSION}/deploy/upstream/04_service_account.yaml
kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/${OPERATOR_MARKETPLACE_VERSION}/deploy/upstream/05_role.yaml
kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/${OPERATOR_MARKETPLACE_VERSION}/deploy/upstream/06_role_binding.yaml
sleep 1
kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/${OPERATOR_MARKETPLACE_VERSION}/deploy/upstream/07_upstream_operatorsource.cr.yaml
curl -sL https://raw.githubusercontent.com/operator-framework/operator-marketplace/${OPERATOR_MARKETPLACE_VERSION}/deploy/upstream/08_operator.yaml | \
sed -e "s;quay.io/openshift/origin-operator-marketplace:latest;quay.io/openshift/origin-operator-marketplace:${MARKETPLACE_VERSION};" | \
kubectl apply -f -

# Install Operator Courier for OLM Bundle push @Quay.io
sudo apt-get -y install python3-pip
pip3 install setuptools
pip3 install wheel
pip3 install operator-courier
