# CloudLab OpenStack + Kubernetes Deployment

A CloudLab profile for deploying OpenStack with Kubernetes (via Magnum) and a sample voting application using Garden.

## Repository Structure

```
ccs_openstack_hw_6/
├── osp.py                      # CloudLab profile (geni-lib script)
├── scripts/                    # Setup scripts
│   ├── 01-install-openstack.sh
│   └── 02-configure-magnum.sh
├── cloudlab-deploy/            # Garden deployment for voting app
│   ├── garden.yml
│   ├── *.garden.yml (modules)
│   └── *.md (documentation)
└── garden/
    └── examples/
        └── vote-helm/          # Voting app source code
```

## Quick Start

### 1. Instantiate CloudLab Profile

1. Go to [CloudLab](https://www.cloudlab.us/)
2. Create a new experiment
3. Select "Create Profile" or use existing
4. Use this repository URL: `https://github.com/D13ya/ccs_openstack_hw_6`
5. Select the profile script: `osp.py`
6. Configure parameters (hardware type, compute nodes, passwords)
7. Start the experiment

### 2. Wait for Setup to Complete

- OpenStack installation: ~30-60 minutes
- Magnum configuration: ~5-10 minutes
- Monitor progress in CloudLab's experiment view

### 3. Create Kubernetes Cluster

SSH to the controller node and run:

```bash
source /opt/devstack/openrc admin admin

openstack coe cluster create k8s-cluster \
  --cluster-template k8s-default-template \
  --master-count 1 \
  --node-count 2 \
  --keypair magnum-default

# Wait for completion (~10-20 minutes)
watch openstack coe cluster show k8s-cluster
```

### 4. Deploy Voting Application

```bash
# Get kubeconfig
openstack coe cluster config k8s-cluster --dir ~/.kube --force
export KUBECONFIG=~/.kube/config

# Install Garden CLI
curl -sL https://get.garden.io/install.sh | bash

# Update context in garden.yml
kubectl config get-contexts
nano /local/repository/cloudlab-deploy/garden.yml

# Deploy
cd /local/repository/cloudlab-deploy
garden deploy --env cloudlab

# Access application
kubectl get nodes -o wide  # Get node IP
# Vote UI: http://<node-ip>:30080
# Result UI: http://<node-ip>:30081
```

## Detailed Documentation

See `cloudlab-deploy/` directory for comprehensive documentation:

- **INDEX.md** - Complete navigation guide
- **SETUP.md** - Step-by-step deployment instructions
- **QUICK_REFERENCE.md** - Command cheatsheet
- **ARCHITECTURE.md** - System architecture diagrams
- **TROUBLESHOOTING.md** - Common issues and solutions

## Components

### CloudLab Profile (`osp.py`)
- Multi-node setup (1 controller + N compute nodes)
- Ubuntu 24.04 LTS
- Automated OpenStack installation via DevStack
- Magnum for Kubernetes cluster management

### Voting Application
- **Vote UI** - Python/Flask frontend (NodePort 30080)
- **API** - Python/Flask backend
- **Result UI** - Node.js results display (NodePort 30081)
- **Worker** - Node.js background processor
- **Redis** - In-memory cache
- **PostgreSQL** - Vote storage database

## Requirements

- CloudLab account
- SSH access to experiment nodes
- Basic knowledge of:
  - OpenStack
  - Kubernetes
  - Docker
  - Garden (optional, covered in docs)

## Default Credentials

**OpenStack Dashboard**: `http://<controller-ip>/dashboard`
- Username: `admin` or `demo`
- Password: `chocolateFrog!` (or custom value set during instantiation)

**PostgreSQL** (internal):
- Username: `postgres`
- Password: `postgres`

## Features

✅ Automated OpenStack deployment  
✅ Magnum pre-configured for Kubernetes  
✅ Complete voting application stack  
✅ Garden-based deployment workflow  
✅ Comprehensive documentation  
✅ Simple NodePort access (no ingress needed)  

## Notes

- This is a **lab/demo configuration** - not production-ready
- No persistent volumes (data lost on pod restart)
- No TLS/HTTPS
- Default passwords should be changed for real use

## Troubleshooting

If you encounter issues:

1. Check CloudLab experiment logs
2. Review `/tmp/install-openstack.log` on controller
3. Review `/tmp/configure-magnum.log` on controller
4. See `cloudlab-deploy/TROUBLESHOOTING.md` for detailed help

## License

This project is for educational purposes.

## Credits

Based on the Garden vote-helm example and adapted for CloudLab deployment.
