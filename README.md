# AWS Cloud Security Lab

**Misconfiguration detection and remediation on AWS** — a small, reproducible lab built with Terraform. Deploy a baseline environment, flip into intentional misconfigurations, then remediate using least privilege and document the full lifecycle.

[![Terraform](https://img.shields.io/badge/IaC-Terraform-844FBA?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-232F3E?logo=amazon-web-services&logoColor=white)](https://aws.amazon.com/)

---

## Table of contents

- [Overview](#overview)
- [What you will demonstrate](#what-you-will-demonstrate)
- [Tech stack](#tech-stack)
- [Architecture](#architecture)
- [Repository layout](#repository-layout)
- [Lab modes](#lab-modes)
- [Misconfigurations and remediation](#misconfigurations-and-remediation)
- [Getting started](#getting-started)
- [Recommended demo workflow](#recommended-demo-workflow)
- [Validation and evidence](#validation-and-evidence)
- [Documentation](#documentation)
- [Cost and cleanup](#cost-and-cleanup)
- [Lessons learned](#lessons-learned)

---

## Overview

This project is a **hands-on cloud security exercise**, not just a static deployment. You provision a minimal AWS footprint (VPC, public subnet, EC2, S3, IAM, security groups, CloudTrail), then use a single variable (`lab_mode`) to switch between:

1. A **secure baseline**  
2. A **deliberately insecure** configuration  
3. A **remediated** configuration aligned with least privilege  

That workflow mirrors how security work happens in practice: build, assess risk, fix, and validate.

---

## What you will demonstrate

| Skill area | How this project shows it |
|------------|---------------------------|
| Cloud infrastructure | VPC networking, EC2, S3, IAM, security groups |
| Infrastructure as code | Terraform modules in one place, repeatable environments |
| Threat understanding | Why public data, open SSH, and excessive IAM matter |
| Remediation | Block Public Access, narrow SG rules, scoped IAM policies |
| Monitoring | CloudTrail for audit visibility before and after changes |

---

## Tech stack

| Tool / service | Role |
|----------------|------|
| **Terraform** | Defines and applies all infrastructure |
| **Amazon VPC** | Isolated network for the lab |
| **Amazon EC2** | Linux instance with a simple HTTP demo app |
| **Amazon S3** | Lab data bucket + separate bucket for CloudTrail logs |
| **AWS IAM** | Instance role for EC2 → S3 access (safe vs overly broad) |
| **AWS CloudTrail** | Management event logging |

---

## Architecture

**Resources provisioned**

- 1 VPC, 1 public subnet, internet gateway, route table  
- 1 EC2 instance (Apache serves a small page; user data uploads `sample.txt` to S3)  
- 1 security group (HTTP from the internet; SSH varies by mode)  
- 1 S3 bucket for lab objects  
- 1 IAM role + instance profile attached to EC2  
- 1 CloudTrail trail writing to a dedicated S3 log bucket  

**Traffic and access (conceptual)**

`Internet → Security Group → EC2 (public subnet) → IAM role → S3 lab bucket`  

`CloudTrail → S3 log bucket` (audit trail for configuration changes)

A **Mermaid diagram** and component table live in [docs/architecture.md](docs/architecture.md).

---

## Repository layout

```text
.
├── README.md
├── .gitignore
├── docs/
│   ├── architecture.md    # Diagram + component reference
│   ├── risk-table.md      # Misconfiguration / risk / impact / fix
│   └── validation.md      # How to prove remediations worked
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars.example
    └── .terraform.lock.hcl
```

Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` (that file is gitignored so secrets and personal values stay local).

---

## Lab modes

Set `lab_mode` in `terraform.tfvars`:

| Mode | Purpose |
|------|---------|
| `baseline` | Secure starting point for demos or first deploy |
| `insecure` | Intentional misconfigurations for assessment and screenshots |
| `remediated` | Same as baseline posture: least privilege and locked-down S3 |

After changing `lab_mode`, run `terraform apply` to converge the environment.

---

## Misconfigurations and remediation

When `lab_mode = "insecure"`:

| Issue | What changes | Risk |
|-------|----------------|------|
| Public S3 | Block Public Access off + public read bucket policy | Unauthorized object read from the internet |
| Open SSH | Port 22 from `0.0.0.0/0` | Brute-force and unauthorized access attempts |
| Broad IAM | `s3:*` on `*` for the EC2 role | Large blast radius if the instance is compromised |

When `lab_mode = "baseline"` or `remediated`:

- SSH limited to `my_ip_cidr`  
- S3 Block Public Access on; no public bucket policy  
- IAM limited to required actions on the lab bucket only  
- Default S3 encryption enabled  
- CloudTrail remains on  

Detailed narrative: [docs/risk-table.md](docs/risk-table.md).

**Before / after (summary)**

| Area | Insecure | Baseline / remediated |
|------|----------|------------------------|
| SSH | `0.0.0.0/0` | Your IP only (`my_ip_cidr`) |
| S3 public access | Allowed | Blocked |
| IAM (S3) | `s3:*` on `*` | List + get/put on lab bucket only |
| CloudTrail | On | On |

---

## Getting started

### Prerequisites

- AWS account and credentials configured (for example `aws configure`)  
- [Terraform](https://developer.hashicorp.com/terraform/install) installed  
- EC2 key pair in your chosen region if you want SSH (optional)  
- A **globally unique** S3 bucket name  

### Configure

```powershell
cd terraform
Copy-Item terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` — example:

```hcl
aws_region        = "ap-south-1"
availability_zone = "ap-south-1a"
instance_type     = "t2.micro"
bucket_name       = "aws-cloud-security-lab-yourname-2026"
my_ip_cidr        = "203.0.113.10/32"
key_name          = "your-ec2-keypair-name"
lab_mode          = "baseline"
```

Use your real public IP as `x.x.x.x/32` for SSH in secure modes.

### Deploy

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

### Verify it is working

```bash
terraform output web_url
```

Open the printed URL in a browser — you should see the lab page. In S3, confirm `sample.txt` exists in your lab bucket.

### Tear down

```bash
terraform destroy
```

---

## Recommended demo workflow

Use this sequence for portfolios, interviews, or coursework writeups:

1. Deploy with `lab_mode = "baseline"` and capture “secure” screenshots.  
2. Switch to `lab_mode = "insecure"`, `terraform apply`, capture misconfigurations (console: S3, SG, IAM).  
3. Write up **misconfiguration → risk → impact → detection → fix** for each issue.  
4. Switch to `lab_mode = "remediated"`, `terraform apply`, re-check settings.  
5. Use CloudTrail event history to show configuration changes over time.  
6. Run `terraform destroy` when finished.  

---

## Validation and evidence

Follow [docs/validation.md](docs/validation.md) for step-by-step checks (public URL no longer works, SSH scope, IAM policy text, CloudTrail events).

**Optional portfolio assets** (add under `docs/screenshots/` or your report):

- EC2 security group rules (before / after)  
- S3 Block Public Access and bucket policy (before / after)  
- IAM policy JSON or console summary (before / after)  
- Browser hitting `web_url` and CloudTrail filtered events  

---

## Documentation

| Document | Contents |
|----------|----------|
| [docs/architecture.md](docs/architecture.md) | Diagram, components, mode behavior |
| [docs/risk-table.md](docs/risk-table.md) | Risk table for writeups |
| [docs/validation.md](docs/validation.md) | Post-remediation verification |

---

## Cost and cleanup

This lab is sized for learning, but **EC2 runtime, S3 storage, and CloudTrail log storage** can incur charges. Use small instance types where possible, delete the stack with `terraform destroy` when you are done, and empty or lifecycle-manage the trail bucket if you keep the account active.

---

## Lessons learned

- Small misconfigurations (public buckets, `0.0.0.0/0` on SSH, wildcard IAM) create outsized risk.  
- **Least privilege** limits damage if one resource is compromised.  
- **CloudTrail** supports both detection narratives and proof that you changed settings deliberately.  
- Treating security as **deploy → assess → remediate → validate** is closer to real work than “terraform apply once and forget.”

---

## License

This repository is provided for **educational and portfolio** use. Review AWS terms and your organization’s policies before deploying in production or shared accounts.
