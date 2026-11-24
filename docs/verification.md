# Verification

## Automated checks

`scripts/build.cjs` runs nine reminder-classification checks, fifteen notification-identity checks, and thirteen notification-lifetime checks before compiling the full mod. The reminder tests reject mail, other applications, and misleading query substrings. Process detection reports whether Outlook is running without requiring a particular desktop state. Lifetime tests cover delayed native queue delivery, expired cards retained beyond two minutes, original-arrival deadlines, removed records, unknown arrivals, and backward clock changes.

The identity regression models a Windows UIA control reused first for Outlook and then for Messages. The previous code retained the cached Outlook app name when the message changed. The fixed code rereads the current sender, includes it in cache reuse decisions, prefers a matched stored toast's source, and updates existing card text when metadata changes. Identical content from another app and temporarily missing sender data are covered.

## Observed desktop results before packaging

- Two real calendar reminders 20 seconds apart appeared together, newest first, while older notifications remained visible.
- Independent expiration passed while Windows MessageDuration stayed 60; observed card lifetime was roughly 62.5 seconds including animation allowance.
- Work and personal reminders both arrived with Outlook closed. The final audible pair arrived about 6.7 seconds after their target seconds, and the user confirmed both dings.
- A further work/personal pair arrived with Outlook running in the background within 0.1 second of the target seconds; the user confirmed one ding per reminder.
- Outlook restart and Windhawk renderer/service reload were tested. Those tests do **not** establish Windows reboot or physical sleep/wake behavior for this version.

## App-label report

A user reported a text notification labeled Outlook. The underlying Windows record identified Phone Link, but that does not prove the custom card's displayed label. Source inspection found a stale-app-name path when a UIA runtime ID was reused. This is a confirmed code defect and a plausible explanation of the reported card; no historical screenshot of that exact card was captured. The correction is included in this release. Automated regression coverage alone is not a claim that the historical display was directly reproduced.

The first local desktop test showed Outlook labeled correctly, but a Phone Link test had no app-name prefix because its per-device application ID returned no AppsFolder name. The corrected lookup resolves the exact Phone Link package family explicitly, including its per-device message IDs. This is a separate correction from the cached-sender defect.

The raw UIA sender is stored separately from the canonical display name. This preserves stable cache identity when Windows calls the source Messages and the card calls it Phone Link; it also avoids recreating an unchanged card when the raw sender is unavailable.

## Sender-label desktop check

On November 24, 2026, the packaged installer loaded the corrected mod into both Explorer and ShellExperienceHost, preserved the 60-second duration, and moved the ding file to the stable ProgramData directory. At approximately 15:29 Eastern, disposable local Windows toasts were posted under the installed Outlook and Phone Link notification channels; no email or text message was sent.

The actual desktop cards visibly read **Outlook · Local label check A** and then **Phone Link · Local label check B**, over a different foreground app. The Outlook test was withdrawn before the Phone Link test. Both tagged test alerts were then removed. This confirms the displayed labels in this controlled sequence; the historical reused-control report is additionally covered by the regression test, not a captured historical screenshot.

The sender-label build passed 24 checks on GitHub. Its self-contained source and DLL SHA-256 values matched the local installed build byte for byte. Installer upgrade and restore dry-run passed; a separate clean-machine installation, OS reboot, and physical sleep/wake were not performed during this packaging session.

## Delayed native-banner replay

On November 24, a four-toast local burst initially displayed correctly, newest first, and expired after the configured 60 seconds. Approximately three minutes after its original delivery, the fourth card visibly reappeared. Its Windows record retained the original arrival timestamp, with no new submission. This reproduced a failure that a short initial-display test missed.

The worker forgot expired cards after two minutes, while Windows' native banner queue could take longer to reach them. A late native banner was consequently treated as new. The correction retains suppression while the stored notification exists, does not consume that suppression on a first match, and limits native fallback cards to the remaining time from their original arrival.

The corrected build was installed and reloaded into Explorer and ShellExperienceHost. In the traced repeat, four local Slack-channel toasts appeared together over another foreground app, 0.04–0.33 seconds after Windows receipt. Clicking the newest card and then the next card dismissed exactly those two cards; trace arrival IDs and visible remaining cards agreed. The two untouched cards expired 62.6–62.7 seconds after arrival, including animation allowance, with Windows MessageDuration still 60.

The native queue then presented the two dismissed notifications approximately 123 and 183 seconds after their original arrival. Both produced `suppress-expired` records and neither produced a second `card-create`. The latter delay exceeded the previous two-minute suppression interval after dismissal, directly exercising the reproduced failure path. No Slack message was sent by these local toast tests.

The corrected build passed all 37 checks in GitHub's Windows CI. Downloaded CI source and DLL SHA-256 hashes matched the locally installed files. Same-version upgrades preserve prior DLLs using content-derived storage filenames; source, manifest, installer, and release all report 0.1.0. Installation and restore dry-runs passed. This session tested renderer reloads, not a Windows reboot or physical sleep/wake cycle.

## Optional local renderer trace

For a focused diagnostic session, create an empty `%LOCALAPPDATA%\WindowsNotificationFixes\trace-enabled` file. The parent directory must exist. Events then append to `renderer-trace.jsonl` in the same directory. The marker expires after 30 minutes; deleting it stops logging immediately. The log stops growing at 16 MiB. Remove or archive the old log before another session if necessary.

Events contain only event type, Windows FILETIME timestamps, original notification arrival, and numeric hit-test/action metadata. They exclude notification text, sender/app names, account data, and typed input. `card-create` and `card-remove` record rendering; `suppress-expired` and `suppress-aged` record replay suppression; `click-point`, `card-action`, `banner-command`, and `pending-command` allow dismissal routing to be checked. A Windows database arrival by itself does not establish a visible card.

## Manual acceptance procedure

1. Record the Windows build, Windhawk version, mod version, active apps, and display configuration.
2. Keep a different application in the foreground. Create two private events without guests, 20–30 seconds apart, with five-minute reminders. Confirm both sync to Outlook before their reminder times.
3. Observe both cards together, app labels, ordering, one ding each, and independent expiration. Do not hover during the duration measurement.
4. Repeat with Outlook fully closed. Confirm `olk.exe` is absent; distinguish initial delivery from replay when Outlook later opens.
5. Check alternating apps: a clearly labeled disposable Outlook test followed by a disposable Phone Link or test-app notification. Verify both visible sender labels, not just database application IDs. Exercise native-control reuse as well as simultaneous cards.
   Also post four uniquely labeled local test toasts together. Check all four appear, dismiss one, and wait at least five minutes from the burst without posting replacements. Verify expired or dismissed cards do not return as the native queue advances.
6. Restart Outlook and reload Windhawk; repeat. Then, as separate tests, perform a real sleep/wake cycle and Windows restart and repeat. Record which tests actually ran.
7. Delete test events and dismiss only their alerts. Preserve real reminders/messages. Remove any temporary test registrations.

Avoid relying on a browser-automation-owned tab to represent normal background state. Do not infer delivery from an in-app reminder window. A database arrival, a visible desktop card, and an audible sound are separate observations.
