#!/bin/sh
# Railway startup script for OpenClaw
# Creates config on first boot and starts the gateway bound to 0.0.0.0

# Create OpenClaw config directory
mkdir -p /data/.openclaw

# Write config on first boot.
# Subsequent changes made via the OpenClaw UI are preserved.
if [ ! -f /data/.openclaw/openclaw.json ]; then

  if [ -n "$DEVS_AI_AGENT_ID" ] && [ -n "$OPENAI_API_BASE_URL" ]; then
    # ── Devs.ai agent selected ──────────────────────────────────────────
    # Register a custom "devsai" LLM provider that routes through the
    # Atreides OpenAI-compatible proxy.  OpenClaw resolves ${ENV_VAR}
    # references in its JSON config at runtime.
    cat > /data/.openclaw/openclaw.json << EOFCFG
{
  "gateway": {
    "controlUi": {
      "dangerouslyDisableDeviceAuth": true
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "devsai": {
        "baseUrl": "\${OPENAI_API_BASE_URL}",
        "apiKey": "\${OPENAI_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "${DEVS_AI_AGENT_ID}",
            "name": "Devs.ai Agent",
            "reasoning": false,
            "input": ["text"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": 128000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "devsai/${DEVS_AI_AGENT_ID}"
      }
    }
  }
}
EOFCFG
    echo "[start.sh] Configured Devs.ai proxy provider for agent: ${DEVS_AI_AGENT_ID}"
    echo "[start.sh] Proxy base URL: ${OPENAI_API_BASE_URL}"

  else
    # ── No Devs.ai agent — default config ───────────────────────────────
    # User configures their own LLM provider in the OpenClaw Setup Wizard
    # or Control UI (Settings → LLM Keys).
    cat > /data/.openclaw/openclaw.json << 'EOF'
{"gateway":{"controlUi":{"dangerouslyDisableDeviceAuth":true}}}
EOF
    echo "[start.sh] Created default config (no Devs.ai agent — configure LLM in OpenClaw UI)"
  fi
fi

# Start gateway bound to 0.0.0.0 (required for Railway's proxy to reach the app)
exec node openclaw.mjs gateway --allow-unconfigured --bind lan
