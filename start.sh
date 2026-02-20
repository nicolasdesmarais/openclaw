#!/bin/sh
# Railway startup script for OpenClaw
# Creates / updates config and starts the gateway bound to 0.0.0.0

# Create OpenClaw config directory
mkdir -p /data/.openclaw

# ──────────────────────────────────────────────────────────────────────────────
# Config generation strategy:
#   - When DEVS_AI_AGENT_ID is set, ALWAYS regenerate openclaw.json so that
#     env-var changes (new agent, new proxy URL) take effect on redeploy.
#   - When no DEVS_AI_AGENT_ID, only create a default config on first boot
#     (preserves manual LLM key edits made via the OpenClaw UI).
# ──────────────────────────────────────────────────────────────────────────────

NEEDS_WRITE=false

if [ -n "$DEVS_AI_AGENT_ID" ] && [ -n "$OPENAI_API_BASE_URL" ]; then
  # Always rewrite when Devs.ai proxy is configured — env vars may have changed
  NEEDS_WRITE=true
elif [ ! -f /data/.openclaw/openclaw.json ]; then
  # First boot without Devs.ai — write a minimal default config
  NEEDS_WRITE=true
fi

if [ "$NEEDS_WRITE" = "true" ]; then

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

  echo "[start.sh] Config written to /data/.openclaw/openclaw.json"
fi

# Log the resolved config for debugging (redact secrets)
echo "[start.sh] === Config summary ==="
echo "[start.sh] DEVS_AI_AGENT_ID=${DEVS_AI_AGENT_ID:-<not set>}"
echo "[start.sh] OPENAI_API_BASE_URL=${OPENAI_API_BASE_URL:-<not set>}"
echo "[start.sh] OPENAI_API_KEY=$(echo "${OPENAI_API_KEY}" | cut -c1-8)..."
echo "[start.sh] PORT=${PORT:-18789}"
echo "[start.sh] ======================"

# Start gateway bound to 0.0.0.0 (required for Railway's proxy to reach the app)
exec node openclaw.mjs gateway --allow-unconfigured --bind lan
