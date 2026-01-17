#!/bin/bash
# Start/restart the Cloudflare tunnel for listonit

# Kill existing tunnel if running
pkill -f "cloudflared tunnel run listonit" 2>/dev/null

# Start tunnel in background
nohup cloudflared tunnel run listonit > /tmp/cloudflared.log 2>&1 &

echo "Cloudflare tunnel started (PID: $!)"
echo "Logs: /tmp/cloudflared.log"
echo "URL: https://api.manyhappyapples.com"
