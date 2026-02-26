import { getPreferenceValues } from "@raycast/api";
import type { PatternType } from "./detect";

interface RawPreferences {
  clearDelay: string;
  enableCC: boolean;
  enableSSN: boolean;
  enableSIN: boolean;
  showNotification: boolean;
}

export interface Preferences {
  clearDelay: number;
  enabledPatterns: Set<PatternType>;
  showNotification: boolean;
}

const PATTERN_MAP: Record<string, PatternType> = {
  enableCC: "cc",
  enableSSN: "ssn",
  enableSIN: "sin",
};

export function getPreferences(): Preferences {
  const raw = getPreferenceValues<RawPreferences>();
  const enabledPatterns = new Set<PatternType>();

  for (const [key, patternType] of Object.entries(PATTERN_MAP)) {
    if (raw[key as keyof RawPreferences]) {
      enabledPatterns.add(patternType);
    }
  }

  return {
    clearDelay: Math.max(1, parseInt(raw.clearDelay, 10) || 30),
    enabledPatterns,
    showNotification: raw.showNotification,
  };
}
