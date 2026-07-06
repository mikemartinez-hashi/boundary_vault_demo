#!/bin/bash
set -e

# ---------- Install the Boundary Enterprise binary (required for HCP workers) ----------
apt-get update -y
apt-get install -y curl gnupg lsb-release

curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list
apt-get update -y
apt-get install -y boundary-enterprise

# ---------- Worker configuration (controller-led registration) ----------
IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)

mkdir -p /etc/boundary.d/worker-auth

cat <<EOF > /etc/boundary.d/boundary.hcl
disable_mlock = true

hcp_boundary_cluster_id = "${hcp_boundary_cluster_id}"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  public_addr                           = "$PUBLIC_IP:9202"
  auth_storage_path                     = "/etc/boundary.d/worker-auth"
  controller_generated_activation_token = "${activation_token}"

  tags {
    type = ["demo", "aws"]
  }
}
EOF

chown -R boundary:boundary /etc/boundary.d
chmod 700 /etc/boundary.d/worker-auth

systemctl enable boundary
systemctl restart boundary
