# Verification

## Automated checks

`scripts/build.cjs` runs nine reminder-classification checks and fifteen notification-identity checks before compiling the full mod. The reminder tests reject mail, other applications, and misleading query substrings. Process detection reports whether Outlook is running without requiring a particular desktop state.

The identity regression models a Windows UIA control reused first for Outlook and then for Messages. The previous code retained the cached Outlook app name when the message changed. The fixed code rereads the current sender, includes it in cache reuse decisions, prefers a matched stored toast's source, and updates existing card text when metadata changes. Identical content from another app and temporarily missing sender data are covered.

## Observed desktop results before packaging

- Two real calendar reminders 20 seconds apart appeared together, newest first, while older notifications remained visible.
- Independent expiration passed while Windows MessageDuration stayed 60; observed card lifetime was roughly 62.5 seconds including animation allowance.
- Work and personal reminders both arrived with Outlook closed. The final audible pair arrived about 6.7 seconds after their target seconds, and the user confirmed both dings.
- A further work/personal pair arrived with Outlook running in the background within 0.1 second of the target seconds; the user confirmed one ding per reminder.
- Outlook restart and Windhawk renderer/service reload were tested. Those tests do **not** establish Windows reboot or physical sleep/wake behavior for this version.

## App-label report

A user reported a text notification labeled Outlook. The underlying Windows record identified Phone Link, but that does not prove the custom card's displayed label. Source inspection found a stale-app-name path when a UIA runtime ID was reused. This is a confirmed code defect and a plausible explanation of the reported card; no historical screenshot of that exact card was captured. The correction is included in mod 1.2.3. See release notes for subsequent live validation; automated regression coverage alone is not a claim that the historical display was directly reproduced.

The first local desktop test showed Outlook labeled correctly, but a Phone Link test had no app-name prefix because its per-device application ID returned no AppsFolder name. Mod 1.2.4 resolves the exact Phone Link package family explicitly, including its per-device message IDs. This is a separate correction from the cached-sender defect.

Mod 1.2.5 stores the raw UIA sender separately from the canonical display name. This preserves stable cache identity when Windows calls the source Messages and the card calls it Phone Link; it also avoids recreating an unchanged card when the raw sender is unavailable.

## Manual acceptance procedure

1. Record the Windows build, Windhawk version, mod version, active apps, and display configuration.
2. Keep a different application in the foreground. Create two private events without guests, 20–30 seconds apart, with five-minute reminders. Confirm both sync to Outlook before their reminder times.
3. Observe both cards together, app labels, ordering, one ding each, and independent expiration. Do not hover during the duration measurement.
4. Repeat with Outlook fully closed. Confirm `olk.exe` is absent; distinguish initial delivery from replay when Outlook later opens.
5. Check alternating apps: a clearly labeled disposable Outlook test followed by a disposable Phone Link or test-app notification. Verify both visible sender labels, not just database application IDs. Exercise native-control reuse as well as simultaneous cards.
6. Restart Outlook and reload Windhawk; repeat. Then, as separate tests, perform a real sleep/wake cycle and Windows restart and repeat. Record which tests actually ran.
7. Delete test events and dismiss only their alerts. Preserve real reminders/messages. Remove any temporary test registrations.

Avoid relying on a browser-automation-owned tab to represent normal background state. Do not infer delivery from an in-app reminder window. A database arrival, a visible desktop card, and an audible sound are separate observations.
