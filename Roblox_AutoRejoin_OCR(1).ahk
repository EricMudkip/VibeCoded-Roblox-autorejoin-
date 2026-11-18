#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ==============================================================================
; Roblox Disconnected (Error Code: 769) Background OCR & Image Auto-Rejoin Macro
; ==============================================================================
; Reference Links:
; - Roblox Deep Links Documentation: https://create.roblox.com/docs/production/promotion/deeplinks
; - Roblox Share Link Protocol Format: https://devforum.roblox.com/t/private-server-help/3934961
; - Windows.Media.Ocr.OcrEngine API: https://learn.microsoft.com/en-us/uwp/api/windows.media.ocr.ocrengine?view=winrt-28000
;
; Features:
; 1. User GUI to input and save any Roblox Private Server Link, Share Link, or Game Link.
; 2. Completely silent background OCR scanner (using Windows 10/11 Windows.Media.Ocr)
;    that captures the Roblox window even when unfocused and detects:
;    "Disconnected", "Reconnect was unsuccessful", or "Error Code: 769".
; 3. Optional ImageSearch fallback if "disconnected_ref.png" is placed in the script folder.
; 4. Smart Deep-Link Resolver: converts standard web links and private server links into
;    direct `roblox://` client launch URIs so Roblox opens directly without browser tab buildup.
;
; Hotkeys:
;   F1 - Toggle Background Monitoring ON / OFF
;   F2 - Force Rejoin Immediately (Test Link)
;   F3 - Show / Hide Configuration Window
; ==============================================================================

global ConfigFile := A_ScriptDir "\rejoin_settings.ini"
global ReferenceImage := A_ScriptDir "\disconnected_ref.png"
global TempCapturePath := A_Temp "\roblox_ocr_capture.png"
global TempTextPath := A_Temp "\roblox_ocr_result.txt"
global OcrScriptPath := A_Temp "\roblox_win_ocr.ps1"

global IsMonitoring := false
global LastRejoinTick := 0
global CheckIntervalMs := 5000       ; Check every 5 seconds
global RejoinCooldownMs := 45000     ; Wait 45 seconds after launching before re-triggering
global TargetWindow := "ahk_exe RobloxPlayerBeta.exe"

; Load saved settings
SavedLink := IniRead(ConfigFile, "Settings", "ServerLink", "")
SavedDirectProtocol := IniRead(ConfigFile, "Settings", "UseDirectProtocol", "1")
SavedCloseBeforeRejoin := IniRead(ConfigFile, "Settings", "CloseRobloxFirst", "1")
SavedClickReconnectFallback := IniRead(ConfigFile, "Settings", "ClickReconnectIfNoLink", "0")

; Create the helper PowerShell OCR script once on startup
InitOcrHelperScript()

; ==============================================================================
; GUI Construction
; ==============================================================================
MainGui := Gui("+AlwaysOnTop", "Roblox Auto-Rejoin (OCR + Image Detection)")
MainGui.SetFont("s9", "Segoe UI")

MainGui.Add("Text", "x16 y14 w460", "Private Server Link or Game URL:")
LinkInput := MainGui.Add("Edit", "x16 y34 w460 h24 vServerLink", SavedLink)

ChkDirect := MainGui.Add("CheckBox", "x16 y68 w460 Checked" SavedDirectProtocol, "Launch directly via roblox:// protocol (faster, avoids extra browser tabs)")
ChkCloseFirst := MainGui.Add("CheckBox", "x16 y92 w460 Checked" SavedCloseBeforeRejoin, "Close disconnected Roblox client before rejoining via link")
ChkReconnectBtn := MainGui.Add("CheckBox", "x16 y116 w460 Checked" SavedClickReconnectFallback, "Click in-game 'Reconnect' button instead if Server Link is left blank")

MainGui.Add("Text", "x16 y148 w460", "Status:")
StatusText := MainGui.Add("Text", "x65 y148 w410 cRed", "Idle (Press F1 or click Start Monitoring)")

LastOcrText := MainGui.Add("Text", "x16 y172 w460 h36 cGray", "Last OCR Scan: None")

