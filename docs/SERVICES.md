# AWS Services

## EC2

One Ubuntu 24.04 `t3.micro` hosts Docker, Nginx, the Next.js container, and the FastAPI container. This keeps the assignment within the requested single-server design and avoids a load balancer.

## RDS PostgreSQL

RDS PostgreSQL 16 provides managed backups and patching while remaining private. It is single-AZ with `db.t3.micro`, 20 GB gp3, and one day of backups as requested.

## ECR

Two private ECR repositories store backend and frontend images. The EC2 instance receives `AmazonEC2ContainerRegistryReadOnly` through its instance role, so no AWS keys are stored on the server.

## Elastic IP

The attached Elastic IP gives the browser a stable address for Nginx. It must remain attached while allocated to avoid charges outside applicable free-tier allowances.

## Nginx

Nginx is the single public entry point. It sends `/` to Next.js and `/api/` to FastAPI after removing the `/api` prefix. It also forwards WebSocket upgrade headers.

## Rejected alternatives

- **EKS**: unnecessary Kubernetes control-plane and worker complexity, and not compatible with the free-tier-only constraint.
- **ALB/NLB**: adds a billable managed load balancer when one EC2 instance is required.
- **NAT Gateway**: adds a significant hourly and data-processing charge; the EC2 instance is public and RDS only needs private inbound access.
- **Multi-AZ RDS**: increases database cost and is explicitly forbidden for this assignment.
- **Secrets Manager**: useful for larger production systems but explicitly forbidden here; sensitive application values stay in the server-only `.env` file.
- **ElastiCache**: not needed by the current application and not free-tier compatible.