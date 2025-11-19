# Deployment Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         CloudLab                                │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 Controller Node                          │   │
│  │  ┌────────────────────────────────────────────────┐     │   │
│  │  │          OpenStack (DevStack)                   │     │   │
│  │  │  - Keystone, Nova, Neutron, Glance, etc.       │     │   │
│  │  │  - Magnum (Container Orchestration Engine)     │     │   │
│  │  │  - Heat (Orchestration)                        │     │   │
│  │  └────────────────────────────────────────────────┘     │   │
│  │                                                          │   │
│  │  ┌────────────────────────────────────────────────┐     │   │
│  │  │        Kubernetes Cluster (Magnum)             │     │   │
│  │  │                                                │     │   │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐    │     │   │
│  │  │  │ Master   │  │ Worker 1 │  │ Worker 2 │    │     │   │
│  │  │  │   Node   │  │   Node   │  │   Node   │    │     │   │
│  │  │  └──────────┘  └──────────┘  └──────────┘    │     │   │
│  │  │                                                │     │   │
│  │  │     ┌─────────────────────────────┐           │     │   │
│  │  │     │  Vote Application Pods       │           │     │   │
│  │  │     │  - Vote UI (NodePort 30080) │           │     │   │
│  │  │     │  - API Service              │           │     │   │
│  │  │     │  - Result UI (NodePort 30081)│          │     │   │
│  │  │     │  - Worker                   │           │     │   │
│  │  │     │  - Redis (Bitnami)          │           │     │   │
│  │  │     │  - PostgreSQL (Bitnami)     │           │     │   │
│  │  │     └─────────────────────────────┘           │     │   │
│  │  └────────────────────────────────────────────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐                     │
│  │  Compute Node 1 │  │  Compute Node 2 │                     │
│  │  (Nova Compute) │  │  (Nova Compute) │                     │
│  └─────────────────┘  └─────────────────┘                     │
└─────────────────────────────────────────────────────────────────┘
```

## Application Architecture

```
                    Internet
                       │
                       │
              ┌────────▼────────┐
              │   CloudLab      │
              │   Firewall      │
              └────────┬────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
   ┌────▼────┐                   ┌────▼────┐
   │  Vote   │                   │ Result  │
   │   UI    │                   │   UI    │
   │ :30080  │                   │ :30081  │
   └────┬────┘                   └────┬────┘
        │                             │
        │         ┌───────────────────┘
        │         │
   ┌────▼─────────▼────┐
   │    API Service    │
   │   (ClusterIP)     │
   └────┬──────────────┘
        │
        │
   ┌────▼────┐     ┌──────────┐
   │  Redis  │     │  Worker  │
   │  Cache  │◀────┤ Service  │
   └─────────┘     └────┬─────┘
                        │
                   ┌────▼─────┐
                   │PostgreSQL│
                   │ Database │
                   └──────────┘
```

## Data Flow

```
1. User votes via Vote UI (port 30080)
        │
        ▼
2. Vote sent to API Service
        │
        ▼
3. API stores vote in Redis queue
        │
        ▼
4. Worker picks up vote from Redis
        │
        ▼
5. Worker stores vote in PostgreSQL
        │
        ▼
6. Result UI reads from PostgreSQL (port 30081)
```

## Network Topology

```
CloudLab Physical Network
        │
        ├─── Controller: 192.168.X.X
        │         │
        │         └─── OpenStack Network
        │                   │
        │                   └─── Kubernetes Cluster
        │                             │
        │                             ├─── Pod Network (Calico)
        │                             │         │
        │                             │         ├─── vote-xxx
        │                             │         ├─── api-xxx
        │                             │         ├─── result-xxx
        │                             │         ├─── worker-xxx
        │                             │         ├─── redis-xxx
        │                             │         └─── postgres-0
        │                             │
        │                             └─── Service Network
        │                                       ├─── ClusterIP Services
        │                                       └─── NodePort Services
        │                                             ├─── :30080 → vote
        │                                             └─── :30081 → result
        │
        ├─── Compute-1: 192.168.X.Y
        └─── Compute-2: 192.168.X.Z
```

## Garden Deployment Flow

```
1. garden deploy
        │
        ├─── Build Phase
        │     │
        │     ├─── Build: vote-image
        │     ├─── Build: api-image
        │     ├─── Build: result-image
        │     └─── Build: worker-image
        │
        ├─── Deploy Phase (dependencies resolved)
        │     │
        │     ├─── Deploy: redis (Helm)
        │     ├─── Deploy: db (Helm)
        │     │     └─── Run: db-init
        │     │
        │     ├─── Deploy: api (depends on redis)
        │     ├─── Deploy: worker-deploy (depends on redis, db)
        │     │
        │     ├─── Deploy: vote (depends on api)
        │     └─── Deploy: result (depends on db-init)
        │
        └─── Success!
              Services accessible via NodePorts
```

## Component Dependencies

```
vote
 └─── api
       └─── redis

result
 └─── db-init
       └─── db

worker-deploy
 ├─── redis
 └─── db

db-init
 └─── db
```

## Resource Requirements

```
Per Node (Recommended):
- CPU: 4+ cores
- RAM: 8+ GB
- Disk: 50+ GB

Kubernetes Cluster:
- Master: 1 node (2 CPU, 4 GB RAM)
- Worker: 2+ nodes (2 CPU, 4 GB RAM each)

Application Pods:
- vote: ~100 MB RAM
- api: ~100 MB RAM
- result: ~100 MB RAM
- worker: ~100 MB RAM
- redis: ~100 MB RAM
- postgres: ~256 MB RAM
```

## Ports and Services

```
External Access (NodePort):
- 30080: Vote UI (HTTP)
- 30081: Result UI (HTTP)

Internal Services (ClusterIP):
- api: 80
- redis-master: 6379
- postgres: 5432

OpenStack Dashboard:
- http://<controller-ip>/dashboard
```

## Security Considerations

```
⚠️  This is a DEMO/LAB configuration!
⚠️  NOT for production use!

Issues in this setup:
- No TLS/HTTPS
- Default passwords
- No authentication on Redis
- No network policies
- NodePort exposes services directly
- No persistent storage (data loss on pod restart)

For production, add:
- Ingress controller with TLS
- Secrets management
- Network policies
- Persistent volumes
- Resource limits
- Pod security policies
- Image scanning
- RBAC configuration
```
