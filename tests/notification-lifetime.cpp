#include "notification-lifetime.h"
#include <cassert>
#include <iostream>

int main() {
    using namespace NotificationLifetime;
    constexpr std::int64_t arrival=134400000000000000LL;
    constexpr std::uint64_t lifetime=61500;
    auto after=[&](std::uint64_t ms){return static_cast<std::uint64_t>(arrival)+ms*10000;};
    assert(RemainingMilliseconds(arrival,after(0),lifetime)==lifetime);
    assert(RemainingMilliseconds(arrival,after(20000),lifetime)==41500);
    assert(RemainingMilliseconds(arrival,after(lifetime-1),lifetime)==1);
    assert(RemainingMilliseconds(arrival,after(lifetime),lifetime)==0);
    assert(RemainingMilliseconds(arrival,after(180000),lifetime)==0);
    assert(RemainingMilliseconds(arrival,after(600000),lifetime)==0);
    assert(RemainingMilliseconds(0,after(600000),lifetime)==lifetime);
    assert(RemainingMilliseconds(arrival,arrival-10000,lifetime)==lifetime);
    assert(KeepExpired(arrival,false,180000));
    assert(KeepExpired(arrival,false,3600000));
    assert(!KeepExpired(arrival,true,0));
    assert(KeepExpired(0,false,180000));
    assert(!KeepExpired(0,false,24ULL*60*60*1000+1));
    std::cout << "13 notification lifetime checks passed\n";
}
