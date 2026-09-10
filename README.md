# NixOS Config

NixOS configuration (flake) for two hosts:

- **`niro`** — desktop (x86_64-linux), the control machine.
- **`almiraj`** — netcup ARM VPS (aarch64-linux), public services.

## Programs used (desktop)

- Distro - [NixOS](https://nixos.org/)
- Shell - [Noctalia](https://github.com/noctalia-dev/noctalia-shell)
- Terminal - [Kitty](https://github.com/kovidgoyal/kitty)
- WM - [niri](https://github.com/YaLTeR/niri)
- Launcher - [rofi](https://archlinux.org/packages/community/x86_64/rofi/)
- File Manager - [yazi](https://github.com/sxyazi/yazi)
- Image viewer - [nsxiv](https://wiki.archlinux.org/title/nsxiv)
- Video player - [mpv](https://wiki.archlinux.org/title/Mpv)
- Audio player - [mpd](https://wiki.archlinux.org/title/Music_Player_Daemon)+[ncmpcpp](https://wiki.archlinux.org/title/Ncmpcpp)
- RSS reader - [newsboat](https://wiki.archlinux.org/title/Newsboat)
- Editor - [neovim](https://neovim.io/) (via nvf)

![](./wall.png)