/**
 * Resolve the frame-ancestors CSP directive.
 *
 * When the env var OPENCLAW_ALLOWED_FRAME_ANCESTORS is set (comma or
 * space separated list of origins), the Control UI can be embedded in
 * iframes from those origins.  Otherwise it defaults to 'none' which
 * blocks all embedding.
 */
function resolveFrameAncestors(): string {
  const envVal = process.env.OPENCLAW_ALLOWED_FRAME_ANCESTORS;
  if (envVal && envVal.trim()) {
    // Accept comma or space-separated origins
    const origins = envVal
      .split(/[\s,]+/)
      .map((o) => o.trim())
      .filter(Boolean);
    if (origins.length > 0) {
      return `frame-ancestors ${origins.join(" ")}`;
    }
  }
  return "frame-ancestors 'none'";
}

export function buildControlUiCspHeader(): string {
  // Control UI: conditionally allow framing, block inline scripts, keep styles permissive
  // (UI uses a lot of inline style attributes in templates).
  return [
    "default-src 'self'",
    "base-uri 'none'",
    "object-src 'none'",
    resolveFrameAncestors(),
    "script-src 'self'",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "img-src 'self' data: https:",
    "font-src 'self' https://fonts.gstatic.com",
    "connect-src 'self' ws: wss:",
  ].join("; ");
}
