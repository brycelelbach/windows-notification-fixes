// Build with the exact Windhawk toolchain used for the installed mod.
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const {createHash} = require('node:crypto');
const root = path.resolve(__dirname, '..');
const version=fs.readFileSync(path.join(root,'VERSION'),'utf8').trim();
if(!/^\d+\.\d+\.\d+$/.test(version)) throw new Error('VERSION must contain a release version');
const wh = process.env.WINDHAWK_ROOT || path.join(process.env.ProgramFiles || 'C:/Program Files', 'Windhawk');
const cc = path.join(wh, 'Compiler/bin/clang++.exe');
const build = path.join(root, 'build'), dist = path.join(root, 'dist');
for (const dir of [build, dist]) fs.mkdirSync(dir, {recursive:true});
const run = (command,args,cwd=root) => {
  const r=spawnSync(command,args,{cwd,encoding:'utf8',windowsHide:true});
  if(r.stdout) process.stdout.write(r.stdout);
  if(r.stderr) process.stderr.write(r.stderr);
  if(r.error || r.status!==0) throw r.error || new Error(`Command failed (${r.status}): ${command}`);
};
const common=['-std=c++23','-O2','-DUNICODE','-D_UNICODE','-target','x86_64-w64-mingw32','-I'+path.join(root,'src')];
for(const name of ['outlook-reminder-sound','notification-identity','notification-lifetime']) {
  const exe=path.join(build,name+'.exe');
  run(cc,[...common,'-static',path.join(root,'tests',name+'.cpp'),'-o',exe],path.join(wh,'Compiler'));
  run(exe,[]); // Classifiers are independent of whether Outlook happens to be running.
}
let source=fs.readFileSync(path.join(root,'src/compact-notifications.wh.cpp'),'utf8');
for(const name of ['outlook-reminder-sound.h','notification-identity.h','notification-lifetime.h','notification-trace.h']) {
  source=source.replace(`#include "${name}"`,fs.readFileSync(path.join(root,'src',name),'utf8').replace(/^#pragma once\r?\n/,''));
}
const standalone='compact-notifications.wh.cpp';
fs.writeFileSync(path.join(dist,standalone),source);
if(source.match(/@version\s+(\S+)/)?.[1]!==version) throw new Error('Source metadata must match VERSION');
const modId='local@compact-notifications-background';
const output=path.join(build,'notification-fixes.dll');
run(cc,[...common,'-shared','-DWINVER=0x0A00','-D_WIN32_WINNT=0x0A00','-D_WIN32_IE=0x0A00','-DNTDDI_VERSION=0x0A000008','-D__USE_MINGW_ANSI_STDIO=0','-DWH_MOD',`-DWH_MOD_ID=L"${modId}"`,`-DWH_MOD_VERSION=L"${version}"`,path.join(wh,'Engine/1.7.3/64/windhawk.lib'),path.join(dist,standalone),'-include','windhawk_api.h','-Wl,--export-all-symbols','-Wl,--no-insert-timestamp','-o',output,'-lole32','-loleaut32','-ld2d1','-ldwrite','-lshcore','-lgdi32','-lwindowscodecs','-ladvapi32','-lshell32','-ldwmapi','-lwinmm'],path.join(wh,'Compiler'));
// Content-derived storage names preserve rollback copies during same-version development.
const binaryHash=createHash('sha256').update(fs.readFileSync(output)).digest('hex');
const dll=`${modId}_${version}_${binaryHash.slice(0,12)}.dll`;
fs.copyFileSync(output,path.join(dist,dll));
const hash=f=>createHash('sha256').update(fs.readFileSync(path.join(dist,f))).digest('hex');
const manifest={version,modId,libraryFileName:dll,windhawkVersion:'1.7.3',architecture:'x86-64',files:{[standalone]:hash(standalone),[dll]:hash(dll)}};
fs.writeFileSync(path.join(dist,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log(JSON.stringify(manifest,null,2));
