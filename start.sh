#!/bin/sh
# Railway startup script for OpenClaw
# Creates config on first boot and starts the gateway bound to 0.0.0.0

# Create OpenClaw config directory
mkdir -p /data/.openclaw

# Write default config on first boot (disables device pairing for headless containers)
if [ ! -f /data/.openclaw/openclaw.json ]; then
  cat > /data/.openclaw/openclaw.json << 'EOF'
{"gateway":{"controlUi":{"dangerouslyDisableDeviceAuth":true}}}
EOF
  echo "[start.sh] Created default config at /data/.openclaw/openclaw.json"
fi

# Start gateway bound to 0.0.0.0 (required for Railway's proxy to reach the app)
exec node openclaw.mjs gateway --allow-unconfigured --bind lan
