# 🐧 Linux Dotfiles & Suckless Core

This directory contains the core configuration files for my Linux environment. It is designed to be managed with GNU Stow and deployed directly to the home (`~`) directory[cite: 1].

The environment is heavily keyboard-driven, prioritizing low system overhead and modularity through custom C-compiled binaries and bespoke shell scripts.

---

## 🏗️ Window Management: The Suckless Desktop

The primary graphical environment is built on the Suckless philosophy, utilizing a custom-patched build of `dwm`[cite: 1]. A secondary `Qtile` configuration is also maintained as a Python-based alternative[cite: 1].

### `dwm` (Dynamic Window Manager)
The `dwm` source code is embedded directly in `.config/dwm/`[cite: 1]. It features several critical quality-of-life patches to enhance the modern desktop experience:
*   **`vanitygaps`**: Adds customizable inner and outer gaps between tiled windows[cite: 1].
*   **`swallow`**: Terminal windows are dynamically "swallowed" (hidden) when launching graphical applications from them, reducing clutter[cite: 1].
*   **`scratchpad`**: Enables a drop-down terminal that can be toggled via a hotkey without disrupting the current tiling layout[cite: 1].
*   **`ipc`**: Inter-process communication enabled via `dwm-msg` for external script control[cite: 1].
*   **Status Bar**: Patched with `bar_status2d`, `bar_tags`, and `bar_alpha` for a highly customized visual aesthetic[cite: 1].

### Status Bar & Compositing
*   **`dwmblocks`**: A modular status bar for `dwm` compiled from `.config/dwmblocks/`[cite: 1]. Modules are driven by the shell scripts located in `.local/bin/dwm-scripts/` (tracking battery, CPU, memory, and internet traffic)[cite: 1].
*   **`picom`**: Handles transparency, shadows, and vsync[cite: 1].
*   **`polybar`**: Available as an alternative status bar via `.config/polybar/`[cite: 1].

---

## 💻 Terminal & Shell Environment

| Tool | Configuration | Description |
| :--- | :--- | :--- |
| **Emulator** | `alacritty` | GPU-accelerated terminal configured via `.config/alacritty/`[cite: 1]. |
| **Shell** | `zsh` | Core aliases, exports, and functions split into modular files in `.config/zsh/`[cite: 1]. |
| **Prompt** | `Oh My Posh` | Uses the custom `capr4n.omp.json` theme for a fast, informative prompt[cite: 1]. |
| **Plugins** | Custom | Includes `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `zsh-you-should-use`[cite: 1]. |

---

## 📝 Editor: LunarVim Setup

The Neovim environment is managed through the LunarVim framework, completely encapsulating the IDE experience within `.config/nvim/`[cite: 1].

*   **Initialization:** Core settings and mappings are managed in `config.lua` and `init.lua`[cite: 1].
*   **LSP & Formatting:** Pre-configured with language servers (`lua_ls`, `tailwindcss`, `jsonls`) and null-ls for formatting[cite: 1].
*   **UI Plugins:** Integrated with `lualine`, `alpha` dashboard, `telescope` for fuzzy finding, and `nvimtree`[cite: 1].

---

## 🧰 Custom Utility Scripts (`.local/bin`)

The `.local/bin` directory acts as a personal PATH repository for workflow automation[cite: 1]. 

Notable scripts include:
*   **`anime` / `torr`**: CLI-based media and torrent management[cite: 1].
*   **`atmux`**: Automated tmux session management[cite: 1].
*   **`lfrun`**: Wrapper for the `lf` terminal file manager[cite: 1].
*   **`powermenu` / `launcher`**: Scripted Rofi menus for system power states and application launching[cite: 1].

---

## ⚙️ Compiling & Installation

To deploy this environment, use GNU Stow from the parent directory:

```bash
# Link all configs to the home directory
cd ~/dotfiles
stow -t ~ dotfiles

#Recompiling Suckless Binaries
#Whenever changes are made to the config.def.h or source .c files in dwm or dwmblocks, they must be recompiled[cite: 1].

#Bash
## Compile and install dwm
cd ~/.config/dwm
sudo make clean install
## Compile and install dwmblocks
cd ~/.config/dwmblocks
sudo make clean install