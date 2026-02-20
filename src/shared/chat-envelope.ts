const ENVELOPE_PREFIX = /^\[([^\]]+)\]\s*/;
const ENVELOPE_CHANNELS = [
  "WebChat",
  "WhatsApp",
  "Telegram",
  "Signal",
  "Slack",
  "Discord",
  "Google Chat",
  "iMessage",
  "Teams",
  "Matrix",
  "Zalo",
  "Zalo Personal",
  "BlueBubbles",
];

const MESSAGE_ID_LINE = /^\s*\[message_id:\s*[^\]]+\]\s*$/i;

function looksLikeEnvelopeHeader(header: string): boolean {
  if (/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}Z\b/.test(header)) {
    return true;
  }
  if (/\d{4}-\d{2}-\d{2} \d{2}:\d{2}\b/.test(header)) {
    return true;
  }
  return ENVELOPE_CHANNELS.some((label) => header.startsWith(`${label} `));
}

export function stripEnvelope(text: string): string {
  // First strip any inbound metadata blocks that precede the envelope.
  // These are injected by OpenClaw for LLM context but should not be shown
  // in the chat UI.
  const stripped = stripInboundMeta(text);

  const match = stripped.match(ENVELOPE_PREFIX);
  if (!match) {
    return stripped;
  }
  const header = match[1] ?? "";
  if (!looksLikeEnvelopeHeader(header)) {
    return stripped;
  }
  return stripped.slice(match[0].length);
}

/**
 * Strip OpenClaw-injected inbound metadata blocks from message text.
 *
 * Removes blocks like:
 *   Conversation info (untrusted metadata):
 *   ```json
 *   { "message_id": "...", "sender": "..." }
 *   ```
 *
 * These are prepended by `buildInboundUserContextPrefix()` for the LLM's
 * benefit and should not appear in the chat UI.
 */
export function stripInboundMeta(text: string): string {
  // Match: "Label (untrusted ...) :\n```json\n...\n```"
  // Covers: Conversation info, Sender, Forwarded message context,
  //         Chat history since last reply, Replied message, Thread starter
  return text.replace(
    /(?:Conversation info|Sender|Forwarded message context|Chat history since last reply|Replied message|Thread starter)\s*\([^)]*\):\s*```(?:json)?\s*[\s\S]*?```\s*/g,
    "",
  ).trim();
}

export function stripMessageIdHints(text: string): string {
  if (!text.includes("[message_id:")) {
    return text;
  }
  const lines = text.split(/\r?\n/);
  const filtered = lines.filter((line) => !MESSAGE_ID_LINE.test(line));
  return filtered.length === lines.length ? text : filtered.join("\n");
}