BtnToggle := MainGui.Add("Button", "x16 y216 w145 h32", "Start Monitoring (F1)")
BtnTest := MainGui.Add("Button", "x173 y216 w145 h32", "Test Rejoin Now (F2)")
BtnSave := MainGui.Add("Button", "x330 y216 w146 h32", "Save Settings")

BtnToggle.OnEvent("Click", (*) => ToggleMonitoring())
BtnTest.OnEvent("Click", (*) => TriggerRejoin("Manual Test"))
BtnSave.OnEvent("Click", (*) => SaveConfiguration(true))

MainGui.Show("w492 h264")

; ==============================================================================
; Hotkeys
; ==============================================================================
F1::ToggleMonitoring()
F2::TriggerRejoin("Hotkey F2")
F3::
{
    if WinExist("ahk_id " MainGui.Hwnd) && DllCall("IsWindowVisible", "Ptr", MainGui.Hwnd)
        MainGui.Hide()
    else
        MainGui.Show()
}

; ==============================================================================
; Core Functions
; ==============================================================================
SaveConfiguration(ShowMsg := false) {
    global ConfigFile, LinkInput, ChkDirect, ChkCloseFirst, ChkReconnectBtn
    IniWrite(Trim(LinkInput.Value), ConfigFile, "Settings", "ServerLink")
    IniWrite(ChkDirect.Value, ConfigFile, "Settings", "UseDirectProtocol")
    IniWrite(ChkCloseFirst.Value, ConfigFile, "Settings", "CloseRobloxFirst")
    IniWrite(ChkReconnectBtn.Value, ConfigFile, "Settings", "ClickReconnectIfNoLink")
    if ShowMsg
        TrayTip("Settings saved to rejoin_settings.ini", "Roblox Auto-Rejoin", 1)
}

ToggleMonitoring() {
    global IsMonitoring, CheckIntervalMs, StatusText, BtnToggle
    SaveConfiguration(false)
    IsMonitoring := !IsMonitoring
    if IsMonitoring {
        StatusText.Value := "Monitoring Roblox in background..."
        StatusText.Opt("cGreen")
        BtnToggle.Text := "Stop Monitoring (F1)"
        SetTimer(MonitorRobloxRoutine, CheckIntervalMs)
        MonitorRobloxRoutine()
    } else {
        StatusText.Value := "Paused (Press F1 to resume)"
        StatusText.Opt("cRed")
        BtnToggle.Text := "Start Monitoring (F1)"
        SetTimer(MonitorRobloxRoutine, 0)
    }
}

MonitorRobloxRoutine() {
    global IsMonitoring, LastRejoinTick, RejoinCooldownMs, TargetWindow, ReferenceImage, LastOcrText
    if !IsMonitoring
        return

    ; Respect cooldown window while Roblox is loading into the server
    if (LastRejoinTick > 0 && (A_TickCount - LastRejoinTick < RejoinCooldownMs)) {
        RemainingSec := Round((RejoinCooldownMs - (A_TickCount - LastRejoinTick)) / 1000)
        LastOcrText.Value := "Cooldown active (" RemainingSec "s remaining while Roblox loads)..."
        return
    }

    Hwnd := WinExist(TargetWindow)
    if !Hwnd {
        LastOcrText.Value := "Roblox window not detected."
        return
    }

    ; 1. Optional ImageSearch fallback if user placed disconnected_ref.png in script directory
    if FileExist(ReferenceImage) && WinActive("ahk_id " Hwnd) {
        CoordMode("Pixel", "Window")
        WinGetPos(&WX, &WY, &WW, &WH, "ahk_id " Hwnd)
        try {
            if ImageSearch(&FoundX, &FoundY, 0, 0, WW, WH, "*50 " ReferenceImage) {
                LastOcrText.Value := "Detected disconnect prompt via ImageSearch!"
                TriggerRejoin("ImageSearch Match")
                return
            }
        }
    }

    ; 2. Background Windows OCR scan of the Roblox window (works even if Roblox is behind other windows)
    OcrText := CaptureAndOcrWindow(Hwnd)
    CleanPreview := RegExReplace(OcrText, "[\r\n]+", " ")
    if (StrLen(CleanPreview) > 95)
        CleanPreview := SubStr(CleanPreview, 1, 95) "..."
    LastOcrText.Value := "Last OCR: " (CleanPreview != "" ? CleanPreview : "(No text read)")

    ; Match the disconnect overlay from the screenshot:
    ; "Disconnected", "Reconnect was unsuccessful. Please try again. (Error Code: 769)"
    if RegExMatch(OcrText, "i)(Disconnected|Reconnect\s+was\s+unsuccessful|Error\s*Code\s*:\s*769|Error\s*Code\s*:\s*\d+)") {
        TriggerRejoin("OCR Detected Disconnect Overlay")
    }
}

