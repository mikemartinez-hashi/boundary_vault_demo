provider "aws" {
  region = var.region
}

# HCP Boundary cluster.
# Credentials come from the `boundary_config` variable set in HCP Terraform
# (terraform-category vars), so they must be wired in explicitly here.
provider "boundary" {
  addr                   = var.boundary_addr
  auth_method_id         = var.boundary_auth_method_id
  auth_method_login_name = var.boundary_login_name
  auth_method_password   = var.boundary_password
}

# HCP Vault cluster.
# Configured automatically by HCP Terraform's Vault-backed dynamic provider
# credentials (the Vault variable set: TFC_VAULT_PROVIDER_AUTH=true,
# TFC_VAULT_ADDR, TFC_VAULT_NAMESPACE, TFC_VAULT_RUN_ROLE). HCP Terraform
# authenticates via workload identity and injects the address, namespace, and a
# short-lived token — so this block stays empty. Do not set address/token here.
provider "vault" {}
