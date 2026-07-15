# 🌌 DarqSied's Cross-Platform Multi-Environment

![Linux](https://img.shields.io/badge/Linux-Arch-33BAE3?style=for-the-badge&logo=arch-linux&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-11-0078D4?style=for-the-badge&logo=windows&logoColor=white)
![Manager](https://img.shields.io/badge/Manager-GNU_Stow-FF4B4B?style=for-the-badge)
![WM](https://img.shields.io/badge/WM-dwm_|_Qtile-5E5086?style=for-the-badge)

> A production-grade, keyboard-driven computing environment spanning a tailored Linux Suckless/Python ecosystem and a deeply modularized Windows automation layer.

---

## 🧠 Core Philosophy & Insights

This repository bridges two completely different OS mentalities into a singular, highly efficient workflow.

*   **Suckless Minimalism with Modern Visuals:** The Linux environment anchors on a custom C-compiled `dwm` window manager accompanied by `dwmblocks` for bar management. It handles compositing via `picom` and notification routing via `dunst`. 
*   **The Decoupled Windows Core:** Instead of a single massive script, the `AutoHotKey` setup is fully architecture-engineered. It separates orchestration (`Router.ahk`), configurations (`Config.ahk`), and layout mutations (`WindowManager.ahk`) into dedicated micro-modules.
*   **Stow-Optimized Deployment:** The `dotfiles` folder is organized exactly to mimic a clean home folder mapping. Running GNU Stow out of the parent path cleanly mirrors `.config`, `.local/bin`, and your shell targets right where they belong.

---

## 🛠️ The Tech Stack

| Component | Linux Environment | Windows Environment | Insight / Rationale |
| :--- | :--- | :--- | :--- |
| **Window Manager** | `dwm` (Custom C patches) / `Qtile` | Virtual Desktop Accessor | Native dynamic tiling layout vs emulated workspace hooks. |
| **Terminal / Prompt** | `Alacritty` + Oh My Posh (`capr4n` theme)[cite: 1] | Windows Terminal / Alacritty[cite: 1] | GPU rendering parity across environments[cite: 1]. |
| **Shell System** | `Zsh` (Autopair, Suggestions, Vim-mode)[cite: 1] | PowerShell 7[cite: 1] | Unifying terminal shortcuts and editor paradigms[cite: 1]. |
| **Core Editor** | LunarVim Ecosystem (`init.lua` + base configurations)[cite: 1] | LunarVim (Shared via AppData)[cite: 1] | A fully IDE-fledged text editor experience on both operating systems[cite: 1]. |
| **Utility Hub** | `ranger`, `lf`, `nsxiv`, `rofi`[cite: 1] | Native custom shortcuts[cite: 1] | Fast file previewing, selection, and clipboard tracking via `greenclip`[cite: 1]. |

---

## 📂 Repository Tree

```text
.
├── AutoHotKey/                   # Deeply modular Windows translation engine[cite: 1]
│   ├── Shortcuts.ahk             # Central daemon runner[cite: 1]
│   ├── VirtualDesktopAccessor.dll# Raw Windows virtual desktop hook[cite: 1]
│   └── Modules/                  # Componentized engine files (WindowManager, Keybindings, Router)[cite: 1]
│
└── dotfiles/                     # Pure Linux GNU Stow root package[cite: 1]
    ├── .config/                  # Isolated configuration directories[cite: 1]
    │   ├── dwm/                  # Source C code for dwm + dynamic tiling patches[cite: 1]
    │   ├── nvim/                 # Fully fleshed out LunarVim layer[cite: 1]
    │   ├── polybar/scripts/      # Custom localized metric gathering scripts[cite: 1]
    │   └── zsh/                  # Advanced shell configurations and plugin entries[cite: 1]
    └── .local/bin/               # Bespoke workspace utility scripts (anime, atmux, torr, powermenu)[cite: 1]
