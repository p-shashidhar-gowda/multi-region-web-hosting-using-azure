#!/bin/bash

sudo apt update 
sudo apt upgrade -y 

sudo apt install apache2 -y

cat <<EOF | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Global CDN - Central India</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f3f2f1;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            color: #323130;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 400px;
            width: 90%;
            border-top: 6px solid #0078d4;
        }
        h1 {
            color: #0078d4;
            font-size: 24px;
            margin-bottom: 5px;
        }
        h2 {
            font-size: 18px;
            font-weight: 500;
            color: #605e5c;
            margin-top: 0;
            margin-bottom: 30px;
        }
        .btn {
            background-color: #0078d4;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 4px;
            font-weight: 600;
            display: inline-block;
            transition: background-color 0.2s;
        }
        .btn:hover {
            background-color: #106ebe;
        }
        .region-badge {
            background-color: #e1dfdd;
            color: #323130;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 20px;
            display: inline-block;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Global CDN</h1>
        <span class="region-badge">📍 Central India</span>
        <h2>Welcome to the India Node</h2>
        <p style="margin-bottom:30px; color:#605e5c;">Experience low-latency content delivery powered by Azure.</p>
        <a href="/upload/index.html" class="btn">Manage Uploads</a>
    </div>
</body>
</html>
EOF

sudo systemctl enable apache2
sudo systemctl restart apache2