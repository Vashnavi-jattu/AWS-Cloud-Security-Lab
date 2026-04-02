variable "aws_region" {
  description = "AWS region for the lab"
  type        = string
  default     = "ap-south-1"
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
  default     = "ap-south-1a"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "bucket_name" {
  description = "Unique S3 bucket name"
  type        = string
}

variable "my_ip_cidr" {
  description = "Trusted public IP in CIDR format for SSH when lab_mode is baseline or remediated"
  type        = string
}

variable "key_name" {
  description = "Optional EC2 key pair name for SSH"
  type        = string
  default     = ""
}

variable "lab_mode" {
  description = "Deployment mode for the lab: baseline, insecure, or remediated"
  type        = string
  default     = "baseline"

  validation {
    condition     = contains(["baseline", "insecure", "remediated"], var.lab_mode)
    error_message = "lab_mode must be one of: baseline, insecure, remediated."
  }
}
