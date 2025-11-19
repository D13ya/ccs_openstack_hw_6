# Quick Reference Card

## Essential Commands

### CloudLab Setup
```bash
# SSH to controller
ssh username@controller.yourexp.cloudlab.us

# Source OpenStack creds (do this in every new shell)
source /opt/devstack/openrc admin admin

# Create K8s cluster
openstack coe cluster create k8s-cluster \
  --cluster-template k8s-default-template \
  --master-count 1 --node-count 2 \
  --keypair magnum-default

# Check cluster status
openstack coe cluster show k8s-cluster

# Get kubeconfig
mkdir -p ~/.kube
openstack coe cluster config k8s-cluster --dir ~/.kube --force
export KUBECONFIG=~/.kube/config
```

### Garden Deployment
```bash
# Install Garden (if not installed)
curl -sL https://get.garden.io/install.sh | bash

# Navigate to deployment directory
cd /local/repository/cloudlab-deploy

# Update garden.yml context name
kubectl config get-contexts
nano garden.yml  # Edit the 'context' field

# Deploy everything
garden deploy --env cloudlab

# Check status
garden get status

# View logs
garden logs vote
```

### Kubernetes Commands
```bash
# Get all resources
kubectl get all

# Get nodes with IPs
kubectl get nodes -o wide

# Get pod status
kubectl get pods

# Get services
kubectl get svc

# View pod logs
kubectl logs <pod-name>

# Describe pod (for troubleshooting)
kubectl describe pod <pod-name>

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/sh
```

### Access Application
```bash
# Get node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')

# Vote UI
echo "Vote: http://$NODE_IP:30080"

# Result UI
echo "Result: http://$NODE_IP:30081"
```

### Cleanup
```bash
# Delete Garden deployment
garden delete environment

# Delete K8s cluster
openstack coe cluster delete k8s-cluster
```

## File You Need to Edit

**Only one file needs editing:**
```yaml
# cloudlab-deploy/garden.yml
context: kubernetes-admin@kubernetes  # Change this to your actual context name
```

Get your context name:
```bash
kubectl config get-contexts
```

## Troubleshooting

### Pods not starting?
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Can't access via NodePort?
```bash
# Check if service exists
kubectl get svc

# Check node IP
kubectl get nodes -o wide

# Check firewall (usually OK on CloudLab)
```

### Garden build fails?
```bash
# Check if context is correct
kubectl config current-context

# Check if kubectl works
kubectl get nodes

# Try with more verbose output
garden deploy --env cloudlab --log-level debug
```

## Architecture

```
┌─────────┐     ┌─────┐     ┌────────┐
│  Vote   │────▶│ API │────▶│ Redis  │
│   UI    │     └─────┘     └────────┘
│ :30080  │                      │
└─────────┘                      ▼
                            ┌────────┐     ┌──────────┐
                            │ Worker │────▶│ Postgres │
                            └────────┘     └──────────┘
┌─────────┐                                     │
│ Result  │◀────────────────────────────────────┘
│   UI    │
│ :30081  │
└─────────┘
```

## Default Credentials

**OpenStack Dashboard**: http://<controller-ip>/dashboard
- Username: `admin` or `demo`
- Password: `chocolateFrog!` (or your custom password)

**PostgreSQL** (internal):
- Username: `postgres`
- Password: `postgres`

**Redis** (internal):
- No authentication

## Useful Links

- [Garden Docs](https://docs.garden.io/)
- [CloudLab Docs](https://docs.cloudlab.us/)
- [OpenStack Docs](https://docs.openstack.org/)
- [Magnum Docs](https://docs.openstack.org/magnum/latest/)
