#!/bin/bash
set -e

# ---------- Web demo page (same as tf-demo-hashi template) ----------
sudo apt-get update -y
sudo apt-get install -y apache2
sudo systemctl enable apache2
sudo systemctl start apache2

sudo cat <<EOF > /var/www/html/index.html
<h1>Hello! This is a Boundary + Vault demo from the SE Team</h1>
<p>Instance Type: ${instance_type}</p>
<p>Environment: ${environment}</p>
<p>Region: ${region}</p>
<p>OS: Ubuntu 24.04</p>
EOF

# ---------- Demo user brokered by Boundary/Vault ----------
useradd -m -s /bin/bash '${demo_username}'
echo '${demo_username}:${demo_password}' | chpasswd
usermod -aG sudo '${demo_username}'

# Ubuntu cloud images disable password auth; re-enable it for the brokered
# username/password credential (cloud-init drops a "no" in sshd_config.d)
cat <<EOF > /etc/ssh/sshd_config.d/99-boundary-demo.conf
PasswordAuthentication yes
EOF
systemctl restart ssh
