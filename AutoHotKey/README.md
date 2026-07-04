# ⚡ AHK v2 Modular Engine

A hyper-optimized, zero-overhead AutoHotkey v2 workspace designed for power users. This engine is entirely modular, breaking away from traditional monolith scripts into a clean, phased boot sequence with native Windows OS hooks.

## 🏗️ Architecture

The engine is centralized through a single hub (`Shortcuts.ahk`) that loads modules in strict phases: Core Definitions, System Logic, User Interfaces, and Triggers.

```text
📁 AutoHotKey (Root Directory)
│
├── 📄 Shortcuts.ahk              [THE HUB] The central nervous system.
├── ⚙️ VirtualDesktopAccessor.dll [EXTERNAL] Bridge for native virtual desktop manipulation.
│
└── 📁 Modules                    [THE ENGINE]
    │
    ├── 🧠 Phase 1: Core Definitions
    │   ├── 📄 Config.ahk         (Global Variables, App Maps, PWA Lists)
    │   ├── 📄 InitHooks.ahk      (Startup Sequence, Shell Hooks, Native Mouse Hook)
    │   └── 📄 Utilities.ahk      (Helper Functions, Smart Notifiers, Silent Logger)
    │
    ├── 🏗️ Phase 2: System Logic
    │   ├── 📄 Router.ahk         (Virtual Desktop Auto-Routing & Delayed Title Polling)
    │   ├── 📄 WindowManager.ahk  (Centering, Ghost Mode, Scratchpads, Z-Order)
    │   └── 📄 CaptureEngine.ahk  (Hybrid Screenshot Watchdog & ShareX Bridge)
    │
    ├── 🖥️ Phase 3: User Interface
    │   ├── 📄 Cheatsheet.ahk     (Dynamic File Parser & Grid GUI Renderer)
    │   └── 📄 TrayMenu.ahk       (Custom Command Center & Global Toggles)
    │
    └── ⚡ Phase 4: The Triggers
        ├── 📄 Hotstrings.ahk     (Text Abbreviations & Snippets)
        └── 📄 Keybindings.ahk    (All Hotkeys, Mouse Overrides, and Leader Keys)