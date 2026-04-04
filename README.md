# AWS Cloud Security Lab: Misconfiguration Detection and Remediation

This project builds a small AWS environment with Terraform, intentionally introduces common cloud security misconfigurations, and then remediates them using least-privilege and secure configuration practices.

It is designed as a beginner-friendly portfolio project that demonstrates:

- AWS infrastructure setup
- cloud security assessment
- risk analysis
- remediation
- monitoring and validation

## Architecture

The lab includes:

- `1 VPC`
- `1 public subnet`
- `1 EC2 instance`
- `1 security group`
- `1 S3 bucket`
- `1 IAM role attached to EC2`
- `1 CloudTrail trail`

High-level flow:

`Internet -> Security Group -> EC2 in Public Subnet -> IAM Role -> S3 Bucket`

`CloudTrail -> logs AWS management activity`

A diagram and component table are in [docs/architecture.md](docs/architecture.md).

## Project Structure

```text
.
|-- .gitignore
|-- README.md
|-- docs/
|   |-- architecture.md
|   |-- risk-table.md
|   `-- validation.md
`-- terraform/
    |-- .terraform.lock.hcl
    |-- main.tf
    |-- outputs.tf
    |-- terraform.tfvars.example
    `-- variables.tf
```

## What The Terraform Code Does

The Terraform code supports three modes through the `lab_mode` variable:

- `baseline`: secure starting environment
- `insecure`: intentionally vulnerable configuration for demonstration
- `remediated`: secure post-fix configuration

This makes the project easier to explain because you can show:

1. the normal setup
2. the vulnerable state
3. the corrected secure state

## Services Created

The code provisions:

- custom VPC with DNS support
- public subnet
- internet gateway and route table
- EC2 instance with a small Apache web server
- S3 bucket for sample data
- IAM role and instance profile for EC2
- CloudTrail with a dedicated log bucket

## Intentional Misconfigurations

When `lab_mode = "insecure"`, the Terraform code introduces these issues:

### 1. Public S3 bucket

- S3 Block Public Access is disabled
- a public-read bucket policy is added

Risk:
Anyone on the internet may read bucket objects.

### 2. SSH open to the world

- EC2 port `22` is opened to `0.0.0.0/0`

Risk:
The management interface is exposed to the internet and vulnerable to brute-force attempts.

### 3. Overly broad IAM permissions

- the EC2 IAM role is given `s3:*` on `*`

Risk:
If EC2 is compromised, the attacker can abuse more S3 access than required.

## Remediation Strategy

When `lab_mode = "remediated"`, the project applies secure controls:

- SSH restricted to your trusted IP
- S3 Block Public Access enabled
- public bucket policy removed
- least-privilege IAM policy scoped to the lab bucket
- S3 encryption enabled
- CloudTrail remains enabled for visibility

## How To Run The Project

## Prerequisites

You need:

- an AWS account
- Terraform installed
- AWS credentials configured locally
- an EC2 key pair in your target region if you want SSH access

## Setup

1. Go to the `terraform/` directory.
2. Copy `terraform.tfvars.example` to `terraform.tfvars`.
3. Replace the sample values with your own bucket name, key pair name, and public IP CIDR.

Example:

```hcl
aws_region        = "ap-south-1"
availability_zone = "ap-south-1a"
instance_type     = "t2.micro"
bucket_name       = "aws-cloud-security-lab-yourname-2026"
my_ip_cidr        = "203.0.113.10/32"
key_name          = "your-ec2-keypair-name"
lab_mode          = "baseline"
```

## Terraform Commands

Initialize:

```bash
terraform init
```

Validate:

```bash
terraform validate
```

Preview changes:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

Destroy resources when finished:

```bash
terraform destroy
```

## Recommended Demo Workflow

Use this order for a strong portfolio story:

1. Deploy with `lab_mode = "baseline"`
2. Capture screenshots of the secure starting state
3. Change to `lab_mode = "insecure"`
4. Run `terraform apply`
5. Observe the misconfigurations and capture screenshots
6. Document the risk and impact of each issue
7. Change to `lab_mode = "remediated"`
8. Run `terraform apply`
9. Validate that the fixes worked
10. Destroy the environment after testing

## Before / After Summary

| Area | Insecure Mode | Remediated Mode |
|---|---|---|
| SSH access | `0.0.0.0/0` | `my_ip_cidr` only |
| S3 public access | Allowed | Blocked |
| IAM policy | `s3:*` on `*` | Bucket-scoped least privilege |
| CloudTrail | Enabled | Enabled |

## Validation

Use the checks in `docs/validation.md` to verify the remediations.

Key validation points:

- public S3 object access should fail after remediation
- SSH should no longer be open to everyone
- EC2 IAM permissions should be scoped only to the lab bucket
- CloudTrail should show configuration changes

## Risk Analysis

The risk table is available in `docs/risk-table.md`.

## Lessons Learned

- Misconfigurations in AWS can quickly expose systems and data.
- Least privilege reduces blast radius if a resource is compromised.
- CloudTrail improves visibility and helps validate configuration changes.
- Secure cloud design is not only about deployment, but also about review and remediation.

## Cost Note

Keep the lab small and destroy resources when finished to avoid unnecessary AWS charges. Pay special attention to:

- EC2 runtime
- S3 storage
- CloudTrail log storage

## Portfolio Value

This project is useful because it demonstrates both cloud and security skills:

- infrastructure provisioning
- practical misconfiguration analysis
- remediation with least privilege
- validation and monitoring

It is stronger than a normal deployment project because it shows why cloud settings matter from a security perspective.