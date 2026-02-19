import { describe, expect, it } from "vitest";
import { buildControlUiCspHeader } from "./control-ui-csp.js";

describe("buildControlUiCspHeader", () => {
  it("blocks inline scripts while allowing inline styles", () => {
    // Ensure env is clean for this test
    delete process.env.OPENCLAW_ALLOWED_FRAME_ANCESTORS;
    const csp = buildControlUiCspHeader();
    expect(csp).toContain("frame-ancestors 'none'");
    expect(csp).toContain("script-src 'self'");
    expect(csp).not.toContain("script-src 'self' 'unsafe-inline'");
    expect(csp).toContain("style-src 'self' 'unsafe-inline'");
  });

  it("allows configurable frame-ancestors via env var", () => {
    process.env.OPENCLAW_ALLOWED_FRAME_ANCESTORS = "https://*.vercel.app https://devs.ai http://localhost:3000";
    try {
      const csp = buildControlUiCspHeader();
      expect(csp).not.toContain("frame-ancestors 'none'");
      expect(csp).toContain("frame-ancestors https://*.vercel.app https://devs.ai http://localhost:3000");
    } finally {
      delete process.env.OPENCLAW_ALLOWED_FRAME_ANCESTORS;
    }
  });

  it("falls back to frame-ancestors 'none' with empty env var", () => {
    process.env.OPENCLAW_ALLOWED_FRAME_ANCESTORS = "  ";
    try {
      const csp = buildControlUiCspHeader();
      expect(csp).toContain("frame-ancestors 'none'");
    } finally {
      delete process.env.OPENCLAW_ALLOWED_FRAME_ANCESTORS;
    }
  });
});
