# Chrome AI Cleaner

Batch script (`removeChromeAi.bat`) to disable built-in AI features in Google Chrome on Windows (Gemini, AI Mode, local on-device AI model).

## What the script does

1. **Closes Chrome** if it is running.
2. **Backs up existing Chrome registry policies** (if any) to `%USERPROFILE%\Desktop\Chrome_AI_Backup`, before making any changes.
3. **Sets Chrome enterprise policies** that permanently disable AI features:
- `GenAILocalFoundationalModelSettings = 1` - disables local (on-device) AI model
- `GeminiSettings = 1` - disables Gemini integration
- `AIModeSettings = 1` - disables AI Mode in browsing
4. **Finds and deletes existing locally downloaded AI model files** (e.g. `weights.bin` in `OptGuideOnDeviceModel`, `OnDeviceModel`, `OptimizationGuide` folders) within the Chrome profile, to immediately free up disk space.
5. **Does not touch** bookmarks, passwords, history or extensions.
6. Finally, prints the current state of the set policies for verification.

## Important disk note

After deleting, Chrome may **re-download** the AI ​​model files in the background (via the internal "Component Updater" mechanism) the next time it is started. This is normal and **not a problem** - even though the file is back on disk (usually a few hundred MB), the AI ​​functions remain inactive due to the policies set in step 3. The script can be re-run at any time to delete the file again, if it bothers you.

## How to use

1. Download `removeChromeAi.bat`.
2. Run it by double-clicking it (the script itself asks for Administrator rights and offers a UAC prompt - click **Yes**).
3. Follow the on-screen instructions, pressing any key when prompted.
4. Once finished, open Chrome and go to `chrome://policy`, then click **Reload policies** to apply the changes immediately.
5. Check that `GenAILocalFoundationalModelSettings` is set to `1`.

## Requirements

- Windows with Google Chrome installed
- Administrator rights (the script requires them)

## Security

The script only modifies the Windows registry under `HKLM\SOFTWARE\Policies\Google\Chrome` (the standard Chrome enterprise policy location) and deletes only the AI ​​model files within the recognized AI folders in the Chrome profile. It does not touch other parts of the system. Registry backups are automatically saved before any changes are made, so changes can be manually restored by importing `.reg` files from the backup folder if necessary.