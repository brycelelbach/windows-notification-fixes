#include "outlook-reminder-sound.h"
#include <iostream>
#include <cassert>
int main(int argc, char** argv) {
    const std::wstring outlook = L"Microsoft.OutlookForWindows_8wekyb3d8bbwe!Microsoft.OutlookforWindows";
    using OutlookReminderSound::IsCalendarReminder;
    assert(IsCalendarReminder(outlook, "notificationType=EventReminder&buttonId=Click"));
    assert(IsCalendarReminder(outlook, "ms-outlook://scheduled?notificationType=EventReminder&buttonId=Click"));
    assert(IsCalendarReminder(outlook, "buttonId=Click&notificationType=EventReminder"));
    assert(!IsCalendarReminder(outlook, "notificationType=Mail&buttonId=Click"));
    assert(!IsCalendarReminder(L"Slack", "notificationType=EventReminder"));
    assert(!IsCalendarReminder(outlook, "itemId=notificationType=EventReminder"));
    assert(!IsCalendarReminder(outlook, "notificationType=EventReminderExtra"));
    assert(!IsCalendarReminder(outlook, "#notificationType=EventReminder"));
    assert(!IsCalendarReminder(outlook, ""));
    bool running = OutlookReminderSound::IsRunningInThisSession();
    if (argc > 1) assert(running == (std::string_view(argv[1]) == "running"));
    std::cout << "9 classification checks passed; Outlook running=" << running << '\n';
}
