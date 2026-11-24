# Release version policy

Use one release version across VERSION, Windhawk source metadata, build manifest,
installer, ZIP, and Git tag. The current release is 0.1.0.

Keep the version unchanged throughout a round of related work and testing. Do not
increment it for each edit, intermediate build, or individual bug fix. Choose a
new version for a later release after a separate period of work, or when the user
explicitly requests it. Git commits and artifact hashes distinguish intermediate
builds; they are not extra user-facing version numbers.

Preserve notification settings and rollback copies. Do not publish private
calendar data, account settings, notification payloads, or diagnostic screenshots.