TriggerRejoin(Reason := "Detected") {
    global LastRejoinTick, LinkInput, ChkDirect, ChkCloseFirst, ChkReconnectBtn, TargetWindow, StatusText
    SaveConfiguration(false)
    ServerUrl := Trim(LinkInput.Value)

    if (ServerUrl = "") {
        if ChkReconnectBtn.Value && WinExist(TargetWindow) {
            StatusText.Value := "Clicking in-game Reconnect button (" Reason ")"
            ClickInGameReconnectButton(WinExist(TargetWindow))
            LastRejoinTick := A_TickCount
        } else {
            StatusText.Value := "Please enter a Private Server / Game Link first!"
            StatusText.Opt("cRed")
        }
        return
    }

    LastRejoinTick := A_TickCount
    StatusText.Value := "Rejoining server (" Reason ")..."
    StatusText.Opt("cBlue")

    ; Optionally close the stuck/disconnected Roblox client first
    if ChkCloseFirst.Value && WinExist(TargetWindow) {
        WinClose(TargetWindow)
        if !WinWaitClose(TargetWindow, "", 4) {
            try ProcessClose("RobloxPlayerBeta.exe")
        }
        Sleep(1000)
    }

    LaunchTarget := ChkDirect.Value ? BuildRobloxLaunchTarget(ServerUrl) : ServerUrl
    try {
        Run(LaunchTarget)
    } catch {
        ; Fallback to raw URL in default browser if protocol launch fails
        Run(ServerUrl)
    }
}

BuildRobloxLaunchTarget(RawLink) {
    ; 1. If already a roblox:// protocol URI, return as-is
    if RegExMatch(RawLink, "i)^roblox://")
        return RawLink

    ; 2. Newer Roblox Private Server Share Link format:
    ;    https://www.roblox.com/share?code=<32-char-hex>&type=Server
    if RegExMatch(RawLink, "i)roblox\.com/share\?.*?code=([a-f0-9]+)", &Match) {
        return "roblox://navigation/share_links?code=" Match[1] "&type=Server"
    }

    ; 3. Classic Roblox Private Server Link format:
    ;    https://www.roblox.com/games/<PlaceId>/...?privateServerLinkCode=<LinkCode>
    if RegExMatch(RawLink, "i)roblox\.com/games/(\d+).*?privateServerLinkCode=([A-Za-z0-9_-]+)", &Match) {
        return "roblox://placeId=" Match[1] "&linkCode=" Match[2]
    }

    ; 4. Standard Roblox Game URL:
    ;    https://www.roblox.com/games/<PlaceId>/...
    if RegExMatch(RawLink, "i)roblox\.com/games/(\d+)", &Match) {
        return "roblox://placeId=" Match[1]
    }

    ; 5. Fallback to opening the user-supplied URL in the default browser
    return RawLink
}

ClickInGameReconnectButton(Hwnd) {
    ; In the Roblox disconnect modal, the "Reconnect" button sits on the bottom-right
    ; of the centered dark dialog box (approx 56% X, 57% Y of the client area).
    WinGetClientPos(&CX, &CY, &CW, &CH, "ahk_id " Hwnd)
    if (CW > 0 && CH > 0) {
        TargetX := Round(CW * 0.56)
        TargetY := Round(CH * 0.57)
        PostMessage(0x0200, 0, (TargetY << 16) | (TargetX & 0xFFFF), , "ahk_id " Hwnd) ; WM_MOUSEMOVE
        Sleep(50)
        ControlClick("x" TargetX " y" TargetY, "ahk_id " Hwnd, , "Left", 1, "NA")
    }
}

