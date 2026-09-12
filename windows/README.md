# Windows / Galaxy Book

Windows 10/11 x64 portable desktop app. Galaxy Book ARM devices require Windows x64 emulation. The app keeps all planner records in the current Windows user's AppData directory; it does not need a paid server or API key. Weather requires an internet connection.

The rabbit stays above other windows and can wander within the monitor's work area. Drag the rabbit using its drag handle. Closing the planner leaves the rabbit running; close the rabbit window from the taskbar to quit.

Build with Node 24 and pnpm 11.19.0:

```sh
pnpm install --frozen-lockfile
python ../scripts/prepare-web-assets.py
pnpm test
pnpm smoke
pnpm dist
```

The GitHub Actions Windows job opens actual Electron windows, checks isolation, persistence, validated IPC, resize, movement and stop, then builds the portable EXE. A successful job is required before calling the Windows version runtime-tested. A macOS smoke run does not validate Windows rendering or Galaxy Book hardware.

The portable executable is unsigned. Windows may show its standard unknown-publisher notice. No administrator installation is required. Do not disable antivirus or SmartScreen globally.
