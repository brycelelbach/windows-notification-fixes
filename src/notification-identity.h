#pragma once
#include <string_view>

namespace NotificationIdentity {
// Windows can reuse the same UIA runtime ID across different applications.
// A control is a cache location, not the identity of a notification's sender.
inline bool CanReuse(std::wstring_view previousApp, std::wstring_view previousTitle,
                     std::wstring_view previousText, std::wstring_view sender,
                     std::wstring_view title, std::wstring_view text) {
    return !sender.empty() && previousApp == sender && previousTitle == title && previousText == text;
}
inline std::wstring_view Sender(std::wstring_view currentSender, std::wstring_view storedSender = {}) {
    return storedSender.empty() ? currentSender : storedSender;
}
}
