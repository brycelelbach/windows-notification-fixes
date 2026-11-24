#pragma once
#include <windows.h>
#include <tlhelp32.h>
#include <string>
#include <string_view>

// Local policy for the user's requested audible calendar reminders. The normal
// notification sound settings and Quiet Hours checks remain in the renderer.
namespace OutlookReminderSound {
inline bool IsCalendarReminder(const std::wstring& aumid, std::string_view launch) {
    if (_wcsicmp(aumid.c_str(), L"Microsoft.OutlookForWindows_8wekyb3d8bbwe!Microsoft.OutlookforWindows")) {
        return false;
    }
    if (auto pos = launch.find('?'); pos != std::string_view::npos) {
        launch.remove_prefix(pos + 1);
    }
    launch = launch.substr(0, launch.find('#'));
    while (!launch.empty()) {
        auto end = launch.find('&');
        if (launch.substr(0, end) == "notificationType=EventReminder") return true;
        if (end == std::string_view::npos) break;
        launch.remove_prefix(end + 1);
    }
    return false;
}

inline bool IsRunningInThisSession() {
    DWORD session = 0;
    if (!ProcessIdToSessionId(GetCurrentProcessId(), &session)) return true;
    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot == INVALID_HANDLE_VALUE) return true;
    PROCESSENTRY32W entry{};
    entry.dwSize = sizeof(entry);
    if (!Process32FirstW(snapshot, &entry)) {
        CloseHandle(snapshot);
        return true;  // Do not risk duplicate sound if process enumeration failed.
    }
    do {
        if (_wcsicmp(entry.szExeFile, L"olk.exe") == 0) {
            DWORD processSession = 0;
            if (!ProcessIdToSessionId(entry.th32ProcessID, &processSession) || processSession == session) {
                CloseHandle(snapshot);
                return true;
            }
        }
    } while (Process32NextW(snapshot, &entry));
    DWORD error = GetLastError();
    CloseHandle(snapshot);
    return error != ERROR_NO_MORE_FILES;
}
}
