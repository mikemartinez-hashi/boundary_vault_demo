# Self-managed Boundary worker (controller-led registration).
# HCP Boundary routes sessions: client -> HCP -> this worker -> private target.

locals {
  # https://<cluster-uuid>.boundary.hashicorp.cloud -> <cluster-uuid>
  hcp_boundary_cluster_id = split(".", replace(var.boundary_addr, "https://", ""))[0]
}

resource "boundary_worker" "aws" {
  scope_id    = "global"
  name        = "aws-worker-${var.environment}"
  description = "Self-managed worker in AWS for the Boundary + Vault demo"
}

resource "aws_security_group" "boundary_worker" {
  name = "boundary-demo-worker-${var.environment}"

  ingress {
    description = "Boundary session proxy"
    from_port   = 9202
    to_port     = 9202
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "boundary_worker" {
  ami                    = data.aws_ami.hc_base_ubuntu_2404.id
  instance_type          = var.worker_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.boundary_worker.id]

  tags = {
    Name        = "boundary-worker-${var.environment}"
    Type        = var.demo
    Environment = var.environment
    Owner       = var.owner
  }

  user_data = templatefile("${path.module}/templates/user_data_worker.sh", {
    hcp_boundary_cluster_id = local.hcp_boundary_cluster_id
    activation_token        = boundary_worker.aws.controller_generated_activation_token
  })

  user_data_replace_on_change = true
}
