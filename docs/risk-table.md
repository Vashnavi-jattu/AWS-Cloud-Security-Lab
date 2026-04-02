# Risk Table

| Misconfiguration | Risk | Impact | Detection | Fix |
|---|---|---|---|---|
| Public S3 bucket | Data exposure | Anyone on the internet may read objects in the bucket | Reviewed S3 Block Public Access settings and bucket policy | Enabled Block Public Access and removed public read policy |
| SSH open to `0.0.0.0/0` | Exposed management interface | Brute-force attempts and unauthorized access attempts become possible | Reviewed security group inbound rules | Restricted SSH to a trusted IP range |
| IAM policy with `s3:*` on `*` | Excessive privilege | A compromised EC2 instance could access unrelated S3 resources | Reviewed IAM role policy actions and resources | Replaced wildcard permissions with bucket-specific least-privilege actions |
