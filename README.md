----------

NOTE - This is a hobby project created primarily for my personal needs. 

----------


# Chrome AI Cleaner

Batch script (`removeChromeAiWin.bat`) that disables the built-in AI features in Google Chrome on Windows (Gemini, AI Mode, local on-device AI model) and deletes the already downloaded local model files.

## What the script does

1. **Requests Administrator rights** (UAC prompt) and re-launches itself elevated if needed.
2. **Closes Chrome** if it is running (`taskkill`, unsaved form data in open tabs can be lost).
3. **Backs up existing Chrome policies** from the registry (`HKLM` and `HKCU`, only if they exist) to `%USERPROFILE%\Desktop\Chrome_AI_Backup`. An existing backup is **never overwritten**, so re-running the script cannot replace your original settings with the modified ones.
4. **Sets Chrome policies** under `HKLM\SOFTWARE\Policies\Google\Chrome`:
   - `GenAILocalFoundationalModelSettings = 1` - disables the local (on-device) AI model
   - `GeminiSettings = 1` - disables Gemini integration
   - `AIModeSettings = 1` - disables AI Mode in search
5. **Finds and deletes local AI model folders** anywhere inside `%LOCALAPPDATA%\Google\Chrome\User Data`:
   - `OptGuideOnDeviceModel`
   - `OnDeviceModel`
   - any leftover `weights.bin` located inside one of those folders
6. **Verifies** the policies by querying the registry.

Bookmarks, passwords, history and extensions are not touched.

## Notes

- **Disk space:** Chrome may re-download the model in the background the next time it starts. With the policies set the AI features stay inactive, so this is harmless; re-run the script to remove the file again.
- **"Managed by your organization":** because the policies are set via the registry, Chrome will show this notice in the menu and in `chrome://settings`. This is expected.
- Only stable **Google Chrome** is handled (not Chrome Beta/Dev/Canary, Chromium or Edge).
- Policies are set in `HKLM`, so they apply to all users on the machine.

## How to use

1. Download `removeChromeAiWin.bat`.
2. Double-click it (or right-click -> *Run as administrator*). Click **Yes** on the UAC prompt.
3. Follow the on-screen instructions and press a key when prompted.
4. Start Chrome, open `chrome://policy` and click **Reload policies**.
5. Verify that `GenAILocalFoundationalModelSettings`, `GeminiSettings` and `AIModeSettings` are all set to `1`.

## Reverting

Delete the three values from `HKLM\SOFTWARE\Policies\Google\Chrome` (or the whole key if it did not exist before), or import the `.reg` files from `Desktop\Chrome_AI_Backup` if you had policies before. Note that a `.reg` import only adds/overwrites values, it does not delete the three values added by this script.

## Requirements

- Windows with Google Chrome installed
- Administrator rights (requested automatically)

## Safety

The script only writes to `HKLM\SOFTWARE\Policies\Google\Chrome` and only deletes folders named `OptGuideOnDeviceModel` / `OnDeviceModel` (and `weights.bin` inside them) within Chrome's `User Data` directory. Nothing else on the system is modified.
