<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ClipSync - Quick Setup</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 700px;
            margin: 0 auto;
            padding: 20px;
            line-height: 1.6;
            color: #333;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            text-align: center;
            margin-bottom: 30px;
        }
        .step {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 20px;
            margin: 20px 0;
            border-radius: 0 8px 8px 0;
        }
        .code {
            background: #2d3748;
            color: #e2e8f0;
            padding: 15px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            margin: 10px 0;
            overflow-x: auto;
        }
        .success {
            background: #d4edda;
            border: 1px solid #c3e6cb;
            color: #155724;
            padding: 15px;
            border-radius: 8px;
            margin: 15px 0;
            text-align: center;
        }
        h2 {
            color: #667eea;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔄 ClipSync</h1>
        <p>Clipboard sync between devices</p>
    </div>

    <h2>1️⃣ Clone Repository</h2>
    <div class="step">
        <div class="code">git clone https://github.com/idanless/ClipSync.git
cd ClipSync</div>
    </div>

    <h2>2️⃣ Run Server</h2>
    <div class="step">
        <div class="code">sudo ./run_clipsync.sh</div>
    </div>

    <h2>3️⃣ Connect Windows Client</h2>
    <div class="step">
        <p>1. Open Windows client</p>
        <p>2. Enter your server IP address</p>
        <p>3. Connect</p>
    </div>

    <div class="success">
        <h3>✅ Done!</h3>
        <p>Both devices now sync clipboard automatically.<br>
        Copy on one side → Paste on the other!</p>
    </div>
</body>
</html>
