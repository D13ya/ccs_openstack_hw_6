# CloudLab Deployment Quick Setup

## Step 1: Create CloudLab Experiment

1. Go to CloudLab and instantiate the experiment using `osp.py` profile
2. Wait for nodes to provision and OpenStack to install (~30-60 minutes)
3. Access the controller node via SSH

## Step 2: Create Kubernetes Cluster on OpenStack

SSH to controller node:
```bash
ssh your-user@controller.yourexp.cloudlab.us

# Source OpenStack credentials
source /opt/devstack/openrc admin admin

# Create Kubernetes cluster using Magnum
openstack coe cluster create k8s-cluster \
  --cluster-template k8s-default-template \
  --master-count 1 \
  --node-count 2 \
  --keypair magnum-default

# Monitor cluster creation (takes 10-20 minutes)
watch openstack coe cluster show k8s-cluster
# Wait until status shows CREATE_COMPLETE

# Get kubeconfig
mkdir -p ~/.kube
openstack coe cluster config k8s-cluster --dir ~/.kube --force
export KUBECONFIG=~/.kube/config

# Verify cluster access
kubectl get nodes
```

## Step 3: Setup Local Environment

### Option A: Deploy from Controller Node (Simpler)

On the controller node:
```bash
# Install Garden CLI
curl -sL https://get.garden.io/install.sh | bash

# Clone your deployment files
cd /local/repository
cd cloudlab-deploy

# Deploy
garden deploy --env cloudlab
```

### Option B: Deploy from Local Machine

Copy kubeconfig to your local machine:
```bash
# On your local machine
scp your-user@controller.yourexp.cloudlab.us:~/.kube/config ~/.kube/cloudlab-config

# Update garden.yml with correct context
kubectl config get-contexts

# Deploy
garden deploy --env cloudlab
```

## Step 4: Access the Application

Get the node IP:
```bash
kubectl get nodes -o wide
```

Access the services:
- Vote UI: `http://<node-ip>:30080`
- Result UI: `http://<node-ip>:30081`

## Troubleshooting

Check pod status:
```bash
kubectl get pods
kubectl logs <pod-name>
kubectl describe pod <pod-name>
```

Check services:
```bash
kubectl get svc
```

## Cleanup

```bash
garden delete environment
```

On OpenStack:
```bash
openstack coe cluster delete k8s-cluster
```
