#pragma once
#include <cstdint>

namespace NotificationLifetime {
// A Windows banner can reach the UIA fallback several minutes after delivery.
// That observation must not restart a card's display budget.
inline std::uint64_t RemainingMilliseconds(std::int64_t arrivalFileTime,
                                         std::uint64_t nowFileTime,
                                         std::uint64_t lifetimeMs) {
    if (arrivalFileTime <= 0 || nowFileTime < static_cast<std::uint64_t>(arrivalFileTime)) return lifetimeMs;
    const auto elapsed=(nowFileTime-static_cast<std::uint64_t>(arrivalFileTime))/10000;
    return elapsed >= lifetimeMs ? 0 : lifetimeMs-elapsed;
}

// Retain suppression while the actual stored notification still exists. An
// arbitrary short timeout cannot cover Windows' serial native banner queue.
inline bool KeepExpired(std::int64_t arrivalFileTime, bool removedFromStore,
                        std::uint64_t ageMs) {
    if (arrivalFileTime > 0) return !removedFromStore;
    return ageMs <= 24ULL*60*60*1000; // Legacy non-stored banner fallback only.
}
}
