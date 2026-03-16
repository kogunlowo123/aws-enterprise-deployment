# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, please email: **kogunlowo@gmail.com**

Include the following in your report:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You will receive an acknowledgment within 48 hours and a detailed response within 7 days.

## Security Best Practices

This project follows these security practices:

- Terraform state files are never committed to the repository
- Secrets and credentials are managed via environment variables or AWS Secrets Manager
- Infrastructure follows least-privilege IAM/RBAC policies with permission boundaries
- Network configurations enforce Zero Trust with 3-tier subnet architecture
- Encryption at rest (KMS) and in transit (TLS) is enabled for all resources
- WAFv2 with OWASP managed rules protects public-facing endpoints
- GuardDuty and Security Hub provide continuous threat detection
- No hardcoded credentials in Terraform configurations

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |

## Disclosure Policy

We follow a coordinated disclosure process. Please allow us reasonable time to address any reported vulnerabilities before public disclosure.
