# ---------- AWS ----------

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "environment" {
  description = "Environment Type (used in names and tags)"
  type        = string
  default     = "Demo"
}

variable "owner" {
  description = "Owner tag applied to all instances"
  type        = string
  default     = "SE Team"
}

variable "demo" {
  description = "Type tag applied to all instances"
  type        = string
  default     = "boundary-vault-demo"
}

variable "key_name" {
  description = "Optional existing EC2 key pair (break-glass access; Boundary is the intended access path)"
  type        = string
  default     = "linux-demo-kp"
}

variable "windows_instance_type" {
  description = "EC2 instance type for the Windows server"
  type        = string
  default     = "t3.medium"
}

variable "linux_instance_type" {
  description = "EC2 instance type for the Ubuntu server"
  type        = string
  default     = "t3.micro"
}

variable "worker_instance_type" {
  description = "EC2 instance type for the self-managed Boundary worker"
  type        = string
  default     = "t3.small"
}

# ---------- HCP Boundary ----------

variable "boundary_addr" {
  description = "HCP Boundary cluster URL, e.g. https://<cluster-uuid>.boundary.hashicorp.cloud"
  type        = string
}

variable "boundary_auth_method_id" {
  description = "Boundary password auth method ID in the global scope (ampw_...)"
  type        = string
}

variable "boundary_login_name" {
  description = "Boundary admin login name"
  type        = string
}

variable "boundary_password" {
  description = "Boundary admin password"
  type        = string
  sensitive   = true
}

# ---------- HCP Vault ----------

variable "vault_address" {
  description = "HCP Vault public address, e.g. https://<cluster>.hashicorp.cloud:8200"
  type        = string
}

variable "vault_admin_token" {
  description = "HCP Vault admin token (used by Terraform to configure Vault)"
  type        = string
  sensitive   = true
}

variable "vault_namespace" {
  description = "Vault namespace (HCP Vault uses 'admin' by default)"
  type        = string
  default     = "admin"
}

variable "vault_kv_path" {
  description = "Mount path for the demo KV v2 secrets engine"
  type        = string
  default     = "boundary-demo"
}

# ---------- Demo credentials ----------

variable "ubuntu_demo_username" {
  description = "Local user created on the Ubuntu server and brokered by Boundary"
  type        = string
  default     = "demo-user"
}

variable "windows_admin_username" {
  description = "Local admin user created on the Windows server and brokered by Boundary"
  type        = string
  default     = "demo-admin"
}
