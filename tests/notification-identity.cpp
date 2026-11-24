#include "notification-identity.h"
#include <cassert>
#include <iostream>

int main() {
    using namespace NotificationIdentity;
    // Regression: one Windows control first showed Outlook, then a phone message.
    // The old branch used the cached app even though its title/text changed.
    const auto cachedApp = L"Outlook";
    assert(!CanReuse(cachedApp, L"Meeting", L"Starts now", L"Messages", L"Contact", L"Hello"));
    assert(Sender(L"Messages") == L"Messages");
    assert(Sender(L"Messages") != cachedApp);
    // Identical text from two apps must not reuse the previous app identity.
    assert(!CanReuse(cachedApp, L"Hello", L"Body", L"Messages", L"Hello", L"Body"));
    assert(CanReuse(cachedApp, L"Hello", L"Body", L"Outlook", L"Hello", L"Body"));
    assert(!CanReuse(cachedApp, L"Hello", L"Body", L"", L"Hello", L"Body"));
    // The exact matched stored notification provides authoritative app metadata.
    assert(Sender(L"Outlook", L"Messages") == L"Messages");
    assert(Sender(L"", L"Messages") == L"Messages");
    assert(Sender(L"").empty());
    std::cout << "9 notification identity regression checks passed\n";
}
