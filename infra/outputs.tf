output "elastic_ip" {
  value       = aws_eip.app.public_ip
  description = "Elastic IP for the Nginx entry point"
}

output "rds_endpoint" {
  value       = aws_db_instance.postgres.address
  description = "Private RDS PostgreSQL endpoint"
}

output "ecr_backend_url" {
  value       = aws_ecr_repository.backend.repository_url
  description = "Backend ECR repository URL"
}

output "ecr_frontend_url" {
  value       = aws_ecr_repository.frontend.repository_url
  description = "Frontend ECR repository URL"
}