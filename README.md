[README.md](https://github.com/user-attachments/files/35006761/README.md)
# EricMudkip ACX Rejoiner

Lightweight [AutoHotkey v2](https://www.autohotkey.com/v2/) background auto-rejoiner for Roblox that detects disconnect prompts (`Error Code: 769`) using built-in [Windows OCR](https://learn.microsoft.com/en-us/uwp/api/windows.media.ocr.ocrengine?view=winrt-28000) and a built-in replaceable reference image, then automatically rejoins your private server or game link via [Roblox Deep Links](https://create.roblox.com/docs/production/promotion/deeplinks).

## Features

* **Background Windows OCR Scanner:** Reads the Roblox window every 5 seconds in the background via the native [Windows.Media.Ocr.OcrEngine API](https://learn.microsoft.com/en-us/uwp/api/windows.media.ocr.ocrengine?view=winrt-28000) to detect `"Disconnected"`, `"Reconnect was unsuccessful"`, and `"Error Code: 769"` even while unfocused.
* **Built-in Image Replacer & Live Preview:** Pre-loaded with the default `Disconnected (Error Code: 769)` dialog image (`disconnected_ref.png` embedded directly inside the script) and includes GUI buttons to **Replace Image (Browse File...)**, **Capture Image from Roblox Window**, or **Restore Built-in Default Image** at any time.
* **Direct `roblox://` Protocol Launching:** Converts standard Roblox game URLs, legacy `privateServerLinkCode` links ([Roblox Deep Links Documentation](https://create.roblox.com/docs/production/promotion/deeplinks)), and newer `/share?code=` server links ([Roblox Private Server Share Links](https://devforum.roblox.com/t/private-server-help/3934961)) into direct `roblox://` protocol URIs so you do not accumulate browser tabs.
* **Persistent Settings:** Automatically saves your server URL, detection toggles, and ImageSearch variation tolerance (`0-255`) to `rejoin_settings.ini`.

## Prerequisites & Downloads

* **Windows 10 or Windows 11:** Required for the native [Windows.Media.Ocr.OcrEngine API](https://learn.microsoft.com/en-us/uwp/api/windows.media.ocr.ocrengine?view=winrt-28000) and Windows PowerShell 5.1.
* **AutoHotkey v2.0+:** Download and install from the [AutoHotkey v2 Official Website](https://www.autohotkey.com/v2/) or the [AutoHotkey v2 Microsoft Store Page](https://apps.microsoft.com/detail/9plqfdg8hh9d) (see the [AutoHotkey Installation Guide](https://www.autohotkey.com/docs/v2/howto/Install.htm)).
* **English Windows OCR Language Pack:** Included by default on English Windows installs; if missing, install it under **Settings > Time & Language > Language > Options > Download OCR** ([Windows OCR Setup Guide](https://techcommunity.microsoft.com/discussions/windowsinsiderprogram/look-for-a-safe-image-to-text-converter-for-extracting-text-from-pictures/4417442/replies/4513696)).
* **Roblox Desktop App:** Ensure `RobloxPlayerBeta.exe` is installed so `roblox://` deep links launch directly ([Roblox Deep Links Documentation](https://create.roblox.com/docs/production/promotion/deeplinks)).

## Setup & Usage Tutorial

1. **Extract the ZIP Archive:** Extract `EricMudkip ACX rejoiner.zip` to a folder on your PC.
2. **Install AutoHotkey v2:** Install [AutoHotkey v2](https://www.autohotkey.com/v2/) if you have not already.
3. **Run the Macro:** Double-click `EricMudkip_ACX_Rejoiner.ahk` to open the **EricMudkip ACX Rejoiner** window.
4. **Paste Your Server Link:** Paste your Private Server URL (`https://www.roblox.com/share?code=...&type=Server` or `privateServerLinkCode=...` per [Roblox Private Server Share Links](https://devforum.roblox.com/t/private-server-help/3934961)) or game link into **Private Server Link or Game URL** and click **Save Settings**.
5. **Customize Detection Image (Optional):** Use **Replace Image (Browse File...)** to pick any custom screenshot, **Capture Image from Roblox Window** to grab the current Roblox center prompt, or **Restore Built-in Default Image** to revert to the built-in `Disconnected` prompt.
6. **Test Your Rejoin Link:** Press `F2` (or click **Test Rejoin Now**) to verify that Roblox opens directly into your server via [Roblox Deep Links](https://create.roblox.com/docs/production/promotion/deeplinks).
7. **Start Monitoring:** Press `F1` (or click **Start Monitoring**) to begin background scanning.

## Hotkeys

| Hotkey | Action | Description |
| :--- | :--- | :--- |
| `F1` | Start / Stop Monitoring | Toggles background [Windows OCR](https://learn.microsoft.com/en-us/uwp/api/windows.media.ocr.ocrengine?view=winrt-28000) and `ImageSearch` monitoring on or off |
| `F2` | Test Rejoin Now | Immediately closes the disconnected client (if enabled) and launches your saved link via [Roblox Deep Links](https://create.roblox.com/docs/production/promotion/deeplinks) |
| `F3` | Show / Hide GUI | Hides or restores the **EricMudkip ACX Rejoiner** window while keeping monitoring active |
