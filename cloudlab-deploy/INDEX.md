# CloudLab Vote App Deployment - Complete Guide

Welcome! This directory contains everything you need to deploy a voting application on CloudLab's Kubernetes cluster using Garden.

## 📚 Documentation Index

### Start Here
1. **[README.md](README.md)** - Overview and quick start guide
2. **[SETUP.md](SETUP.md)** - Detailed step-by-step deployment instructions

### Reference
3. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Command cheatsheet and quick lookup
4. **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture and diagrams
5. **[SUMMARY.md](SUMMARY.md)** - What we created and why

### Help
6. **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions

## 🚀 Quick Start (TL;DR)

```bash
# 1. Create CloudLab experiment with osp.py profile
# 2. SSH to controller
ssh username@controller.your-exp.cloudlab.us

# 3. Create Kubernetes cluster
source /opt/devstack/openrc admin admin
openstack coe cluster create k8s-cluster \
  --cluster-template k8s-default-template \
  --master-count 1 --node-count 2 --keypair magnum-default

# 4. Get kubeconfig
openstack coe cluster config k8s-cluster --dir ~/.kube --force
export KUBECONFIG=~/.kube/config

# 5. Update garden.yml with correct context
kubectl config get-contexts
nano /local/repository/cloudlab-deploy/garden.yml

# 6. Deploy
cd /local/repository/cloudlab-deploy
garden deploy --env cloudlab

# 7. Access
kubectl get nodes -o wide  # Get node IP
# Visit http://<node-ip>:30080 (vote) and :30081 (result)
```

## 📁 File Structure

### Configuration Files
- **garden.yml** - Main Garden project configuration
- **.gitignore** - Git ignore patterns

### Application Modules (Build)
- **vote-image.garden.yml** - Vote UI container build
- **api-image.garden.yml** - API container build
- **result-image.garden.yml** - Result UI container build
- **worker-image.garden.yml** - Worker container build

### Application Modules (Deploy)
- **vote.garden.yml** - Vote frontend deployment (NodePort 30080)
- **api.garden.yml** - API backend deployment (ClusterIP)
- **result.garden.yml** - Result UI deployment (NodePort 30081)
- **worker.garden.yml** - Worker deployment
- **redis.garden.yml** - Redis cache (Bitnami Helm)
- **postgres.garden.yml** - PostgreSQL + init (Bitnami Helm)

## 🎯 What This Does

Deploys a complete voting application:
- **Frontend**: Users vote for cats or dogs
- **Backend**: API processes votes
- **Cache**: Redis stores temporary data
- **Worker**: Processes votes asynchronously
- **Database**: PostgreSQL stores final results
- **Results UI**: Displays voting results in real-time

## ⚙️ Key Features

✅ **Simple** - Minimal configuration, single environment  
✅ **Complete** - Full application stack included  
✅ **CloudLab-optimized** - No ingress, uses NodePorts  
✅ **Garden-powered** - Easy deployment and management  
✅ **Self-contained** - References existing vote-helm code  

## 📊 Application Ports

- **30080** - Vote UI (external access)
- **30081** - Result UI (external access)
- **80** - API service (internal only)
- **6379** - Redis (internal only)
- **5432** - PostgreSQL (internal only)

## 🔧 Prerequisites

1. CloudLab account
2. Active experiment with `osp.py` profile
3. OpenStack installed on controller (~30-60 min)
4. Kubernetes cluster created via Magnum (~10-20 min)
5. Garden CLI installed
6. kubectl access configured

## 📖 Recommended Reading Order

**For First-Time Users:**
1. Start with [README.md](README.md)
2. Follow [SETUP.md](SETUP.md) step-by-step
3. Keep [QUICK_REFERENCE.md](QUICK_REFERENCE.md) handy
4. Refer to [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if needed

**For Understanding the System:**
1. Read [ARCHITECTURE.md](ARCHITECTURE.md)
2. Review [SUMMARY.md](SUMMARY.md)

**For Quick Deployment:**
1. Use commands from [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
2. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if issues arise

## 🎓 Learning Objectives

By deploying this application, you'll learn:
- How to use OpenStack Magnum for Kubernetes
- Container orchestration with Kubernetes
- Application deployment with Garden
- Multi-tier application architecture
- Service discovery and networking
- Helm charts and package management

## 🛠️ Technologies Used

- **CloudLab** - Physical infrastructure
- **OpenStack** - Cloud platform (DevStack)
- **Magnum** - Kubernetes cluster management
- **Kubernetes** - Container orchestration
- **Garden** - Development and deployment workflow
- **Helm** - Kubernetes package manager
- **Docker** - Container runtime
- **Python/Flask** - Vote and API services
- **Node.js** - Result and Worker services
- **Redis** - In-memory cache
- **PostgreSQL** - Relational database

## 📞 Getting Help

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) first
2. Review Garden logs: `garden logs --log-level debug`
3. Check Kubernetes events: `kubectl get events`
4. Inspect pod logs: `kubectl logs <pod-name>`

## 🧹 Cleanup

```bash
# Remove application
garden delete environment

# Delete Kubernetes cluster
openstack coe cluster delete k8s-cluster

# Terminate CloudLab experiment (via web UI)
```

## ⚠️ Important Notes

- This is a **lab/demo configuration** - not production-ready
- No persistent storage - data lost on pod restart
- No TLS/HTTPS - plain HTTP only
- Default passwords - change for real use
- NodePort access - no ingress controller

## 🚦 Status Indicators

**Ready to deploy when:**
- ✅ CloudLab experiment status: Ready
- ✅ OpenStack dashboard accessible
- ✅ Kubernetes cluster: CREATE_COMPLETE
- ✅ kubectl get nodes shows all nodes Ready
- ✅ Garden CLI installed
- ✅ garden.yml context updated

## 📝 Next Steps After Deployment

1. Test the application by voting
2. View results in real-time
3. Check pod logs to see data flow
4. Scale deployments: `kubectl scale deployment vote --replicas=3`
5. Experiment with Garden's hot-reload features
6. Try breaking things and fixing them!

## 🎉 Success Looks Like

```bash
$ kubectl get pods
NAME                      READY   STATUS    RESTARTS   AGE
api-xxx                   1/1     Running   0          5m
postgres-0                1/1     Running   0          6m
redis-master-0            1/1     Running   0          6m
result-xxx                1/1     Running   0          4m
vote-xxx                  1/1     Running   0          3m
worker-deploy-xxx         1/1     Running   0          4m

$ kubectl get svc
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
vote           NodePort    10.254.x.x      <none>        80:30080/TCP
result         NodePort    10.254.x.x      <none>        80:30081/TCP
api            ClusterIP   10.254.x.x      <none>        80/TCP
redis-master   ClusterIP   10.254.x.x      <none>        6379/TCP
postgres       ClusterIP   10.254.x.x      <none>        5432/TCP
```

Browse to `http://<node-ip>:30080` and start voting! 🗳️

---

**Happy Deploying!** 🚀

For questions or issues, refer to the documentation files listed above.
