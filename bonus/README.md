# Bonus Pack — HomeNAS Setup Guide

This folder accompanies the **HomeNAS Setup Guide** PDF. It contains drop-in configuration files and helper scripts so you can skip the manual typing for the longer config sections.

Every file in here has a header comment explaining:

- Which section of the guide it pairs with
- Where to put it on the HP Mini
- What values to substitute before saving

Always pair each file with its section in the guide — these are templates with example values, not turnkey configs.

## Contents

| File | Pairs with | Drop-in destination |
|---|---|---|
| `docker-compose.yml` | §5.1 | `~/docker/docker-compose.yml` |
| `smb.conf.sample` | §6.3 | Append to `/etc/samba/smb.conf` |
| `smartd.conf.sample` | §9.3 | Append to `/etc/smartd.conf` |
| `msmtprc.sample` | §9.4 | `/etc/msmtprc` |
| `99-tailscale.conf` | §7.3 | `/etc/sysctl.d/99-tailscale.conf` |
| `tailscale-ethtool.service` | §7.3 | `/etc/systemd/system/tailscale-ethtool.service` |
| `NAS_Transfer.applescript` | §10.1–10.3 | macOS Script Editor → export as `.app` |
| `NAS_Transfer.bat` | §10.4 | Anywhere on your Windows desktop |

## Substitution checklist

The templates use the same dummy values as the guide. Replace these everywhere before saving:

| Template value | Your value |
|---|---|
| `your-email@gmail.com` | Alert recipient (Gmail) |
| `<paste-your-16-char-app-password-here>` | Gmail App Password (no spaces) |
| `<paste-your-token-here>` | Fresh Plex claim token from `https://plex.tv/claim` |
| `alice` / `bob` / `carol` / `dave` | Your NAS usernames |
| `America/Chicago` | Your timezone (`Region/City` format) |
| `eno1` | Your network interface (`ip -br link show`) |
| `192.168.1.100` | HP Mini's LAN IP |

The full canonical list is in the **Your Values** worksheet at the start of the guide PDF.

## A note on overwriting system files

Two of these files (`smb.conf.sample`, `smartd.conf.sample`) are meant to be **appended** to existing system files — not to replace them. Debian ships with default `/etc/samba/smb.conf` and `/etc/smartd.conf` files whose `[global]` sections (and `DEVICESCAN` line, respectively) you should preserve.

The other config files (`msmtprc.sample`, `99-tailscale.conf`, `tailscale-ethtool.service`) replace or create their target files outright — those locations are either empty by default or only contain a single setting.

When in doubt, follow the matching guide section step-by-step instead of blindly copying.
