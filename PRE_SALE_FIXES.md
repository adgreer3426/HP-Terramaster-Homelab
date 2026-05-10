# Pre-Sale Fixes for HomeNAS_Setup_Guide

Apply each fix below in **Pages**, then re-export to PDF (`File → Export To → PDF`, Image Quality: Best). Order doesn't matter — fixes are independent.

Source of truth for these fixes: `REVIEW_HomeNAS_Setup_Guide.md`.

---

## Fix 1 — Plex Section: Replace placeholder claim token

**Find** (in the Plex `docker-compose` snippet):

```
PLEX_CLAIM=claim-x
```

**Replace with:**

```
# Get a fresh token from https://plex.tv/claim — expires in 4 minutes.
# Remove this line entirely after the server has been claimed once.
PLEX_CLAIM=<paste-your-token-here>
```

**Why:** `claim-x` is a placeholder, not a real token. Buyers following the guide verbatim will get an unclaimed server. Real tokens come from `plex.tv/claim`, expire in 4 minutes, and are only needed on first run.

---

## Fix 2 — Plex Section: PUID and PGID — VERIFIED ✓

Verified 2026-05-09: both lines correctly show `PUID=1000` and `PGID=1000`. The review extraction (`PUID=100`) was a binary-extraction artifact, not a real bug. **No change needed.**

---

## Fix 3 — Samba Section: Switch from `dperson/samba` to native Samba

The `dperson/samba` Docker image hasn't been maintained since ~2020 and has unpatched CVEs. **Replace the entire Samba Docker section** with the native install below — it's simpler, removes one container, and is what every maintained NAS guide recommends in 2026.

### New Samba section content

#### Install Samba

```bash
sudo apt update
sudo apt install -y samba samba-common-bin
```

#### Create users

For each NAS user (`adam`, `amanda`, `ava`, `leslie`), create a system user with no shell login, then set a Samba password:

```bash
sudo useradd -M -s /usr/sbin/nologin adam
sudo smbpasswd -a adam
```

Repeat for `amanda`, `ava`, and `leslie`.

#### Configure shares

Edit `/etc/samba/smb.conf` and append:

```ini
[media]
   path = /mnt/nas/media
   browseable = yes
   read only = no
   guest ok = no
   valid users = adam, amanda, ava, leslie
   create mask = 0664
   directory mask = 0775

[adam]
   path = /mnt/nas/adam
   browseable = yes
   read only = no
   valid users = adam
   create mask = 0664
   directory mask = 0775

[amanda]
   path = /mnt/nas/amanda
   browseable = yes
   read only = no
   valid users = amanda
   create mask = 0664
   directory mask = 0775

[ava]
   path = /mnt/nas/ava
   browseable = yes
   read only = no
   valid users = ava
   create mask = 0664
   directory mask = 0775

[leslie]
   path = /mnt/nas/leslie
   browseable = yes
   read only = no
   valid users = leslie
   create mask = 0664
   directory mask = 0775
```

#### Validate config and start the service

```bash
sudo testparm                          # syntax-check smb.conf
sudo systemctl restart smbd nmbd
sudo systemctl enable smbd nmbd        # auto-start on boot
```

**Why:** Native Samba removes a Docker container from the stack, has zero abandoned-image risk, and makes share configuration a single readable file (`/etc/samba/smb.conf`) instead of compose YAML with environment-variable overrides.

---

## Fix 4 — Initial Setup Section: Use `visudo`, not `nano`

**Find** (in the sudo configuration step, near "agreer ALL=(ALL:ALL) ALL"):

```bash
sudo nano /etc/sudoers
```

**Replace with:**

```bash
sudo visudo
```

Then add the line:

```
agreer ALL=(ALL:ALL) ALL
```

**Why:** A typo in `/etc/sudoers` locks you out of `sudo` completely — recovery requires booting into rescue mode. `visudo` syntax-checks the file before saving and refuses to write a broken config. This is non-negotiable for a guide aimed at people new to Linux server admin.

---

## Fix 5 — Add an IP Address Reference Table

Add this table near the top of the Tailscale section, **or** as a standalone "Network Addresses" subsection in the Quick Reference:

| Access Type | Address | When to Use |
|---|---|---|
| Local network (home) | `192.168.1.25` | On home Wi-Fi or wired LAN |
| Remote / VPN (Tailscale) | `100.115.3.97` | Anywhere outside the home network |

**Why:** Both IPs appear in the guide and serve different purposes. Without this table a buyer will eventually paste the wrong one and hit "host unreachable."

---

## Fix 6 — Troubleshooting Section: Add the chmod permission fix

If not already present, add to the **Troubleshooting & Reference** section:

