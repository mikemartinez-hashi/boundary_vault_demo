output "ubuntu_public_ip" {
  description = "Ubuntu server public IP (web page only — SSH is Boundary-only)"
  value       = aws_instance.ubuntu.public_ip
}

output "windows_public_ip" {
  description = "Windows server public IP (web page only — RDP is Boundary-only)"
  value       = aws_instance.windows.public_ip
}

output "boundary_worker_public_ip" {
  description = "Self-managed Boundary worker public IP"
  value       = aws_instance.boundary_worker.public_ip
}

output "boundary_ubuntu_target_id" {
  description = "Boundary target ID for the Ubuntu SSH target"
  value       = boundary_target.ubuntu_ssh.id
}

output "boundary_windows_target_id" {
  description = "Boundary target ID for the Windows RDP target"
  value       = boundary_target.windows_rdp.id
}

output "connect_ubuntu" {
  description = "Connect to the Ubuntu server through Boundary"
  value       = "boundary connect ssh -target-id ${boundary_target.ubuntu_ssh.id} -- -l ${var.ubuntu_demo_username}"
}

output "connect_windows" {
  description = "Connect to the Windows server through Boundary"
  value       = "boundary connect rdp -target-id ${boundary_target.windows_rdp.id}"
}

output "authenticate" {
  description = "Authenticate the Boundary CLI first"
  value       = "BOUNDARY_ADDR=${var.boundary_addr} boundary authenticate password -auth-method-id ${var.boundary_auth_method_id} -login-name ${var.boundary_login_name}"
  sensitive   = true
}
