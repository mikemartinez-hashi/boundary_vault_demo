# Boundary + Vault Demo

Single `terraform apply` that stands up a complete HCP Boundary + HCP Vault access demo:

- **Ubuntu 24.04 server** (hc-base image) running Apache — SSH reachable *only* from the Boundary worker
- **Windows Server 2025** (hc-base image) running IIS — RDP reachable *only* from the Boundary worker
- **Self-managed Boundary worker** (Ubuntu, `boundary-enterprise`), auto-registered to your HCP Boundary cluster via controller-led activation
- **Vault**: KV v2 mount with the generated server credentials, plus the periodic/orphan token Boundary uses
- **Boundary**: org + project scopes, static host catalog, Vault credential store, credential libraries, and two targets (`ubuntu-ssh`, `windows-rdp`) with brokered credentials

## Demo story

"Nobody knows the server passwords." Terraform generates random credentials, stores them in Vault, and locks SSH/RDP down to the worker's security group. The only way in is `boundary connect`, which brokers the credential from Vault at session time — with full session visibility in HCP Boundary.

## Prerequisites

This deployment runs in **HCP Terraform**. The workspace needs:

1. **HCP Boundary cluster** (any tier — brokered credentials work on Standard). Wired via the `boundary_config` variable set (terraform category): `boundary_addr`, `boundary_auth_method_id` (`ampw_...` from the cluster's Auth Methods page), `boundary_login_name`, `boundary_password`.
2. **HCP Vault cluster** with the **public endpoint enabled**. The Vault provider authenticates via HCP Terraform's Vault-backed dynamic credentials — set the Vault variable set (env category): `TFC_VAULT_PROVIDER_AUTH=true`, `TFC_VAULT_ADDR`, `TFC_VAULT_NAMESPACE=admin`, `TFC_VAULT_RUN_ROLE=tfc-admin-role`. The `tfc-admin-role` Vault role must have a policy that can create a KV mount, write secrets, create policies, and **create an orphan token** (`auth/token/create-orphan` / sudo) with the `boundary-controller` and `boundary-demo-kv-read` policies attached — otherwise the `vault_token.boundary` resource fails at apply.
3. **AWS credentials** for the workspace (dynamic provider credentials or an AWS var set). The hc-base AMIs from `888995627335` must be visible in `region`.
4. Workspace variable `vault_address` (the HCP Vault public address, same value as `TFC_VAULT_ADDR`) — Boundary's credential store needs it as a terraform-readable variable since env-category vars aren't visible inside the config.

## Run it

Queue a plan/apply in the HCP Terraform workspace (VCS-driven or CLI-driven). No `terraform.tfvars` for secrets — everything comes from the variable sets above.

Give the instances ~3–5 minutes after apply for user_data to finish (Windows takes the longest; the worker registers within ~1 minute).

## Demo walkthrough

```bash
# 1. Authenticate (command printed in outputs)
export BOUNDARY_ADDR=https://<cluster-uuid>.boundary.hashicorp.cloud
boundary authenticate password -auth-method-id ampw_XXXX -login-name admin

# 2. SSH to Ubuntu — Boundary fetches the credential from Vault and shows it
terraform output -raw connect_ubuntu   # then run it
# boundary connect ssh -target-id ttcp_XXXX -- -l demo-user
# (paste the brokered password when prompted)

# 3. RDP to Windows — brokered username/password displayed, local RDP client opens
boundary connect rdp -target-id <windows target id>

# 4. Show the goods in the UIs:
#    - HCP Boundary: active sessions, targets, worker health
#    - HCP Vault: boundary-demo/ KV mount, boundary-controller policy, token accessor
#    - Try to SSH/RDP directly to the public IP -> blocked by security group
```

## Talking points

- **Terraform** provisioned everything — infra *and* the Boundary/Vault config — in one apply (IaC for security posture, not just servers)
- **No standing credentials on laptops**: passwords live in Vault, brokered per-session by Boundary
- **Network segmentation**: targets have no public SSH/RDP exposure; the worker is the only path, and it dials *out* to HCP Boundary
- **Session visibility**: every connection is a recorded session event in Boundary (upgrade path: session recording, credential *injection* with SSH certs on Plus tier)

## Notes / demo-grade shortcuts

- Credentials pass through EC2 user_data (visible in instance metadata) — fine for a demo, not production. Production story: Vault agent / SSH cert injection.
- The Vault token Terraform creates for Boundary is periodic (24h) and renewable; Boundary renews it automatically. If the demo sits idle for weeks, re-run `terraform apply` to mint a fresh one.
- `terraform destroy` cleans up everything, including the Boundary scopes and Vault mount.

## Files

| File | Purpose |
|------|---------|
| `servers.tf` | Windows + Ubuntu targets, SGs, SSM role (from the tf-demo-hashi templates) |
| `worker.tf` | Self-managed worker EC2 + controller-led registration |
| `vault.tf` | KV mount, secrets, Boundary policies + periodic token |
| `boundary.tf` | Scopes, hosts, credential store/libraries, targets |
| `templates/` | user_data for Ubuntu, Windows, and the worker |
