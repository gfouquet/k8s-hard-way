#!/usr/bin/env bash
NODE_NAME="$1"

kubectl config set-cluster kubernetes-the-hard-way \
              --certificate-authority=ca.pem \
              --embed-certs=true \
              --server=https://{{ kube_public_ip }}:6443 \
              "--kubeconfig=${NODE_NAME}.kubeconfig"

kubectl config "set-credentials system:node:${NODE_NAME}" \
              "--client-certificate=${NODE_NAME}.pem" \
              "--client-key=${NODE_NAME}-key.pem" \
              --embed-certs=true \
              "--kubeconfig=${NODE_NAME}.kubeconfig"

kubectl config set-context default \
              --cluster=kubernetes-the-hard-way \
              "--user=system:node:${NODE_NAME}" \
              "--kubeconfig=${NODE_NAME}.kubeconfig"
              
kubectl config use-context default "--kubeconfig=${NODE_NAME}.kubeconfig"
