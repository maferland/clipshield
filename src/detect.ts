export type PatternType = "cc" | "ssn" | "sin";

export interface Detection {
  type: PatternType;
  label: string;
  match: string;
}

/**
 * Luhn algorithm — validates credit card check digit.
 */
export function luhn(digits: string): boolean {
  const nums = digits.split("").map(Number);
  let sum = 0;
  let alternate = false;

  for (let i = nums.length - 1; i >= 0; i--) {
    let n = nums[i];
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }

  return sum % 10 === 0;
}

const PATTERNS: Record<PatternType, { label: string; regex: RegExp; validate?: (match: string) => boolean }> = {
  cc: {
    label: "Credit Card",
    regex: /\b(?:\d[ -]*?){13,19}\b/g,
    validate: (match) => {
      const digits = match.replace(/[\s-]/g, "");
      return digits.length >= 13 && digits.length <= 19 && luhn(digits);
    },
  },
  ssn: {
    label: "SSN (US)",
    regex: /\b\d{3}-\d{2}-\d{4}\b/g,
  },
  sin: {
    label: "SIN (CA)",
    regex: /\b\d{3}[ -]\d{3}[ -]\d{3}\b/g,
  },
};

export function detect(text: string, enabled: Set<PatternType>): Detection[] {
  const results: Detection[] = [];

  for (const [type, { label, regex, validate }] of Object.entries(PATTERNS)) {
    if (!enabled.has(type as PatternType)) continue;

    const matches = text.matchAll(new RegExp(regex.source, regex.flags));
    for (const m of matches) {
      const match = m[0];
      if (validate && !validate(match)) continue;
      results.push({ type: type as PatternType, label, match });
    }
  }

  return results;
}
