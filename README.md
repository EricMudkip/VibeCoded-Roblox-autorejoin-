# EricMudkip ACX Rejoiner

Lightweight [AutoHotkey v2](https://www.autohotkey.com/v2/) background auto-rejoiner and anti-AFK auto-clicker for Roblox that detects disconnect prompts (`Error Code: 769`) using built-in [Windows OCR](https://learn.microsoft.com/en-us/uwp/api/windows.media.ocr.ocrengine?view=winrt-28000) and a built-in replaceable reference image, then automatically rejoins your private server or game link via [Roblox Deep Links](https://create.roblox.com/docs/production/promotion/deeplinks).

## Features

* **Built-In Auto-Clicker (Minutes, Seconds & Set Coordinates):** Configure click intervals in **minutes** and **seconds**, optionally lock clicks to a custom **X / Y position** (with a one-click **Pick Position** button), and choose between **background Roblox window clicks** (keeps your mouse free) or **standard screen clicks**.
* **Background Windows OCR Scanner:** Reads the Roblox window every 5 seconds in the background via the native [Windows.Media.Ocr.OcrEngine API](https://learn.microsoft.com/en-us/uwp/api/windows.media.ocr.ocrengine?view=winrt-28000) to detect `"Disconnected"`, `"Reconnect was unsuccessful"`, and `"Error Code: 769"` even while unfocused.
* **Auto-Close Newly Opened Browser Windows (RAM Saver):** Snapshots existing browser windows before launching a link and automatically closes any newly spawned browser window once Roblox opens.
* **Built-in Image Replacer & Live Preview:** Pre-loaded with the default `Disconnected (Error Code: 769)` dialog image (`disconnected_ref.png` embedded cleanly inside the script).
* **Persistent Settings:** Saves your server link, auto-clicker intervals/coordinates, browser cleanup toggle, and OCR settings to `rejoin_settings.ini`.

## Hotkeys

| Hotkey | Action | Description |
| :--- | :--- | :--- |
| `F1` | Start / Stop Monitoring | Toggles background Windows OCR and `ImageSearch` monitoring on or off |
| `F2` | Test Rejoin Now | Immediately closes the disconnected client (if enabled) and launches your saved link |
| `F3` | Show / Hide GUI | Hides or restores the **EricMudkip ACX Rejoiner** window while keeping monitoring/clicking active |
| `F4` | Start / Stop Auto-Clicker | Toggles the interval auto-clicker on or off |
