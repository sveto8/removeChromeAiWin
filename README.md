# Chrome AI Cleaner

Batch script (`removeChromeAi.bat`) to disable built‑in AI features in Google Chrome on Windows (Gemini, AI Mode, local on‑device AI model).

## What the script does

1. **Closes Chrome** if it is running.
2. **Backs up existing Chrome registry policies** (if any) to `%USERPROFILE%\Desktop\Chrome_AI_Backup` before changing anything.
3. **Sets Chrome enterprise policies** that permanently disable AI features:
   - `GenAILocalFoundationalModelSettings = 1` – disables the local (on‑device) AI model
   - `GeminiSettings = 1` – disables Gemini integration
   - `AIModeSettings = 1` – disables AI Mode in search
4. **Finds and deletes any existing locally downloaded AI model files** (e.g. `weights.bin` inside `OptGuideOnDeviceModel`, `OnDeviceModel`, `OptimizationGuide` folders) within Chrome profiles, to free up disk space immediately.
5. **Does not touch** bookmarks, passwords, history, or extensions.
6. At the end, it displays the current state of the set policies for verification.

## Important note about disk space

After deletion, Chrome **may re‑download** the AI model files in the background (via the internal "Component Updater" mechanism) the next time it starts. This is normal and **not a problem** – even though the file reappears on disk (usually a few hundred MB), the AI features remain inactive because of the policies set in step 3. You can re‑run the script at any time to delete that file again if it bothers you.

## How to use

1. Download `removeChromeAi.bat`.
2. Double‑click to run it (the script will request Administrator privileges and show a UAC prompt – click **Yes**).
3. Follow the on‑screen instructions, press any key when prompted.
4. After completion, open Chrome and go to `chrome://policy`, then click **Reload policies** to apply the changes immediately.
5. Verify that `GenAILocalFoundationalModelSettings` is set to `1`.

## Requirements

- Windows with Google Chrome installed
- Administrator rights (the script requests them automatically)

## Safety

The script only modifies the Windows registry under `HKLM\SOFTWARE\Policies\Google\Chrome` (the standard Chrome enterprise policy location) and deletes only AI model files inside recognised AI folders within the Chrome profile. It does not touch other parts of the system. A registry backup is automatically saved before any changes, so changes can be manually reverted by importing the `.reg` files from the backup folder if needed.