### Samba write permissions broken after reboot

If users can read but not write to shares:

```bash
# Quick fix (world-writable — fine for a home NAS with no public exposure):
sudo chmod -R 777 /mnt/nas

# Better fix (owner+group writable, others read-only):
sudo chown -R agreer:agreer /mnt/nas
sudo chmod -R 775 /mnt/nas
```

**Why:** This is the single most common runtime issue on this stack. Listing both options lets buyers choose between speed and security hygiene without having to ask.

---

## Fix 7 — Plex Section: Document Orbi port forwarding

If not already present, add to the end of the **Plex** section:

### Enable Plex remote access (Orbi router)

Plex needs port `32400` forwarded for direct remote streaming. (Tailscale also works for personal use, but port forwarding is required for sharing libraries with friends/family without making them install Tailscale.)

1. Log into the Orbi admin at `http://orbilogin.com` (or `http://192.168.1.1`)
2. Navigate to **Advanced → Advanced Setup → Port Forwarding / Port Triggering**
3. Add a new custom service:
   - **Service Name:** `Plex`
   - **Service Type:** `TCP`
   - **External Starting Port:** `32400`
   - **External Ending Port:** `32400`
   - **Internal IP Address:** `192.168.1.25`
   - **Internal Starting Port:** `32400`
   - **Internal Ending Port:** `32400`
4. **Apply**, then in Plex Web go to **Settings → Remote Access** and confirm: *"Fully accessible outside your network."*

**Why:** Without port forwarding, Plex falls back to its own relay, which is throttled to 2 Mbps per stream — unwatchable for anything above 480p.

---

## Fix 8 — NEW SECTION: NAS Transfer Droplet (macOS)

Add this as a new section. Suggested location: between **Troubleshooting & Reference** and **Smartmontools**, or as a sub-section under **Quick Reference**.

### Bonus: NAS Transfer Droplet (macOS)

A drag-and-drop AppleScript droplet that `rsync`s files to the `media` share. Drop files or folders on the app icon → transfer runs in Terminal with progress → notification when done.

**Why a droplet?** Finder's SMB transfer throws error `-8062` on large files (>4 GB or many files at once). `rsync` handles them reliably. The droplet wraps the `rsync` command so you don't have to type it every time.

**Requirements:**

- macOS with Script Editor (built in)
- Homebrew rsync: `brew install rsync` (Apple's bundled `openrsync` has SMB bugs on macOS Tahoe)

**Build steps:**

1. Open **Script Editor** (Applications → Utilities)
2. **File → New**
3. Paste the contents of `NAS_Transfer.applescript` (included with this guide)
4. **File → Export…**
   - **File Format:** Application
   - **Save as:** `NAS Transfer.app`
   - **Where:** Applications folder
5. Drag the resulting `.app` to your Dock

**Usage:**

- Drag any file or folder onto the **NAS Transfer.app** icon
- A Terminal window opens showing `rsync` progress
- A macOS notification appears when the transfer completes

**Customization:**

- The droplet only targets the `media` share (`smb://192.168.1.25/media`). To transfer to a user share (e.g. `adam`), edit the `shareName` property at the top of the script and re-export.
- The droplet auto-mounts the share if it's not already mounted.
- macOS metadata files (`.DS_Store`, `._*`, `.Spotlight-V100`, `.Trashes`) are excluded automatically — they cause SMB errors otherwise.
- Original files are **not** deleted — this is a copy, not a move.

---

## After applying all fixes

1. In Pages: **File → Export To → PDF** — set Image Quality to **Best**
2. Save as `HomeNAS_Setup_Guide.pdf` in this repo folder
3. Spot-check the PDF:
   - Docker-compose / config snippets render in a readable monospace font
   - Any newly-added sections appear in the Table of Contents
     - To regenerate the TOC if it looks stale: click into the existing TOC → it should auto-update, or **Insert → Table of Contents → Document** to refresh
4. When the PDF looks clean, you're ready to assemble the Gumroad bundle (PDF + `NAS_Transfer.applescript` + standalone `docker-compose.yml` files + bill-of-materials)

---

## Quick checklist

- [ ] Fix 1 — Plex `PLEX_CLAIM` placeholder explained
- [x] Fix 2 — Plex `PUID` / `PGID` verified as `1000`
- [ ] Fix 3 — Samba section rewritten to use native `apt` install
- [ ] Fix 4 — Sudoers edit uses `visudo`
- [ ] Fix 5 — IP address reference table added
- [ ] Fix 6 — Permission troubleshooting commands added
- [ ] Fix 7 — Orbi port forwarding documented
- [ ] Fix 8 — NAS Transfer Droplet section added
- [ ] PDF exported and spot-checked
