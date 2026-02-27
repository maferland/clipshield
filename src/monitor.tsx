import { Clipboard, Icon, MenuBarExtra, showHUD, Color, environment, LaunchType } from "@raycast/api";
import { useCachedState } from "@raycast/utils";
import { useEffect } from "react";
import { detect } from "./detect";
import { getPreferences } from "./preferences";
import { markConcealed, clearClipboard } from "./clipboard";

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

  // Runs on every background tick and on user-initiated launch
  useEffect(() => {
    (async () => {
      const prefs = getPreferences();
      const text = await Clipboard.readText();
      if (!text) return;

      const detections = detect(text, prefs.enabledPatterns);

      if (detections.length > 0 && state.detectedText !== text) {
        // New sensitive data detected — mark concealed and start countdown
        markConcealed(text);
        setState((prev) => ({
          ...prev,
          status: "countdown",
          lastDetection: detections[0].label,
          countdownEnd: Date.now() + prefs.clearDelay * 1000,
          detectedText: text,
        }));
      } else if (detections.length > 0 && state.status === "countdown" && state.countdownEnd) {
        // Still counting down — check if expired
        if (Date.now() >= state.countdownEnd) {
          clearClipboard();
          setState((prev) => ({
            ...prev,
            status: "cleared",
            detectionCount: prev.detectionCount + 1,
            countdownEnd: null,
            detectedText: null,
          }));
          if (prefs.showNotification) {
            await showHUD("Sensitive data cleared from clipboard");
          }
        }
      } else if (detections.length === 0 && state.status === "countdown") {
        // Clipboard changed to non-sensitive content — cancel
        setState((prev) => ({
          ...prev,
          status: "idle",
          countdownEnd: null,
          detectedText: null,
        }));
      }
    })();
  }, []);

  const handleClearNow = async () => {
    clearClipboard();
    setState((prev) => ({
      ...prev,
      status: "cleared",
      detectionCount: prev.detectionCount + 1,
      countdownEnd: null,
      detectedText: null,
    }));
    await showHUD("Sensitive data cleared from clipboard");
  };

  const icon =
    state.status === "countdown"
      ? { source: Icon.Shield, tintColor: Color.Red }
      : { source: Icon.Shield, tintColor: Color.Green };

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
          onAction={handleClearNow}
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
