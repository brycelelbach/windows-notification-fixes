#pragma once
#include <windows.h>
#include <cstdio>
#include <string>

// Opt-in, local, metadata-only tracing. The marker expires after 30 minutes.
// Never records notification text, app names, account data, or input text.
inline void NotificationTrace(const char* event, long long arrival, long long a=0, long long b=0) {
    wchar_t local[MAX_PATH];
    const auto length=GetEnvironmentVariableW(L"LOCALAPPDATA", local, MAX_PATH);
    if (!length || length>=MAX_PATH) return;
    const std::wstring folder=std::wstring(local)+L"\\WindowsNotificationFixes\\";
    WIN32_FILE_ATTRIBUTE_DATA marker{};
    if (!GetFileAttributesExW((folder+L"trace-enabled").c_str(), GetFileExInfoStandard, &marker)) return;
    FILETIME time; GetSystemTimeAsFileTime(&time);
    const auto ticks=(static_cast<unsigned long long>(time.dwHighDateTime)<<32)|time.dwLowDateTime;
    const auto enabled=(static_cast<unsigned long long>(marker.ftLastWriteTime.dwHighDateTime)<<32)|marker.ftLastWriteTime.dwLowDateTime;
    if (ticks<enabled || ticks-enabled>30ULL*60*10000000) return;
    HANDLE file=CreateFileW((folder+L"renderer-trace.jsonl").c_str(), FILE_APPEND_DATA|FILE_READ_ATTRIBUTES,
        FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE, nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if(file==INVALID_HANDLE_VALUE) return;
    LARGE_INTEGER size{};
    if(GetFileSizeEx(file,&size) && size.QuadPart<16*1024*1024) {
        char line[300];
        const int n=std::snprintf(line,sizeof(line),"{\"event\":\"%s\",\"time\":%llu,\"arrival\":%lld,\"a\":%lld,\"b\":%lld}\n",event,ticks,arrival,a,b);
        DWORD written;
        if(n>0 && n<static_cast<int>(sizeof(line))) WriteFile(file,line,n,&written,nullptr);
    }
    CloseHandle(file);
}
