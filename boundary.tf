# ---------- Scopes ----------

resource "boundary_scope" "org" {
  scope_id    = "global"
  name        = "se-demo-org"
  description = "SE demo org"

  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_scope" "project" {
  scope_id    = boundary_scope.org.id
  name        = "boundary-vault-demo"
  description = "Boundary + Vault demo project"

  auto_create_admin_role   = true
  auto_create_default_role = true
}

# ---------- Hosts ----------

resource "boundary_host_catalog_static" "demo" {
  scope_id    = boundary_scope.project.id
  name        = "demo-servers"
  description = "Windows and Ubuntu demo servers"
}

resource "boundary_host_static" "ubuntu" {
  host_catalog_id = boundary_host_catalog_static.demo.id
  name            = "ubuntu-target"
  address         = aws_instance.ubuntu.private_ip
}

resource "boundary_host_static" "windows" {
  host_catalog_id = boundary_host_catalog_static.demo.id
  name            = "windows-target"
  address         = aws_instance.windows.private_ip
}

resource "boundary_host_set_static" "ubuntu" {
  host_catalog_id = boundary_host_catalog_static.demo.id
  name            = "ubuntu-servers"
  host_ids        = [boundary_host_static.ubuntu.id]
}

resource "boundary_host_set_static" "windows" {
  host_catalog_id = boundary_host_catalog_static.demo.id
  name            = "windows-servers"
  host_ids        = [boundary_host_static.windows.id]
}

# ---------- Vault credential store + libraries ----------

resource "boundary_credential_store_vault" "hcp_vault" {
  scope_id    = boundary_scope.project.id
  name        = "hcp-vault"
  description = "HCP Vault credential store"
  address     = var.vault_address
  namespace   = var.vault_namespace
  token       = vault_token.boundary.client_token
}

resource "boundary_credential_library_vault" "ubuntu" {
  credential_store_id = boundary_credential_store_vault.hcp_vault.id
  name                = "ubuntu-creds"
  path                = "${var.vault_kv_path}/data/ubuntu"
  http_method         = "GET"
  credential_type     = "username_password"
}

resource "boundary_credential_library_vault" "windows" {
  credential_store_id = boundary_credential_store_vault.hcp_vault.id
  name                = "windows-creds"
  path                = "${var.vault_kv_path}/data/windows"
  http_method         = "GET"
  credential_type     = "username_password"
}

# ---------- Targets ----------

locals {
  worker_filter = "\"demo\" in \"/tags/type\""
}

resource "boundary_target" "ubuntu_ssh" {
  scope_id     = boundary_scope.project.id
  type         = "tcp"
  name         = "ubuntu-ssh"
  description  = "SSH to the Ubuntu server with Vault-brokered credentials"
  default_port = 22

  host_source_ids = [boundary_host_set_static.ubuntu.id]

  brokered_credential_source_ids = [
    boundary_credential_library_vault.ubuntu.id
  ]

  egress_worker_filter     = local.worker_filter
  session_connection_limit = -1
}

resource "boundary_target" "windows_rdp" {
  scope_id     = boundary_scope.project.id
  type         = "tcp"
  name         = "windows-rdp"
  description  = "RDP to the Windows server with Vault-brokered credentials"
  default_port = 3389

  host_source_ids = [boundary_host_set_static.windows.id]

  brokered_credential_source_ids = [
    boundary_credential_library_vault.windows.id
  ]

  egress_worker_filter     = local.worker_filter
  session_connection_limit = -1
}
