import { Clipboard, Icon, MenuBarExtra, showHUD, Color, environment, LaunchType } from "@raycast/api";
import { useCachedState } from "@raycast/utils";
import { useEffect, useCallback, useRef } from "react";
import { detect } from "./detect";
import { getPreferences } from "./preferences";
import { markConcealed, clearClipboard as nativeClear } from "./clipboard";

interface MonitorState {
  status: "idle" | "countdown" | "cleared";
  lastDetection: string | null;
  detectionCount: number;
  countdownEnd: number | null;
  detectedText: string | null;
}

const DEFAULT_STATE: MonitorState = {
  status: "idle",
  lastDetection: null,
  detectionCount: 0,
  countdownEnd: null,
  detectedText: null,
};

export default function Monitor() {
  const [state, setState] = useCachedState<MonitorState>("monitor-state", DEFAULT_STATE);
  const timerRef = useRef<NodeJS.Timeout | null>(null);

  const checkClipboard = useCallback(async () => {
    const prefs = getPreferences();
    const text = await Clipboard.readText();
    if (!text) return;

    const detections = detect(text, prefs.enabledPatterns);

    if (detections.length > 0 && state.detectedText !== text) {
      // Mark as concealed immediately so clipboard managers auto-expire it
      markConcealed(text);
      const countdownEnd = Date.now() + prefs.clearDelay * 1000;
      setState((prev) => ({
        ...prev,
        status: "countdown",
        lastDetection: detections[0].label,
        countdownEnd,
        detectedText: text,
      }));
    } else if (detections.length === 0 && state.status === "countdown") {
      // Clipboard changed to non-sensitive content — cancel countdown
      setState((prev) => ({
        ...prev,
        status: "idle",
        countdownEnd: null,
        detectedText: null,
      }));
    }
  }, [state.detectedText, state.status, setState]);

  const clearClipboard = useCallback(async () => {
    const prefs = getPreferences();
    const currentText = await Clipboard.readText();

    // Only clear if clipboard still contains the detected text
    if (currentText === state.detectedText) {
      nativeClear();
      setState((prev) => ({
        ...prev,
        status: "cleared",
        detectionCount: prev.detectionCount + 1,
        countdownEnd: null,
        detectedText: null,
      }));

      if (prefs.showNotification) {
        await showHUD("🛡 Sensitive data cleared from clipboard");
      }
    }
  }, [state.detectedText, setState]);

  // Poll clipboard on each background tick
  useEffect(() => {
    checkClipboard();
  }, [checkClipboard]);

  // Handle countdown timer
  useEffect(() => {
    if (state.status === "countdown" && state.countdownEnd) {
      const remaining = state.countdownEnd - Date.now();
      if (remaining <= 0) {
        clearClipboard();
      } else {
        timerRef.current = setTimeout(clearClipboard, remaining);
        return () => {
          if (timerRef.current) clearTimeout(timerRef.current);
        };
      }
    }
  }, [state.status, state.countdownEnd, clearClipboard]);

  const icon =
    state.status === "countdown"
      ? { source: Icon.Shield, tintColor: Color.Red }
      : { source: Icon.Shield, tintColor: Color.Green };

  // In background mode, don't render full menu
  if (environment.launchType === LaunchType.Background) {
    return <MenuBarExtra icon={icon} />;
  }

  const secondsLeft =
    state.status === "countdown" && state.countdownEnd
      ? Math.max(0, Math.ceil((state.countdownEnd - Date.now()) / 1000))
      : null;

  return (
    <MenuBarExtra icon={icon} tooltip="ClipShield — Clipboard Monitor">
      <MenuBarExtra.Section title="Status">
        {state.status === "countdown" && (
          <MenuBarExtra.Item
            icon={{ source: Icon.Clock, tintColor: Color.Red }}
            title={`${state.lastDetection} detected`}
            subtitle={`Clearing in ${secondsLeft}s`}
          />
        )}
        {state.status === "idle" && (
          <MenuBarExtra.Item icon={Icon.CheckCircle} title="Clipboard clean" />
        )}
        {state.status === "cleared" && (
          <MenuBarExtra.Item icon={Icon.CheckCircle} title="Last sensitive data was cleared" />
        )}
      </MenuBarExtra.Section>

      <MenuBarExtra.Section title="Stats">
        <MenuBarExtra.Item title={`Cleared: ${state.detectionCount} time(s)`} />
      </MenuBarExtra.Section>

      <MenuBarExtra.Section>
        <MenuBarExtra.Item
          title="Clear Now"
          icon={Icon.Trash}
          shortcut={{ modifiers: ["cmd"], key: "d" }}
          onAction={clearClipboard}
        />
        <MenuBarExtra.Item
          title="Reset Counter"
          icon={Icon.ArrowCounterClockwise}
          onAction={() => setState(DEFAULT_STATE)}
        />
      </MenuBarExtra.Section>
    </MenuBarExtra>
  );
}
