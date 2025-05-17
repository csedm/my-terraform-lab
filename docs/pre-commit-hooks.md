# Pre-commit Hooks: git-secrets & Terraform

This project uses a shared pre-commit hook to help prevent committing secrets and to enforce Terraform formatting.

## 1. git-secrets

To prevent committing secrets, install [git-secrets](https://github.com/awslabs/git-secrets):

```sh
brew install git-secrets  # macOS
# or follow instructions in the git-secrets repo for other OS
```

Then, register git-secrets hooks in your repo:

```sh
git secrets --install
```

This will automatically scan for secrets on each commit.

## 2. Terraform Formatting

To ensure all Terraform files are properly formatted, the pre-commit hook will run `terraform fmt` on all staged `.tf` files before each commit. Any files that need formatting will be automatically formatted and re-staged before the commit proceeds—no manual intervention is needed.

## 3. Enabling the Shared Pre-commit Hook

To enable the shared pre-commit hook, run:

```sh
ln -sf ../scripts/pre-commit .git/hooks/pre-commit
chmod +x ../scripts/pre-commit
```

This will ensure the pre-commit hook is used locally and can be updated from version control.
