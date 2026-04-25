---
name: infrastructure-best-practices
created: 2026-04-25T00:00:00Z
category: Infrastructure
severity: warn
enabled: True
references:
  - https://www.terraform.io/docs/cloud-docs/recommended-practices/index.html
  - https://www.cncf.io/wp-content/uploads/2020/08/CNCF-Best-Practices-for-Kubernetes-Workloads.pdf
  - https://www.oreilly.com/library/view/infrastructure-as-code/9781098121620/
  - https://kubernetes.io/docs/concepts/configuration/overview/
  - https://12factor.net/
---

# Law: infrastructure-best-practices

**Severity:** warn  
**Created:** 2026-04-25T00:00:00Z  
**Category:** Infrastructure

## Purpose

Enforces Infrastructure as Code best practices for Terraform, Kubernetes, and cloud resources.

## Reference Materials

### Primary Sources

1. **Terraform Recommended Practices**  
   https://www.terraform.io/docs/cloud-docs/recommended-practices/index.html  
   HashiCorp's official guidance on workspace organization, module design, and team workflows.

2. **CNCF - Best Practices for Kubernetes Workloads**  
   https://www.cncf.io/wp-content/uploads/2020/08/CNCF-Best-Practices-for-Kubernetes-Workloads.pdf  
   Cloud Native Computing Foundation's comprehensive guide to production-ready K8s deployments.

3. **Kief Morris - Infrastructure as Code (O'Reilly)**  
   https://www.oreilly.com/library/view/infrastructure-as-code/9781098121620/  
   The definitive book on IaC principles, patterns, and anti-patterns.

4. **Kubernetes Documentation - Configuration**  
   https://kubernetes.io/docs/concepts/configuration/overview/  
   Official K8s best practices for configuration, secrets, and resource management.

5. **12-Factor App Methodology**  
   https://12factor.net/  
   Heroku's methodology for cloud-native applications: config, processes, concurrency, disposability.

## Patterns Checked

### 1. Terraform: Remote State Required
From [Terraform Recommended Practices - State](https://www.terraform.io/docs/cloud-docs/recommended-practices/index.html):
> "Use remote state with locking. Local state is for development only."

```hcl
# Bad: Local state
terraform {
  # No backend configured
}

# Good: Remote state with locking
terraform {
  backend "s3" {
    bucket         = "my-tf-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### 2. Terraform: No Hardcoded Values
From [Kief Morris - Infrastructure as Code](https://www.oreilly.com/library/view/infrastructure-as-code/9781098121620/):
> "Externalize all environment-specific values. Use validation to enforce constraints."

```hcl
# Bad: Hardcoded config
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.large"
}

# Good: Variables with validation
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Instance type must be t3.micro, t3.small, or t3.medium"
  }
}
```

### 3. Terraform: Resource Tags Required
From [AWS Tagging Best Practices](https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html):
> "Consistent tagging enables cost allocation, security audits, and resource discovery."

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Owner       = var.team
  }
}

resource "aws_instance" "web" {
  tags = local.common_tags
}
```

### 4. Kubernetes: No Privileged Containers
From [CNCF Best Practices](https://www.cncf.io/wp-content/uploads/2020/08/CNCF-Best-Practices-for-Kubernetes-Workloads.pdf):
> "Containers should not run as root or with privileged mode. Drop all capabilities."

```yaml
# Bad: Privileged mode
securityContext:
  privileged: true
  runAsRoot: true

# Good: Security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

### 5. Kubernetes: Resource Limits Required
From [K8s Configuration Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/):
> "Always define resource requests and limits to prevent noisy neighbor problems."

```yaml
# Bad: No resource constraints
containers:
  - name: app
    image: myapp:latest

# Good: Defined resources
containers:
  - name: app
    image: myapp:latest
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
```

### 6. Kubernetes: Health Checks Required
From [CNCF Best Practices](https://www.cncf.io/wp-content/uploads/2020/08/CNCF-Best-Practices-for-Kubernetes-Workloads.pdf):
> "Liveness and readiness probes prevent traffic to unhealthy pods and enable self-healing."

```yaml
containers:
  - name: app
    livenessProbe:
      httpGet:
        path: /health/live
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /health/ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

### 7. Kubernetes: No Latest Tag
From [K8s Images](https://kubernetes.io/docs/concepts/containers/images/):
> "The :latest tag is non-deterministic. Use immutable tags or digest references."

```yaml
# Bad: Non-reproducible
image: myapp:latest

# Good: Immutable tag
image: myapp:v1.2.3@sha256:abc123...
```

### 8. No Public S3 Buckets
From [AWS S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html):
> "Block all public access by default. Use explicit IAM policies for access control."

```hcl
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### 9. Secrets Management
From [HashiCorp Vault Patterns](https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-intro):
> "No plaintext secrets in code or state. Use secret managers with dynamic credentials."

```hcl
# Bad: Secrets in plain text
resource "aws_db_instance" "db" {
  password = "mysecretpassword"
}

# Good: Use secrets manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}

resource "aws_db_instance" "db" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

### 10. Network Security Groups
From [AWS Security Group Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/security-groups.html):
> "Principle of least privilege. Restrict to specific CIDRs, not 0.0.0.0/0."

```hcl
# Bad: Open to world
resource "aws_security_group" "allow_all" {
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Good: Restricted access
resource "aws_security_group" "web" {
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}
```

## Remediation

Infrastructure violations can have security and cost implications. Review against Terraform/Kubernetes best practices before applying.

---

*Guidance synthesized from HashiCorp, CNCF, and AWS best practices.*
