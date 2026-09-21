#!/usr/bin/env bash
set -euo pipefail

: "${AWS_REGION:?Set AWS_REGION}"
: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID}"

registry="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
tag="$(git rev-parse --short HEAD)"

aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$registry"

docker build --platform linux/amd64 -t "$registry/crm-backend:$tag" .
docker build --platform linux/amd64 --build-arg NEXT_PUBLIC_API_URL=/api -t "$registry/crm-frontend:$tag" ./frontend

docker push "$registry/crm-backend:$tag"
docker push "$registry/crm-frontend:$tag"

echo "ECR_BACKEND_IMAGE=$registry/crm-backend:$tag"
echo "ECR_FRONTEND_IMAGE=$registry/crm-frontend:$tag"