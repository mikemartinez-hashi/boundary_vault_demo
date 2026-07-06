# ---------- AMIs (same base images as the tf-demo-hashi templates) ----------

data "aws_ami" "hc_base_windows" {
  filter {
    name   = "name"
    values = ["hc-base-windows-server-2025*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  most_recent = true
  owners      = ["888995627335"] # ami-prod account
}

data "aws_ami" "hc_base_ubuntu_2404" {
  filter {
    name   = "name"
    values = ["hc-base-ubuntu-2404-amd64-*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  most_recent = true
  owners      = ["888995627335"] # ami-prod account
}

# ---------- Security groups ----------
# SSH/RDP is only reachable from the Boundary worker — the whole point of the
# demo is that Boundary is the sole access path to the servers.

resource "aws_security_group" "ubuntu" {
  name = "boundary-demo-ubuntu-${var.environment}"

  ingress {
    description = "HTTPS from anywhere (web demo page)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere (web demo page)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "SSH from the Boundary worker only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.boundary_worker.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "windows" {
  name = "boundary-demo-windows-${var.environment}"

  ingress {
    description = "HTTPS from anywhere (web demo page)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere (web demo page)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "RDP from the Boundary worker only"
    from_port       = 3389
    to_port         = 3389
    protocol        = "tcp"
    security_groups = [aws_security_group.boundary_worker.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- IAM for SSM (Windows, carried over from the windows template) ----------

resource "aws_iam_role" "ssm_role" {
  name = "boundary_demo_ssm_role_${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "boundary_demo_ssm_profile_${var.environment}"
  role = aws_iam_role.ssm_role.name
}

# ---------- Demo credentials (generated here, stored in Vault, brokered by Boundary) ----------

resource "random_password" "ubuntu" {
  length           = 20
  special          = true
  override_special = "!@#%^*()-_=+"
}

resource "random_password" "windows" {
  length           = 20
  special          = true
  override_special = "!@#%^*()-_=+"
}

# ---------- Instances ----------

resource "aws_instance" "ubuntu" {
  ami                    = data.aws_ami.hc_base_ubuntu_2404.id
  instance_type          = var.linux_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ubuntu.id]

  tags = {
    Name        = "ubuntu-target-${var.environment}"
    Type        = var.demo
    Environment = var.environment
    Owner       = var.owner
  }

  user_data = templatefile("${path.module}/templates/user_data_ubuntu.sh", {
    environment   = var.environment
    region        = var.region
    instance_type = var.linux_instance_type
    demo_username = var.ubuntu_demo_username
    demo_password = random_password.ubuntu.result
  })

  user_data_replace_on_change = true
}

resource "aws_instance" "windows" {
  ami                    = data.aws_ami.hc_base_windows.id
  instance_type          = var.windows_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.windows.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  tags = {
    Name        = "windows-target-${var.environment}"
    Type        = var.demo
    Environment = var.environment
    Owner       = var.owner
  }

  user_data = templatefile("${path.module}/templates/user_data_windows.ps1", {
    environment    = var.environment
    region         = var.region
    instance_type  = var.windows_instance_type
    admin_username = var.windows_admin_username
    admin_password = random_password.windows.result
  })

  user_data_replace_on_change = true
}
