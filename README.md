# Windows notification fixes

Compact Windows desktop notifications that appear together, keep their own 60-second display time, and can make Outlook calendar reminders audible while Outlook is closed.

This is a GPL-3.0 fork of [Wheatlay's Compact Notifications 1.2](https://github.com/ramensoftware/windhawk-mods/blob/06bb6df5b1aebfa91ab73c3e16ec5c616d71d794/mods/compact-notifications.wh.cpp), running inside [Windhawk](https://windhawk.net/). Package version **0.1.0** contains mod version **1.2.5**. The package and upstream-derived mod have separate version numbers.

## What it changes

- Displays new cards alongside older cards, newest first; an older banner no longer holds up the next one.
- Accepts the legacy Windows `QUNS_BUSY` state when actual Do Not Disturb and the existing per-app checks allow notifications.
- Optionally supplies a calendar ding for silent Outlook event reminders only while Outlook is closed. Running Outlook supplies its own configured reminder sound.
- Reads the sender again when Windows reuses a notification control, preventing a phone message from inheriting an earlier Outlook label.
- Resolves Phone Link's per-device Messages identifiers to **Phone Link**, even when Windows' AppsFolder lookup returns no name.
- Includes a yellow/dark-text profile, app names, and a 60-second Windows display duration. Colors apply across apps; they do not identify the sender.

It displays notifications already submitted to Windows. It cannot repair upstream calendar synchronization or make Outlook honor several Google Calendar reminder times on one event.

## Install Windhawk

Use **Windows 11 x64** and standard installation mode. The packaged binary was built with **Windhawk 1.7.3**; ARM64 and portable mode are not covered by the installer.

1. Download the [official Windhawk 1.7.3 installer](https://github.com/ramensoftware/windhawk/releases/download/v1.7.3/windhawk_setup.exe), or install it using Windows Package Manager:

   ```powershell
   winget install --exact --id RamenSoftware.Windhawk --version 1.7.3 --source winget
   ```

2. Run the installer and select the standard installation. Windows will ask for administrator approval.
3. Open Windhawk once so it initializes its profile and automatic service.

The installer is from [Windhawk's official release](https://github.com/ramensoftware/windhawk/releases/tag/v1.7.3). Its SHA-256 is `5116cc1703384aac88b8d7a3b57f172aea5da32b6df7355fb2f8247d23813c8f`. A release-specific offline installer is also available there. Do not downgrade an existing newer Windhawk installation just to use this package; compile the source in its editor instead and validate compatibility.

## Install the mod

Download `windows-notification-fixes-v0.1.0.zip` from [Releases](https://github.com/brycelelbach/windows-notification-fixes/releases). Extract it. Open **64-bit PowerShell as administrator**, change to the extracted directory, and run:

```powershell
Unblock-File .\scripts\install.ps1
Unblock-File .\scripts\restore.ps1
.\scripts\install.ps1 -WhatIf
.\scripts\install.ps1
```

If local PowerShell policy blocks the reviewed script, use a process-only invocation:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

The installer verifies release file hashes, backs up this mod's previous settings/source, disables the original catalog mod if present, installs the local mod, and checks it loaded. It uses `local@compact-notifications-background`, so catalog updates cannot silently replace the local changes. Existing customization settings are preserved on upgrade. A fresh installation uses the yellow, dark-text, top-right profile with app names and up to ten cards.

The Windows calendar sound is copied locally to `%ProgramData%\WindowsNotificationFixes\calendar-ding.wav`. No Microsoft sound file is distributed in this repository. The installer sets the current user's banner duration to 60 seconds. Run elevation as the intended signed-in user; using another administrator's account would configure that account instead.

The result and backup location are saved in `%ProgramData%\WindowsNotificationFixes\last-install.json`. Keep the backup for rollback. You can delete the downloaded ZIP and extracted package after installation; the runtime no longer depends on that directory.

### Install from source through Windhawk

1. Disable any other Compact Notifications version in Windhawk.
2. In Windhawk, click **Create Mod**.
3. Replace the template with the complete `dist/compact-notifications.wh.cpp` from the release ZIP. This is self-contained; the modular `src/` file alone is insufficient.
4. Click **Compile Mod**, then enable it.
5. Open the mod's settings. Set **Avatars → app's name** on, **Sound → when a card shows**, and **Ding for Outlook calendar reminders while Outlook is closed** on. Choose `%WINDIR%\Media\Windows Notify Calendar.wav` using the resolved Windows folder path for your machine.
6. For the supplied appearance, use Light theme, background `#FFE066`, text `#1B1B1B`, width 420, three body lines, primary monitor, top right, and ten cards.
7. In Windows **Settings → Accessibility → Visual effects**, set **Dismiss notifications after this amount of time** to **1 minute**.

Windhawk may choose a different local ID in the editor. The scripted installer and restore instructions manage the exact ID above; use Windhawk's own disable/remove controls for a manually created mod under another ID.

## Configure Outlook too

See [Outlook and Windows settings](docs/outlook-and-windows.md). The mod's sound fallback does not register calendars or configure Outlook accounts. Each account needs Desktop reminders and working closed-app notification registration. Set Outlook's reminder sound as well so it dings when running. This fork does not add multiple reminders to an Outlook event.

## Build and test

Install Windhawk 1.7.3 and Node.js 22. Then run from a checkout:

```powershell
node .\scripts\build.cjs
```

`WINDHAWK_ROOT` can point to a non-default standard Windhawk installation. The script uses Windhawk's bundled clang/compiler headers and versioned engine import library, runs both regression suites, compiles the self-contained mod, and writes `dist/manifest.json` with SHA-256 hashes. The build does not change your installed mod.

`scripts/package.ps1` creates the release ZIP and its checksum. CI builds and tests on Windows using the pinned official installer. Source correspondence and repeatable builds are provided; bit-for-bit reproducibility across different compiler bundles is not claimed.

## Disable, uninstall, or roll back

For immediate rollback to native Windows banners, disable **Compact Notifications (background fix)** in Windhawk. Leave the catalog Compact Notifications version disabled unless you specifically want it instead. Disabling does not reset the 60-second setting.

To restore the configuration captured before installation, run the following as the same user with administrator rights:

```powershell
$receipt = Get-Content "$env:ProgramData\WindowsNotificationFixes\last-install.json" -Raw | ConvertFrom-Json
& (Join-Path $receipt.backup 'restore.ps1') -BackupPath $receipt.backup
```

For a fresh install this removes the local mod registration; for an upgrade it restores the previous version, settings, source, sound, and prior Windows duration. Other mods are preserved. Unused versioned DLLs and backup files are deliberately retained. Once no mod uses them, they can be deleted manually. To remove Windhawk itself, use Windows **Installed apps → Windhawk → Uninstall**.

## Verification and limits

See [verification](docs/verification.md) for the test procedure and exact tested states. Earlier real work/personal reminders were seen and heard with Outlook closed and in the background. The label correction has automated regression coverage; its live desktop status is recorded separately. Do not interpret an app restart as a Windows reboot or sleep/wake test.

Cards can last slightly longer than 60 seconds because of animation; hovering pauses expiration. Priority reminders/alarms/calls can persist until handled. At most ten normal cards are shown; older cards remain in Notification Center. The mod reads Windows' local notification database and uses Windows accessibility controls for notification actions. This repository contains no calendar data, account settings, private notification logs, or screenshots.

## Attribution

See [NOTICE](NOTICE) and [LICENSE](LICENSE). The fork retains Wheatlay's GPL-3.0 code and credits for notification detection from nikitor32 and m417z. It cannot be relicensed under the Apache license used by unrelated Windows helper projects.
