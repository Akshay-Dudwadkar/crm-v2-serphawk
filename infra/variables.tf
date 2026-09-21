variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "crm-v2-serphawk"
}

variable "my_ip_cidr" {
  type        = string
  description = "Your public IPv4 address in CIDR form, for example 203.0.113.10/32."
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name in ap-south-1."
}

variable "db_name" {
  type    = string
  default = "crm"
}

variable "db_username" {
  type    = string
  default = "crmadmin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}