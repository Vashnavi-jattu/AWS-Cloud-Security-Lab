terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

locals {
  insecure_mode = var.lab_mode == "insecure"

  common_tags = {
    Project = "aws-cloud-security-lab"
    Mode    = var.lab_mode
  }

  ssh_cidr_blocks = local.insecure_mode ? ["0.0.0.0/0"] : [var.my_ip_cidr]

  s3_block_public_acls       = local.insecure_mode ? false : true
  s3_block_public_policy     = local.insecure_mode ? false : true
  s3_ignore_public_acls      = local.insecure_mode ? false : true
  s3_restrict_public_buckets = local.insecure_mode ? false : true

  ec2_policy_document = local.insecure_mode ? {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "OverlyPermissiveS3Access"
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "*"
      }
    ]
    } : {
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [
          aws_s3_bucket.lab_bucket.arn
        ]
      },
      {
        Sid    = "ReadWriteObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.lab_bucket.arn}/*"
        ]
      }
    ]
  }
}

resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "lab-vpc"
  })
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = merge(local.common_tags, {
    Name = "lab-public-subnet"
  })
}

resource "aws_internet_gateway" "lab_igw" {
  vpc_id = aws_vpc.lab_vpc.id

  tags = merge(local.common_tags, {
    Name = "lab-igw"
  })
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_igw.id
  }

  tags = merge(local.common_tags, {
    Name = "lab-public-rt"
  })
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "ec2_sg" {
  name        = "lab-ec2-sg"
  description = "Security group for AWS Cloud Security Lab EC2"
  vpc_id      = aws_vpc.lab_vpc.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = local.insecure_mode ? "Insecure SSH open to everyone" : "SSH only from trusted IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.ssh_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "lab-ec2-sg"
  })
}

resource "aws_s3_bucket" "lab_bucket" {
  bucket = var.bucket_name

  tags = merge(local.common_tags, {
    Name = "lab-s3-bucket"
  })
}

resource "aws_s3_bucket_public_access_block" "lab_bucket_block" {
  bucket = aws_s3_bucket.lab_bucket.id

  block_public_acls       = local.s3_block_public_acls
  block_public_policy     = local.s3_block_public_policy
  ignore_public_acls      = local.s3_ignore_public_acls
  restrict_public_buckets = local.s3_restrict_public_buckets
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lab_bucket_encryption" {
  bucket = aws_s3_bucket.lab_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "public_bucket_policy" {
  count  = local.insecure_mode ? 1 : 0
  bucket = aws_s3_bucket.lab_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadAccess"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.lab_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "lab-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "ec2_s3_policy" {
  name   = "lab-ec2-s3-policy"
  policy = jsonencode(local.ec2_policy_document)

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "attach_ec2_s3_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "lab-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "lab_ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd aws-cli
              systemctl enable httpd
              systemctl start httpd
              echo "<h1>AWS Cloud Security Lab</h1><p>Mode: ${var.lab_mode}</p>" > /var/www/html/index.html
              echo "This is a sample file for the AWS Cloud Security Lab." > /tmp/sample.txt
              aws s3 cp /tmp/sample.txt s3://${var.bucket_name}/sample.txt
              EOF

  tags = merge(local.common_tags, {
    Name = "lab-ec2"
  })
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "${var.bucket_name}-cloudtrail-logs"

  tags = merge(local.common_tags, {
    Name = "lab-cloudtrail-logs"
  })
}

resource "aws_s3_bucket_policy" "cloudtrail_logs_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "lab_trail" {
  name                          = "lab-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_logging                = true

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs_policy]

  tags = local.common_tags
}
