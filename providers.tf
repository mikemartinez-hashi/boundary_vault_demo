provider "aws" {
  region = var.region
}

# HCP Boundary cluster
provider "boundary" {
  addr                            = var.boundary_addr
  auth_method_id                  = var.boundary_auth_method_id
  password_auth_method_login_name = var.boundary_login_name
  password_auth_method_password   = var.boundary_password
}

# HCP Vault cluster (public endpoint must be enabled)
provider "vault" {
  address   = var.vault_address
  token     = var.vault_admin_token
  namespace = var.vault_namespace
}
