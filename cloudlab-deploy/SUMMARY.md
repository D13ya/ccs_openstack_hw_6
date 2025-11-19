# CloudLab Vote App Deployment - Summary

## What We Created

A simplified Garden deployment configuration for running the vote-helm example on CloudLab's Kubernetes cluster.

## Directory Structure

```
cloudlab-deploy/
├── .gitignore                # Git ignore file
├── README.md                 # Overview and quick reference
├── SETUP.md                  # Detailed step-by-step guide
├── garden.yml                # Main Garden project config
├── api.garden.yml            # API service deployment
├── api-image.garden.yml      # API container build
├── postgres.garden.yml       # PostgreSQL database + init
├── redis.garden.yml          # Redis cache
├── result.garden.yml         # Result UI deployment
├── result-image.garden.yml   # Result container build
├── vote.garden.yml           # Vote UI deployment
├── vote-image.garden.yml     # Vote container build
├── worker.garden.yml         # Worker deployment
└── worker-image.garden.yml   # Worker container build
```

## Key Features

### ✅ Simplified for CloudLab
- Single environment configuration (no multi-env complexity)
- NodePort services (no ingress controller needed)
- Local Docker builds (no external registry required)
- References existing vote-helm source code

### ✅ Complete Application Stack
- Frontend: Vote UI (port 30080)
- Backend: API service
- Database: PostgreSQL with auto-initialization
- Cache: Redis
- Worker: Background processor
- Results: Result UI (port 30081)

### ✅ Minimal Configuration
- Only requires updating the Kubernetes context name
- No complex networking setup
- No external dependencies

## Deployment Flow

1. **CloudLab Setup** (30-60 min)
   - Instantiate experiment with osp.py
   - OpenStack installs automatically
   - Magnum configures automatically

2. **Kubernetes Cluster** (10-20 min)
   - Create cluster via Magnum
   - Get kubeconfig
   - Verify access

3. **Application Deployment** (5-10 min)
   - Update garden.yml context
   - Run `garden deploy`
   - Access via NodePorts

## Usage Instructions

See [SETUP.md](SETUP.md) for complete step-by-step instructions.

**Quick commands:**
```bash
# On CloudLab controller
source /opt/devstack/openrc admin admin
openstack coe cluster create k8s-cluster --cluster-template k8s-default-template --master-count 1 --node-count 2 --keypair magnum-default
openstack coe cluster config k8s-cluster --dir ~/.kube --force

# Deploy application
cd cloudlab-deploy
garden deploy --env cloudlab

# Access
kubectl get nodes -o wide  # Get node IP
# Visit http://<node-ip>:30080 and :30081
```

## Next Steps

1. Follow SETUP.md to deploy
2. Customize NodePort numbers if needed (edit vote.garden.yml and result.garden.yml)
3. Add more replicas for scalability testing
4. Experiment with Garden's hot reload features

## Notes

- All container source code is in `../garden/examples/vote-helm/`
- Helm charts are referenced from the same location
- This is production-like architecture but simplified for learning/testing
- No persistent volumes - data lost on pod restart
