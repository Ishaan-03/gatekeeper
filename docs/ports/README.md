# The pipeline in GitLab CI and Jenkins

The real pipeline is [`.github/workflows/gatekeeper.yml`](../../.github/workflows/gatekeeper.yml), and it runs on every change. The two files here are translations of the same gates into GitLab CI and Jenkins. **They have not been run.** They show how each concept maps between the three tools.

| Concept | GitHub Actions | GitLab CI | Jenkins |
|---|---|---|---|
| Pipeline file | `.github/workflows/*.yml` | `.gitlab-ci.yml` | `Jenkinsfile` |
| Ordering | `needs:` | `stages:` plus `needs:` | stage order, `parallel { }` |
| Where it runs | `runs-on:` | `image:` plus runner tags | `agent { docker { ... } }` |
| Secrets and settings | `secrets.X` / `vars.X` | CI/CD variables (masked, protected) | `credentials()` / `withCredentials` |
| OIDC to the cloud | `permissions: id-token: write` | `id_tokens:` | no built-in token; a plugin, or run the agent with a cloud identity |
| Pass files between jobs | `upload-artifact` / `download-artifact` | `artifacts:` plus `needs:` | `stash` / `unstash` |
| Run only on main | `if: github.ref == 'refs/heads/main'` | `rules: - if: $CI_COMMIT_BRANCH == "main"` | `when { branch 'main' }` |
| Reuse | actions (`uses:`) | `include:` / CI components | shared libraries |

## What changes in AWS for each

The pipeline role trusts GitHub's token issuer and this repository's `sub`. Moving to another CI system means a new trust, not a new key:

| CI system | OIDC issuer | Example `sub` to trust |
|---|---|---|
| GitHub Actions | `token.actions.githubusercontent.com` | `repo:Ishaan-03@166810647/gatekeeper@1414191999:ref:refs/heads/main` |
| GitLab CI | `gitlab.com` | `project_path:ishaan-03/gatekeeper:ref_type:branch:ref:main` |
| Jenkins on EKS | the cluster's OIDC issuer | `system:serviceaccount:ci:jenkins-agent` |
