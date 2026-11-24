#pragma once
#include <string_view>

namespace NotificationIdentity {
// Windows can reuse the same UIA runtime ID across different applications.
// A control is a cache location, not the identity of a notification's sender.
inline bool CanReuse(std::wstring_view previousApp, std::wstring_view previousTitle,
                     std::wstring_view previousText, std::wstring_view sender,
                     std::wstring_view title, std::wstring_view text) {
    return previousApp == sender && previousTitle == title && previousText == text;
}
inline std::wstring_view Sender(std::wstring_view currentSender, std::wstring_view storedSender = {}) {
    return storedSender.empty() ? currentSender : storedSender;
}
inline std::wstring_view DisplayName(std::wstring_view aumid, std::wstring_view resolvedName) {
    // Phone Link's per-device Messages IDs aren't resolved by AppsFolder.
    // Use the exact package family, never a previous control's cached sender.
    if (aumid.starts_with(L"Microsoft.YourPhone_8wekyb3d8bbwe!")) return L"Phone Link";
    return resolvedName;
}
}
