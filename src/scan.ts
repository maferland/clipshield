import { Clipboard, showHUD } from "@raycast/api";
import { detect } from "./detect";
import { getPreferences } from "./preferences";
import { clearClipboard } from "./clipboard";

export default async function Scan() {
  const prefs = getPreferences();
  const text = await Clipboard.readText();

  if (!text) {
    await showHUD("Clipboard is empty");
    return;
  }

  const detections = detect(text, prefs.enabledPatterns);

  if (detections.length === 0) {
    await showHUD("Clipboard is clean");
    return;
  }

  const labels = [...new Set(detections.map((d) => d.label))].join(", ");
  clearClipboard();
  await showHUD(`Cleared ${labels} from clipboard`);
}
