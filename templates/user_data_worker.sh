#!/bin/bash
# Log everything (console + file) so a failed registration is visible via
# SSM / EC2 serial console at /var/log/boundary-worker-init.log
exec > >(tee -a /var/log/boundary-worker-init.log) 2>&1
echo "=== boundary worker init starting $(date -u) ==="

export DEBIAN_FRONTEND=noninteractive

# ---------- Install the Boundary Enterprise binary (required for HCP workers) ----------
apt-get update -y
apt-get install -y curl gnupg lsb-release

curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list
apt-get update -y
apt-get install -y boundary-enterprise

echo "boundary binary: $(command -v boundary) / $(boundary version 2>/dev/null | head -1)"

# ---------- Resolve public address (IMDSv2, fall back to private) ----------
IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
if [ -z "$PUBLIC_IP" ]; then
  PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
fi
echo "worker public_addr: $PUBLIC_IP:9202"

# ---------- Worker configuration (controller-led registration) ----------
mkdir -p /etc/boundary.d/worker-auth

cat > /etc/boundary.d/boundary.hcl <<EOF
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

# ---------- Explicit systemd unit (don't depend on the packaged one) ----------
cat > /etc/systemd/system/boundary-worker.service <<'EOF'
[Unit]
Description=Boundary Worker
Requires=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/boundary server -config=/etc/boundary.d/boundary.hcl
User=root
Group=root
Restart=on-failure
RestartSec=5
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

chown -R root:root /etc/boundary.d
chmod 700 /etc/boundary.d/worker-auth

systemctl daemon-reload
systemctl enable boundary-worker
systemctl restart boundary-worker

sleep 5
echo "=== boundary-worker service status ==="
systemctl status boundary-worker --no-pager || true
echo "=== boundary worker init done $(date -u) ==="
