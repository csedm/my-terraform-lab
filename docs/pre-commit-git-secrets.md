# Pre-commit Hook: git-secrets

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
