#!/bin/bash
set -e

# Update system packages
dnf update -y

# Install nginx
dnf install -y nginx

# Write the SIR application landing page
cat > /usr/share/nginx/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SIR — Site Incident Reporting</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #1a1a2e;
            color: #eaeaea;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
            background-color: #16213e;
            padding: 40px 60px;
            border-radius: 8px;
            border: 1px solid #0f3460;
        }
        h1 { color: #e94560; margin-bottom: 5px; }
        .subtitle { color: #a8a8b3; margin-bottom: 30px; }
        .status-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            text-align: left;
            margin-top: 20px;
        }
        .label { color: #a8a8b3; }
        .value { color: #eaeaea; font-weight: bold; }
        .online { color: #00b894; }
        .pending { color: #fdcb6e; }
        .footer {
            margin-top: 30px;
            font-size: 12px;
            color: #a8a8b3;
            border-top: 1px solid #0f3460;
            padding-top: 15px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>SIR</h1>
        <p class="subtitle">Site Incident Reporting System</p>
        <div class="status-grid">
            <span class="label">Environment:</span>
            <span class="value">${environment}</span>
            <span class="label">Region:</span>
            <span class="value">${region}</span>
            <span class="label">Status:</span>
            <span class="value online">Online</span>
            <span class="label">Database:</span>
            <span class="value pending">Pending (Phase 5)</span>
        </div>
        <div class="footer">
            Infrastructure: Terraform on AWS &nbsp;|&nbsp; Managed by: Terraform
        </div>
    </div>
</body>
</html>
EOF

# Enable and start nginx
systemctl enable nginx
systemctl start nginx