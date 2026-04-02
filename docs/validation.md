# Validation Guide

Use the checks below to prove that the remediation worked.

## 1. S3 is not public anymore

- In the AWS Console, open the lab bucket and verify that `Block all public access` is enabled.
- Try to access the uploaded object through a public URL. It should fail after remediation.

Example public URL format:

```text
https://<bucket-name>.s3.amazonaws.com/sample.txt
```

## 2. SSH is no longer open to the world

- Open the EC2 security group.
- Confirm that port `22` is restricted to your trusted IP CIDR instead of `0.0.0.0/0`.

## 3. IAM follows least privilege

- Open the EC2 IAM role.
- Confirm that the policy only allows:
  - `s3:ListBucket` on the lab bucket
  - `s3:GetObject` and `s3:PutObject` on objects in that bucket

## 4. CloudTrail is logging changes

- Open CloudTrail event history.
- Filter for S3, EC2, IAM, or CloudTrail actions.
- Capture evidence of configuration changes during the insecure and remediated stages.

## 5. Web server is still reachable

- Open the EC2 public IP in your browser over HTTP.
- Confirm the sample web page loads after remediation.
