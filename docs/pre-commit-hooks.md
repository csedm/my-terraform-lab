# Pre-commit Hooks: detect-secrets & Terraform

This project uses a shared pre-commit hook to help prevent committing secrets and to enforce Terraform formatting.

Register the pre-commit hook to ensure these actions occur before each commit:

```sh
ln -sf ../scripts/pre-commit .git/hooks/pre-commit
chmod +x ../scripts/pre-commit
```

## 0. Setup

The pre-commit hook will automatically create a Python virtual environment (if one does not exist) and install `detect-secrets` before scanning for secrets. If the virtual environment already exists, it will be activated before running the scan. No manual installation or activation is required.

## 1. detect-secrets

The pre-commit hook will automatically scan for secrets on each commit using the baseline.

## 2. Terraform Formatting

To ensure all Terraform files are properly formatted, the pre-commit hook will run `terraform fmt` on all staged `.tf` files before each commit. Any files that need formatting will be automatically formatted and re-staged before the commit proceeds—no manual intervention is needed.
