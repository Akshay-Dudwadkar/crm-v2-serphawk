#!/usr/bin/env bash
set -euo pipefail

: "${EC2_HOST:?Set EC2_HOST to the Elastic IP or DNS name}"
: "${EC2_USER:=ubuntu}"
: "${SSH_KEY_PATH:?Set SSH_KEY_PATH to the EC2 private key path}"
: "${ECR_BACKEND_IMAGE:?Set ECR_BACKEND_IMAGE}"
: "${ECR_FRONTEND_IMAGE:?Set ECR_FRONTEND_IMAGE}"
: "${AWS_REGION:?Set AWS_REGION}"
: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID}"

remote_dir="/opt/crm"

ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new "$EC2_USER@$EC2_HOST" \
  "sudo mkdir -p '$remote_dir/static/uploads' && sudo chown -R '$EC2_USER':'$EC2_USER' '$remote_dir'"

scp -i "$SSH_KEY_PATH" docker-compose.prod.yml "$EC2_USER@$EC2_HOST:$remote_dir/docker-compose.prod.yml"
scp -i "$SSH_KEY_PATH" nginx/crm.conf "$EC2_USER@$EC2_HOST:$remote_dir/crm.conf"

ssh -i "$SSH_KEY_PATH" "$EC2_USER@$EC2_HOST" bash -s -- "$ECR_BACKEND_IMAGE" "$ECR_FRONTEND_IMAGE" "$AWS_REGION" "$AWS_ACCOUNT_ID" <<'REMOTE'
set -euo pipefail
backend_image="$1"
frontend_image="$2"
aws_region="$3"
aws_account_id="$4"
cd /opt/crm
export ECR_BACKEND_IMAGE="$backend_image"
export ECR_FRONTEND_IMAGE="$frontend_image"
aws ecr get-login-password --region "$aws_region" | docker login --username AWS --password-stdin "$aws_account_id.dkr.ecr.$aws_region.amazonaws.com"
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml exec -T backend python create_tables.py
sudo install -m 0644 crm.conf /etc/nginx/sites-available/crm.conf
sudo ln -sfn /etc/nginx/sites-available/crm.conf /etc/nginx/sites-enabled/crm.conf
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
REMOTE