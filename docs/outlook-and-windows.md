# Outlook and Windows prerequisites

The mod renders arrivals; Outlook must first submit a reminder to Windows.

1. In new Outlook, open Settings → General → Notifications. Enable notifications and **Send notifications when Outlook is closed**. Include both personal and work accounts when multiple accounts are connected.
2. Use Calendar **Desktop** style, rather than only Outlook's separate Reminders window. Configure the desired reminder sound in Outlook. The fork supplies the fallback sound only when `olk.exe` is absent from the current Windows session.
3. Account-specific settings can differ. During the investigation, one work profile lacked native `Reminder` registration even though personal reminders worked. Loading the work profile's settings, choosing Desktop, fully closing and restarting Outlook under that profile, then restoring the original primary account initialized both registrations. Verify each account; success on one does not establish success on the other.
4. In Windows Settings → System → Notifications, allow Outlook notifications, banners, and sound. Review Do Not Disturb and its automatic rules according to your preferences. This installer does not disable Do Not Disturb rules.
5. In Outlook's Windows app advanced settings, allow it to run in the background when that control is available. Microsoft's closed-app notification guidance recommends **Always**.
6. Confirm the actual event's reminder in Outlook. A five-minute default applies to newly created items; an invitation may carry another setting. Google Calendar's array of reminder times does not become an equivalent array in Outlook.

Test with a private event on each account and no attendees. Check both the Windows arrival and visible/audible delivery. A card can only display after Windows receives a toast. Closed-app push can have several seconds of delay even with correct configuration.

Sources:
- [Microsoft: What's new in new Outlook](https://support.microsoft.com/en-us/outlook/getstarted/what-s-new-in-new-outlook-for-windows)
- [Microsoft: Change notification settings](https://support.microsoft.com/en-us/windows/change-notification-settings-in-windows-8942c744-6198-fe56-4639-34320cf9444e)
