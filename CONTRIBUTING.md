# Contributing to AWS Enterprise Deployment

Thank you for your interest in contributing! This guide will help you get started.

## How to Contribute

1. **Fork** the repository
2. **Create a branch** for your feature or fix (`git checkout -b feature/my-feature`)
3. **Make your changes** and ensure they follow the project conventions
4. **Test** your changes thoroughly
5. **Commit** with a clear, descriptive message
6. **Push** to your fork and open a **Pull Request**

## Development Setup

```bash
# Clone your fork
git clone https://github.com/<your-username>/aws-enterprise-deployment.git
cd aws-enterprise-deployment

# Initialize Terraform
cd terraform/environments/prod
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive
```

## Code Standards

- **Formatting**: Use `terraform fmt` to format all `.tf` files
- **Validation**: Run `terraform validate` before submitting changes
- **Naming**: Follow HashiCorp naming conventions for resources and variables
- **Modules**: Keep modules focused and reusable

```bash
# Format all Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Run a plan to check for errors
terraform plan -var-file=prod.tfvars
```

## Pull Request Guidelines

- Keep PRs focused on a single change
- Update documentation if needed
- Include example `terraform plan` output when relevant
- Ensure `terraform fmt` and `terraform validate` pass
- Describe what your PR does and why

## Reporting Issues

- Use GitHub Issues to report bugs or request features
- Include steps to reproduce any bugs
- For security vulnerabilities, see [SECURITY.md](SECURITY.md)

## Code of Conduct

Be respectful, inclusive, and constructive in all interactions.
