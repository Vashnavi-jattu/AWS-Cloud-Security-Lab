output "lab_mode" {
  description = "Current lab deployment mode"
  value       = var.lab_mode
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.lab_vpc.id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public_subnet.id
}

output "security_group_id" {
  description = "Security group ID for EC2"
  value       = aws_security_group.ec2_sg.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.lab_ec2.public_ip
}

output "web_url" {
  description = "HTTP URL for the test web server"
  value       = "http://${aws_instance.lab_ec2.public_ip}"
}

output "s3_bucket_name" {
  description = "Main lab S3 bucket"
  value       = aws_s3_bucket.lab_bucket.bucket
}

output "cloudtrail_name" {
  description = "CloudTrail trail name"
  value       = aws_cloudtrail.lab_trail.name
}