CaptureAndOcrWindow(Hwnd) {
    global OcrScriptPath, TempCapturePath, TempTextPath
    try FileDelete(TempTextPath)
    Cmd := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' OcrScriptPath '" -Hwnd ' Hwnd ' -OutPath "' TempCapturePath '" -TextOut "' TempTextPath '"'
    try {
        RunWait(Cmd, , "Hide")
        if FileExist(TempTextPath)
            return Trim(FileRead(TempTextPath, "UTF-8"))
    }
    return ""
}

InitOcrHelperScript() {
    global OcrScriptPath
    Lines := [
        'param([Int64]$Hwnd, [string]$OutPath, [string]$TextOut)',
        '$ErrorActionPreference = "SilentlyContinue"',
        'Add-Type -AssemblyName System.Drawing',
        '$cs = "using System; using System.Runtime.InteropServices; public class Win32Cap { [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; } [DllImport(\"user32.dll\")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect); [DllImport(\"user32.dll\")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags); [DllImport(\"user32.dll\")] public static extern bool IsIconic(IntPtr hWnd); }"',
        'Add-Type -TypeDefinition $cs',
        '$ptr = [IntPtr]$Hwnd',
        'if ([Win32Cap]::IsIconic($ptr)) { exit 0 }',
        '$rect = New-Object Win32Cap+RECT',
        'if (-not [Win32Cap]::GetWindowRect($ptr, [ref]$rect)) { exit 0 }',
        '$w = $rect.Right - $rect.Left',
        '$h = $rect.Bottom - $rect.Top',
        'if ($w -le 100 -or $h -le 100) { exit 0 }',
        '$bmp = New-Object System.Drawing.Bitmap($w, $h)',
        '$g = [System.Drawing.Graphics]::FromImage($bmp)',
        '$hdc = $g.GetHdc()',
        '$printed = [Win32Cap]::PrintWindow($ptr, $hdc, 2)',
        '$g.ReleaseHdc($hdc)',
        'if (-not $printed) { $g.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bmp.Size) }',
        '$g.Dispose()',
        '$cropX = [int]($w * 0.20)',
        '$cropY = [int]($h * 0.20)',
        '$cropW = [int]($w * 0.60)',
        '$cropH = [int]($h * 0.60)',
        '$cropRect = New-Object System.Drawing.Rectangle($cropX, $cropY, $cropW, $cropH)',
        '$cropped = $bmp.Clone($cropRect, $bmp.PixelFormat)',
        '$bmp.Dispose()',
        '$cropped.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)',
        '$cropped.Dispose()',
        '$null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]',
        '$null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Foundation, ContentType = WindowsRuntime]',
        '$null = [Windows.Storage.StorageFile, Windows.Foundation, ContentType = WindowsRuntime]',
        'Add-Type -AssemblyName System.Runtime.WindowsRuntime',
        '$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq "AsTask" -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name.StartsWith("IAsyncOperation") })[0]',
        'Function Await($WinRtTask, $ResultType) {',
        '    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)',
        '    $netTask = $asTask.Invoke($null, @($WinRtTask))',
        '    $netTask.Wait(-1) | Out-Null',
        '    return $netTask.Result',
        '}',
        '$storageFile = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($OutPath)) ([Windows.Storage.StorageFile])',
        '$stream = Await ($storageFile.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])',
        '$decoder = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])',
        '$softwareBitmap = Await ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])',
        '$ocrEngine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()',
        'if ($null -eq $ocrEngine) {',
        '    $lang = New-Object Windows.Globalization.Language("en-US")',
        '    $ocrEngine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($lang)',
        '}',
        '$ocrResult = Await ($ocrEngine.RecognizeAsync($softwareBitmap)) ([Windows.Media.Ocr.OcrResult])',
        '$stream.Dispose()',
        '[System.IO.File]::WriteAllText($TextOut, $ocrResult.Text, [System.Text.Encoding]::UTF8)'
    ]

    PsCode := ""
    for _, Line in Lines
        PsCode .= Line "`r`n"

    try FileDelete(OcrScriptPath)
    FileAppend(PsCode, OcrScriptPath, "UTF-8")
}
