# Troubleshooting Guide

## Common Issues and Solutions

### 1. Cannot SSH to CloudLab Controller

**Problem**: SSH connection refused or times out

**Solutions**:
- Wait for node to finish booting (check CloudLab experiment page)
- Verify SSH key is uploaded to CloudLab profile
- Use the full hostname from CloudLab's "List View"
- Try from CloudLab's web shell (gear icon on experiment page)

---

### 2. OpenStack Installation Failed

**Problem**: Can't access dashboard or `openstack` commands fail

**Check logs**:
```bash
tail -f /tmp/install-openstack.log
tail -f /opt/stack/logs/stack.sh.log
```

**Common causes**:
- Insufficient resources (try different hardware type)
- Network issues during package download
- Timing issues (try re-running the script)

**Solution**:
```bash
# Try re-running installation
sudo /local/repository/scripts/01-install-openstack.sh chocolateFrog!
```

---

### 3. Magnum Configuration Failed

**Problem**: No cluster template available

**Check logs**:
```bash
tail -f /tmp/configure-magnum.log
```

**Solution**:
```bash
source /opt/devstack/openrc admin admin
sudo /local/repository/scripts/02-configure-magnum.sh
```

---

### 4. Kubernetes Cluster Creation Fails

**Problem**: Cluster stuck in CREATE_FAILED state

**Check error details**:
```bash
source /opt/devstack/openrc admin admin
openstack coe cluster show k8s-cluster
openstack stack list
openstack stack resource list <stack-id>
openstack stack resource show <stack-name> <failed-resource>
```

**Common causes**:
- Insufficient compute resources
- Networking issues
- Heat stack timeout

**Solutions**:
```bash
# Delete failed cluster
openstack coe cluster delete k8s-cluster

# Try with fewer nodes
openstack coe cluster create k8s-cluster \
  --cluster-template k8s-default-template \
  --master-count 1 --node-count 1 \
  --keypair magnum-default

# Or increase compute nodes in CloudLab experiment
```

---

### 5. Cannot Get Kubeconfig

**Problem**: `openstack coe cluster config` fails

**Solution**:
```bash
# Ensure cluster is in CREATE_COMPLETE state
openstack coe cluster show k8s-cluster

# Retry getting config
mkdir -p ~/.kube
openstack coe cluster config k8s-cluster --dir ~/.kube --force

# Set environment variable
export KUBECONFIG=~/.kube/config

# Test connection
kubectl get nodes
```

---

### 6. Garden Deploy Fails - Wrong Context

**Problem**: `Unable to connect to cluster` error

**Solution**:
```bash
# Check available contexts
kubectl config get-contexts

# Update garden.yml with correct context name
nano cloudlab-deploy/garden.yml

# Test kubectl access
kubectl get nodes

# Retry deployment
garden deploy --env cloudlab
```

---

### 7. Container Build Failures

**Problem**: Garden fails during image build

**Check**:
```bash
# Verify source paths exist
ls ../garden/examples/vote-helm/vote-image
ls ../garden/examples/vote-helm/api-image

# Check Garden logs
garden logs --log-level debug
```

**Solution**:
```bash
# Ensure you're in the right directory
cd /local/repository/cloudlab-deploy

# Check if Docker is running
docker ps

# Try building individual images
garden build vote-image
```

---

### 8. Pods Stuck in Pending State

**Problem**: Pods not scheduling

**Check**:
```bash
kubectl get pods
kubectl describe pod <pod-name>
```

**Common causes**:
- Insufficient resources on nodes
- Image pull errors
- PVC not bound

**Solutions**:
```bash
# Check node resources
kubectl describe nodes

# Check events
kubectl get events --sort-by='.lastTimestamp'

# For image pull errors, check buildMode in garden.yml
```

---

### 9. Pods in CrashLoopBackOff

**Problem**: Pods repeatedly crashing

**Check logs**:
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
```

**Common causes**:
- Application errors
- Missing dependencies
- Configuration issues

**Solutions**:
```bash
# Check environment variables
kubectl describe pod <pod-name>

# Check if dependencies are running
kubectl get pods

# Redeploy specific module
garden deploy vote
```

---

### 10. Cannot Access Application via NodePort

**Problem**: Browser can't reach http://node-ip:30080

**Check**:
```bash
# Verify service exists
kubectl get svc

# Check if pods are running
kubectl get pods

# Get correct node IP
kubectl get nodes -o wide
```

**Solutions**:
```bash
# Test from controller node first
curl http://localhost:30080

# If that works, issue is with external access
# Check Kubernetes node IP (InternalIP vs ExternalIP)
kubectl get nodes -o yaml | grep -A 5 addresses

# Try using the internal network IP
```

---

### 11. Database Connection Errors

**Problem**: Worker or Result service can't connect to Postgres

**Check**:
```bash
kubectl get pods
kubectl logs <worker-pod-name>
```

**Solution**:
```bash
# Verify postgres pod is running
kubectl get pods | grep postgres

# Check if db-init ran successfully
garden get status

# Manually run db-init
garden run db-init

# Verify table exists
kubectl exec -it postgres-0 -- psql -U postgres -d postgres -c '\dt'
```

---

### 12. Redis Connection Errors

**Problem**: API or Worker can't connect to Redis

**Check**:
```bash
kubectl get svc redis-master
kubectl logs <api-pod-name>
```

**Solution**:
```bash
# Verify redis pod is running
kubectl get pods | grep redis

# Test redis connectivity
kubectl exec -it <api-pod> -- nc -zv redis-master 6379

# Redeploy redis if needed
garden deploy redis
```

---

## Debug Commands Cheatsheet

```bash
# Check all resources
kubectl get all -n default

# Watch pod status
watch kubectl get pods

# Get detailed pod info
kubectl describe pod <pod-name>

# View pod logs (follow mode)
kubectl logs -f <pod-name>

# View previous container logs (after crash)
kubectl logs <pod-name> --previous

# Execute shell in pod
kubectl exec -it <pod-name> -- /bin/bash

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check resource usage
kubectl top nodes
kubectl top pods

# Garden debug commands
garden get status
garden logs --tail 100
garden deploy --log-level debug
```

## Getting Help

If you're still stuck:

1. Check Garden logs: `garden logs --log-level debug`
2. Check Kubernetes events: `kubectl get events`
3. Check pod logs: `kubectl logs <pod-name>`
4. Verify all prerequisites are met (SETUP.md)
5. Try deleting and redeploying: `garden delete environment && garden deploy`

## Reset Everything

If all else fails, start fresh:

```bash
# Delete Garden deployment
garden delete environment

# Delete Kubernetes cluster
openstack coe cluster delete k8s-cluster

# Wait for deletion to complete
openstack coe cluster list

# Recreate cluster
openstack coe cluster create k8s-cluster \
  --cluster-template k8s-default-template \
  --master-count 1 --node-count 2 \
  --keypair magnum-default

# Get new kubeconfig
openstack coe cluster config k8s-cluster --dir ~/.kube --force

# Redeploy
garden deploy --env cloudlab
```
