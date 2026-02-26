import { describe, it, expect } from "vitest";
import { detect, luhn, type PatternType } from "./detect";

const ALL_PATTERNS = new Set<PatternType>(["cc", "ssn", "sin"]);

describe("luhn", () => {
  it.each([
    ["4111111111111111", true],
    ["4111111111111112", false],
    ["5500000000000004", true],
    ["378282246310005", true],
    ["0000000000000000", true],
    ["1234567890123456", false],
  ])("validates %s as %s", (digits, expected) => {
    expect(luhn(digits)).toBe(expected);
  });
});

describe("detect", () => {
  describe("credit cards", () => {
    it.each([
      ["4111111111111111", "plain Visa"],
      ["4111 1111 1111 1111", "spaced Visa"],
      ["4111-1111-1111-1111", "dashed Visa"],
      ["5500000000000004", "Mastercard"],
      ["378282246310005", "Amex"],
    ])("detects %s (%s)", (input) => {
      const results = detect(input, ALL_PATTERNS);
      expect(results).toHaveLength(1);
      expect(results[0].type).toBe("cc");
    });

    it("rejects invalid Luhn numbers", () => {
      expect(detect("4111111111111112", ALL_PATTERNS)).toHaveLength(0);
    });

    it("rejects short numbers", () => {
      expect(detect("411111111111", ALL_PATTERNS)).toHaveLength(0);
    });
  });

  describe("SSN (US)", () => {
    it("detects valid SSN format", () => {
      const results = detect("123-45-6789", ALL_PATTERNS);
      expect(results).toHaveLength(1);
      expect(results[0].type).toBe("ssn");
    });

    it("ignores SSN without dashes", () => {
      expect(detect("123456789", new Set<PatternType>(["ssn"]))).toHaveLength(0);
    });
  });

  describe("SIN (CA)", () => {
    it.each([
      ["123 456 789", "spaced"],
      ["123-456-789", "dashed"],
    ])("detects %s SIN", (input) => {
      const results = detect(input, ALL_PATTERNS);
      expect(results.some((r) => r.type === "sin")).toBe(true);
    });
  });

  describe("pattern filtering", () => {
    it("respects enabled patterns", () => {
      const ccOnly = new Set<PatternType>(["cc"]);
      expect(detect("123-45-6789", ccOnly)).toHaveLength(0);
    });

    it("returns empty for no enabled patterns", () => {
      expect(detect("4111111111111111", new Set())).toHaveLength(0);
    });
  });

  describe("mixed content", () => {
    it("detects sensitive data embedded in text", () => {
      const text = "My card is 4111 1111 1111 1111 and SSN is 123-45-6789";
      const results = detect(text, ALL_PATTERNS);
      expect(results.length).toBeGreaterThanOrEqual(2);
    });

    it("ignores clean text", () => {
      expect(detect("Hello world, nothing sensitive here!", ALL_PATTERNS)).toHaveLength(0);
    });
  });
});
