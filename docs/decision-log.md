# Decision log

Each entry: what I decided, what else I could have done, why, and what it costs.

## Gate only on HIGH and CRITICAL findings that have a fix

* **Decision:** Trivy fails the build only for HIGH or CRITICAL vulnerabilities with a fixed version available (`--ignore-unfixed`).
* **Alternative:** Fail on every HIGH and CRITICAL finding, or on every finding.
* **Why:** A gate should block what a developer can act on. On the hardened image, all 46 remaining HIGH findings had no fix published, so a stricter gate would have been permanently red and people would learn to ignore it. When Debian later published fixes for `openssl` and `pcre2`, this same gate caught them.
* **Cost:** Unfixed HIGH findings ship. They are listed in every scan log and in the SBOM, so they can be checked again when a fix lands.

## Checkov skips with a written reason

* **Decision:** Fix CKV2_AWS_61 (lifecycle rule); skip CKV_AWS_145, CKV_AWS_136, CKV_AWS_144, CKV_AWS_18 and CKV2_AWS_62 with `#checkov:skip` and a reason next to the resource.
* **Alternative:** Fix everything, or turn the checks off globally.
* **Why:** The fix was free and solved a problem I created (versioning keeps every old state file). The skips each needed extra paid resources (KMS keys, a replica bucket, a log bucket) for a single user lab. A skip in the code is reviewed like code; a global switch would hide future findings too.
* **Cost:** About 1 EUR a month per KMS key avoided. A regulated environment would likely require logging and replication.

## `ecr:GetAuthorizationToken` on `*`

* **Decision:** The pipeline role's login statement uses `Resource: "*"`.
* **Alternative:** None that works. AWS does not support resource-level permissions for this action.
* **Why:** The token it returns is only a registry login. What can be pushed is limited by the second statement: five upload actions on one repository ARN.
* **Cost:** A reviewer will see a wildcard. It is documented here and in the threat model.

## GitHub Actions instead of Jenkins

* **Decision:** Build the pipeline in GitHub Actions, and keep translated GitLab CI and Jenkins versions in `docs/ports/`.
* **Alternative:** Run Jenkins myself.
* **Why:** Actions is free for a public repository, needs no server to patch, and anyone can click into the real runs. Jenkins is common in the job postings I read, so the translation shows how each concept maps.
* **Cost:** The ported files are translations and have not been run. I can explain the differences, but my hands-on experience is with Actions.

## kind in the pipeline instead of EKS

* **Decision:** Test the Kubernetes manifests in a kind cluster created inside the pipeline on every run.
* **Alternative:** A real EKS cluster, or a laptop-only demo.
* **Why:** The EKS control plane bills by the hour even when idle. Pod Security Admission and NetworkPolicy are standard Kubernetes API objects, and kind enforces both, so the tests prove the same controls. Running it in CI means every change is deployed under `restricted` before it can publish, not just once on my laptop.
* **Cost:** IRSA is designed but not deployed; it needs EKS. A kind cluster has no cloud load balancer or IAM integration.

## The pipeline role ARN in the workflow file

* **Decision:** Write the role ARN directly in `gatekeeper.yml`.
* **Alternative:** A GitHub secret or repository variable.
* **Why:** It is an identifier, not a credential. Using it requires a GitHub OIDC token that matches the trust policy. Keeping it in the file makes the pipeline readable in one place.
* **Cost:** Changing the role means a commit, which also means a review.

## Replace `ping` with a TCP check

* **Decision:** `/ping` opens a TCP connection to port 443 with Python's `socket` library and only accepts public addresses.
* **Alternative:** Install `iputils-ping` in the image and add the `NET_RAW` capability back.
* **Why:** The slim image has no `ping`, and the hardened pod drops `NET_RAW`. Adding them back would undo two hardening steps. Without a subprocess, there is no command to inject into.
* **Cost:** It checks TCP reachability on one port, not ICMP. For a reachability check that is the more useful answer anyway, since many hosts drop ICMP.
