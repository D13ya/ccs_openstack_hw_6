# Simplified CloudLab Deployment

A minimal configuration for deploying the vote application to your CloudLab Kubernetes cluster.

## What's Included

This deployment includes:
- **vote**: Frontend UI (Python/Flask) - NodePort 30080
- **api**: REST API backend (Python/Flask) - ClusterIP
- **result**: Results display UI (Node.js) - NodePort 30081
- **worker**: Background job processor (Node.js)
- **redis**: In-memory cache (Bitnami Helm chart)
- **postgres**: Database for storing votes (Bitnami Helm chart)

## Key Simplifications

1. **No ingress**: Using NodePort services for direct access
2. **Local Docker builds**: Images built locally and pushed to cluster
3. **Single environment**: Just CloudLab, no multi-environment complexity
4. **Minimal configuration**: Only essential settings
5. **Reuses existing code**: References vote-helm example from parent directory

## Files Structure

```
cloudlab-deploy/
├── garden.yml              # Main project config
├── vote.garden.yml         # Vote frontend deployment
├── vote-image.garden.yml   # Vote image build
├── api.garden.yml          # API backend deployment
├── api-image.garden.yml    # API image build
├── result.garden.yml       # Results UI deployment
├── result-image.garden.yml # Result image build
├── worker.garden.yml       # Background worker deployment
├── worker-image.garden.yml # Worker image build
├── redis.garden.yml        # Redis cache (Bitnami Helm)
├── postgres.garden.yml     # PostgreSQL (Bitnami Helm)
├── README.md               # This file
└── SETUP.md               # Detailed deployment guide
```

## Quick Start

See **[SETUP.md](SETUP.md)** for detailed step-by-step instructions.

**TL;DR:**
1. Create CloudLab experiment using `osp.py`
2. Wait for OpenStack installation (~30-60 min)
3. Create Kubernetes cluster via Magnum (~10-20 min)
4. Get kubeconfig: `openstack coe cluster config k8s-cluster`
5. Update `garden.yml` with correct context name
6. Run `garden deploy --env cloudlab`
7. Access via `http://<node-ip>:30080` (vote) and `:30081` (result)

## Prerequisites

- CloudLab experiment with OpenStack + Magnum
- Kubernetes cluster created via Magnum
- kubectl configured
- Garden CLI installed (`curl -sL https://get.garden.io/install.sh | bash`)

## Accessing the Application

Get your node IP:
```bash
kubectl get nodes -o wide
```

Access services:
- **Vote UI**: `http://<node-ip>:30080`
- **Result UI**: `http://<node-ip>:30081`

## Troubleshooting

Check deployment status:
```bash
garden get status
kubectl get pods
kubectl get svc
```

View logs:
```bash
kubectl logs <pod-name>
garden logs
```

## Cleanup

```bash
garden delete environment
```

On OpenStack controller:
```bash
openstack coe cluster delete k8s-cluster
```
