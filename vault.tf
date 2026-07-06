# ---------- KV v2 secrets engine holding the server credentials ----------

resource "vault_mount" "kv" {
  path        = var.vault_kv_path
  type        = "kv"
  description = "Server credentials brokered by Boundary"

  options = {
    version = "2"
  }
}

resource "vault_kv_secret_v2" "ubuntu" {
  mount = vault_mount.kv.path
  name  = "ubuntu"

  data_json = jsonencode({
    username = var.ubuntu_demo_username
    password = random_password.ubuntu.result
  })
}

resource "vault_kv_secret_v2" "windows" {
  mount = vault_mount.kv.path
  name  = "windows"

  data_json = jsonencode({
    username = var.windows_admin_username
    password = random_password.windows.result
  })
}

# ---------- Policies + token for the Boundary credential store ----------

# Standard policy Boundary needs to manage its own Vault token
# https://developer.hashicorp.com/boundary/docs/concepts/credential-management
resource "vault_policy" "boundary_controller" {
  name = "boundary-controller"

  policy = <<-EOT
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }

    path "auth/token/renew-self" {
      capabilities = ["update"]
    }

    path "auth/token/revoke-self" {
      capabilities = ["update"]
    }

    path "sys/leases/renew" {
      capabilities = ["update"]
    }

    path "sys/leases/revoke" {
      capabilities = ["update"]
    }

    path "sys/capabilities-self" {
      capabilities = ["update"]
    }
  EOT
}

resource "vault_policy" "kv_read" {
  name = "boundary-demo-kv-read"

  policy = <<-EOT
    path "${var.vault_kv_path}/data/*" {
      capabilities = ["read"]
    }

    path "${var.vault_kv_path}/metadata/*" {
      capabilities = ["read", "list"]
    }
  EOT
}

# Boundary requires a periodic, orphan, renewable token
resource "vault_token" "boundary" {
  display_name = "boundary-credential-store"

  policies = [
    vault_policy.boundary_controller.name,
    vault_policy.kv_read.name,
  ]

  no_default_policy = true
  no_parent         = true
  renewable         = true
  period            = "24h"
}
