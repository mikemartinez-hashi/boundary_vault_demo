<powershell>
Set-ExecutionPolicy Bypass -Scope Process -Force

# ---------- Demo admin user brokered by Boundary/Vault ----------
$Password = ConvertTo-SecureString '${admin_password}' -AsPlainText -Force
New-LocalUser -Name '${admin_username}' -Password $Password -PasswordNeverExpires -FullName 'Boundary Demo Admin'
Add-LocalGroupMember -Group 'Administrators' -Member '${admin_username}'
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member '${admin_username}'

# ---------- Web demo page (same as tf-demo-hashi-windows template) ----------
Install-WindowsFeature -name Web-Server -IncludeManagementTools
Remove-Item -Path "C:\inetpub\wwwroot\iisstart.htm" -Force -ErrorAction SilentlyContinue

$htmlContent = @"
<h1>Hello! This is a Boundary + Vault demo from the SE Team</h1>
<p>Instance Type: ${instance_type}</p>
<p>Environment: ${environment}</p>
<p>Region: ${region}</p>
<p>OS: Windows Server 2025</p>
"@

$htmlContent | Out-File -FilePath "C:\inetpub\wwwroot\index.html" -Encoding utf8
</powershell>
