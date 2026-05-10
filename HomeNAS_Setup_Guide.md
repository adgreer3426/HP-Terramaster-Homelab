# Build a Home NAS — A Synology Alternative

**HP Mini + TerraMaster + Debian 13 + Plex + Tailscale**

A complete, battle-tested recipe for building a 14 TB redundant home NAS that streams Plex everywhere, shares files for the whole family, and is reachable securely from anywhere — without the Synology price tag.

---

## What You'll Build

By the end of this guide you'll have:

- A Debian 13 server running on an HP Mini
- Two drives in software RAID 1 (mirrored — either drive can fail with no data loss)
- **Plex** streaming to phones, TVs, and laptops on your network and remotely
- **Samba** file shares with per-user passwords and a shared media folder
- **Tailscale** for secure remote access from anywhere with no router exposure
- **Smartmontools** monitoring drive health with email alerts to your inbox
- A drag-and-drop **macOS droplet** for fast, reliable file transfers

**Cost vs. Synology DS224+ (2-bay, 14 TB equivalent):**
- This build (HP Mini used + TerraMaster D2-310 + 2× 8 TB drives): **roughly $400–$500**
- Synology DS224+ + 2× 8 TB drives: **roughly $900–$1,100**

Plus you own the whole stack. No proprietary OS, no per-app licensing, no surprise EOL.

---

## Network Addresses

You'll see two IPs throughout this guide. Keep them straight:

| Access Type | Address (example) | When to Use |
|---|---|---|
| Local network | `192.168.1.25` | On home Wi-Fi or wired LAN |
| Remote / VPN | `100.115.3.97` (Tailscale) | Anywhere outside the home network |

Substitute your own values once you've completed the relevant steps.

---

## Bill of Materials

| Item | Notes |
|---|---|
| HP Mini PC (any recent 8th-gen Intel or newer) | Used on eBay for $150–$250. Needs at least 8 GB RAM and a 256 GB internal SSD. |
| TerraMaster D2-310 (2-bay USB-C DAS) | Or any USB-C DAS that supports JBOD/raw passthrough. Avoid hardware-RAID enclosures — we want the drives raw. |
| 2× HDDs of matching capacity | 8 TB or larger, NAS-grade (WD Red Plus, Seagate IronWolf). Two identical drives. |
| USB-C cable | A spare is worth keeping on hand — it's the single point of failure between server and storage. |
| Ethernet cable | Wired connection strongly preferred for a NAS. |

You'll also need a Plex account (free), a Tailscale account (free for up to 100 devices), and a Gmail account (for SMART email alerts).

---

## Architecture at a Glance

```
[ Phones / TVs / Laptops ]
            │
            ├── Local LAN ────┐
            │                 │
            └── Tailscale ────┤
                              ▼
                      ┌─────────────────┐
                      │   HP Mini       │
                      │   Debian 13     │
                      │                 │
                      │  ┌───────────┐  │
                      │  │  Docker   │  │
                      │  │   Plex    │  │
                      │  └───────────┘  │
                      │  Native Samba   │
                      │  Tailscale      │
                      │  smartd         │
                      └────────┬────────┘
                               │ USB-C
                               ▼
                      ┌─────────────────┐
                      │  TerraMaster    │
                      │  ├─ Drive 1     │  RAID 1
                      │  └─ Drive 2     │  (mirror)
                      └─────────────────┘
```

The HP Mini does all compute. The TerraMaster is dumb storage — Linux's `mdadm` handles the RAID in software.

---

## 1. Initial Debian Setup

This guide assumes a fresh Debian 13 ("Trixie") install on the HP Mini. The Debian installer is straightforward — pick a hostname (mine is `greer`), create your user account (mine is `agreer`), select GNOME or no desktop, and install. Use a wired ethernet connection from the start.

After first boot, log in and open a terminal.

### 1.1 Connect to the network

If you used wired ethernet during install, you're already online. Confirm:

```bash
ping -c 3 8.8.8.8
```

If that fails, your network interface isn't up:

```bash
ip link show
```

For Wi-Fi, run `nmtui` for a text-based network manager.

If `ping 8.8.8.8` works but `apt update` fails to resolve hostnames, it's a DNS issue. Add a public resolver:

```bash
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
```

### 1.2 Add your user to sudo

If `sudo` isn't working for your user, you need to add it to the `sudo` group. Switch to root:

```bash
su -
```

Enter the root password, then:

```bash
usermod -aG sudo agreer
exit
```

**Fully log out** of your desktop session and log back in (a new terminal isn't enough — the group membership only refreshes on a new login session). Then test:

```bash
sudo whoami
```

It should print `root`.

If for any reason group membership still doesn't take, edit sudoers directly — but use **`visudo`**, never `nano`:

```bash
sudo visudo
```

Find the line `root ALL=(ALL:ALL) ALL` and add this line directly below:

```
agreer ALL=(ALL:ALL) ALL
```

> **Why `visudo` and not `nano`?** A typo in `/etc/sudoers` locks you out of `sudo` completely — recovery requires booting into rescue mode. `visudo` syntax-checks the file before saving and refuses to write a broken config.

### 1.3 Update the system

```bash
sudo apt update
sudo apt upgrade -y
```

---

## 2. Set Up RAID 1 with mdadm

Connect the TerraMaster via USB-C and turn it on. The enclosure has its own power supply — USB-C alone won't power it.

### 2.1 Verify the drives are detected

```bash
lsblk
```

You should see your two new drives — typically `sda` and `sdb` if your HP's internal storage is NVMe (`nvme0n1`). They should each show their full capacity (e.g. 7.3 T for 8 TB drives) and have no partitions.

If they don't show up:

- Check the enclosure power light is on
- Try a different USB-C port on the HP (some are data-only)
- Run `dmesg | tail -20` right after plugging the cable — it'll show the kernel's view of the device
- Reseat both drives in the enclosure

### 2.2 Install mdadm

```bash
sudo apt install -y mdadm
```

### 2.3 Create the RAID 1 array

```bash
sudo mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sda /dev/sdb
```

It will warn that the drives have no partitions and ask to confirm — type `y` and hit Enter. The array starts syncing in the background. With 8 TB drives, the initial sync takes several hours — but you can format and use the array immediately. Sync progress:

```bash
cat /proc/mdstat
```

### 2.4 Format with ext4 and mount

```bash
sudo mkfs.ext4 /dev/md0
sudo mkdir /mnt/nas
sudo mount /dev/md0 /mnt/nas
```

### 2.5 Make the array survive reboots

Save the RAID config so the kernel reassembles `md0` on boot:

```bash
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u
```

Then add an `/etc/fstab` entry for auto-mount:

```bash
echo '/dev/md0 /mnt/nas ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

Reboot once and confirm `/mnt/nas` is mounted automatically:

```bash
sudo reboot
# after reboot:
df -h | grep nas
```

---

## 3. Folder Structure

This guide uses four NAS users (`adam`, `amanda`, `ava`, `leslie`) — substitute your own family/household members. The structure:

```
/mnt/nas/
├── media/
│   ├── movies/
│   ├── tv/
│   ├── music/
│   └── photos/
├── backups/
│   ├── adam/
│   ├── amanda/
│   ├── ava/
│   └── leslie/
├── shared/
└── plex/
    └── config/
```

Create it:

```bash
sudo chown -R agreer:agreer /mnt/nas
mkdir -p /mnt/nas/media/{movies,tv,music,photos}
mkdir -p /mnt/nas/backups/{adam,amanda,ava,leslie}
mkdir -p /mnt/nas/shared
mkdir -p /mnt/nas/plex/config
```

> **Why this layout?** `media/` is read-shared with everyone for Plex. Each user gets a private `backups/` folder for phone/laptop backups. `shared/` is for files everyone needs to read and write. `plex/config/` holds Plex's database — keeping it on the RAID array means it survives an HP failure without losing your library metadata.

---

## 4. Install Docker

Plex runs in Docker. Samba runs natively (covered in section 6).

```bash
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker agreer
```

**Fully log out and log back in**, then verify:

```bash
docker run hello-world
```

If Docker can't reach `ghcr.io` or `docker.io` to pull images, set its DNS resolver:

```bash
sudo nano /etc/docker/daemon.json
```

Add:

```json
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
```

Save (Ctrl+O, Enter, Ctrl+X), then restart Docker:

```bash
sudo systemctl restart docker
```

---

## 5. Install Plex (Docker)

### 5.1 Create the docker-compose file

```bash
mkdir -p /home/agreer/docker
nano /home/agreer/docker/docker-compose.yml
```

Paste in:

```yaml
services:
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    ports:
      - 32400:32400
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Chicago
      - VERSION=docker
      # Get a fresh token from https://plex.tv/claim — expires in 4 minutes.
      # Remove this line entirely after the server has been claimed once.
      - PLEX_CLAIM=<paste-your-token-here>
    volumes:
      - /mnt/nas/plex/config:/config
      - /mnt/nas/media:/media
    restart: unless-stopped
```

Save (Ctrl+O, Enter, Ctrl+X).

> **About `PUID=1000` and `PGID=1000`:** This makes the container run as your `agreer` user (UID 1000), so files Plex writes are owned by you and write back cleanly to `/mnt/nas`. Confirm your user's IDs match with `id agreer` — if they don't, change PUID/PGID accordingly.
>
> **About the `PLEX_CLAIM` token:** Get a fresh token from `https://plex.tv/claim` immediately before starting the container. The token expires in 4 minutes. After the server is claimed, you can remove the `PLEX_CLAIM` line entirely.

### 5.2 Start Plex

Get your claim token from `https://plex.tv/claim`, paste it into the compose file replacing `<paste-your-token-here>`, save, and start:

```bash
cd /home/agreer/docker
docker compose up -d
```

Watch the logs to confirm a successful claim:

```bash
docker logs plex --tail 30
```

Look for `Server claimed successfully`.

### 5.3 Find your HP's local IP

```bash
ip addr show | grep "inet "
```

Look for an address like `192.168.1.25`. Set this as a DHCP reservation in your router so it never changes.

### 5.4 Complete the Plex setup wizard

On any device on your home network, open:

```
http://<your-hp-ip>:32400/web
```

(e.g. `http://192.168.1.25:32400/web`)

Sign in with your Plex account and add libraries:

- **Movies** → `/media/movies`
- **TV Shows** → `/media/tv`
- **Music** → `/media/music`
- **Photos** → `/media/photos`

> **About the SSL warning:** When you access Plex from a phone or other device, you may see "connection is not private." This is normal — Plex uses a self-signed certificate on the local network. On iOS Safari: tap "Show Details" → "visit this website." On Android Chrome: "Advanced" → "Proceed."

### 5.5 Naming media for Plex

Plex matches metadata based on filenames:

- **Movies:** `Movie Name (2024).mp4`
- **TV Shows:** `Show Name/Season 01/Show Name S01E01.mp4`
- **Music:** organized by artist/album folders

Rename before copying to save Plex from guessing.

---

## 6. Install Samba (Native)

> **Why native instead of Docker?** Earlier versions of this build used the `dperson/samba` Docker image. That image has been unmaintained since ~2020 and has unpatched CVEs. Native Samba on Debian is simpler, removes a container from the stack, and puts share configuration in one readable file (`/etc/samba/smb.conf`).

### 6.1 Install

```bash
sudo apt install -y samba samba-common-bin
```

### 6.2 Create users

For each NAS user, create a system user with no shell login, then set a Samba password:

```bash
sudo useradd -M -s /usr/sbin/nologin adam
sudo smbpasswd -a adam
```

Repeat for `amanda`, `ava`, `leslie` (or whatever names you're using).

### 6.3 Configure shares

Edit `/etc/samba/smb.conf`:

```bash
sudo nano /etc/samba/smb.conf
```

Append at the bottom:

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
   path = /mnt/nas/backups/adam
   browseable = yes
   read only = no
   valid users = adam
   create mask = 0664
   directory mask = 0775

[amanda]
   path = /mnt/nas/backups/amanda
   browseable = yes
   read only = no
   valid users = amanda
   create mask = 0664
   directory mask = 0775

[ava]
   path = /mnt/nas/backups/ava
   browseable = yes
   read only = no
   valid users = ava
   create mask = 0664
   directory mask = 0775

[leslie]
   path = /mnt/nas/backups/leslie
   browseable = yes
   read only = no
   valid users = leslie
   create mask = 0664
   directory mask = 0775
```

### 6.4 Set ownership on the shared folders

```bash
sudo chown -R agreer:agreer /mnt/nas/media
sudo chmod -R 775 /mnt/nas/media

sudo chown adam:adam /mnt/nas/backups/adam
sudo chown amanda:amanda /mnt/nas/backups/amanda
sudo chown ava:ava /mnt/nas/backups/ava
sudo chown leslie:leslie /mnt/nas/backups/leslie
sudo chmod 700 /mnt/nas/backups/*
```

The `media` directory is group-writable for the family. Each user's backup folder is private to them (`700`).

### 6.5 Validate config and start the service

```bash
sudo testparm                          # syntax-check smb.conf
sudo systemctl restart smbd nmbd
sudo systemctl enable smbd nmbd        # auto-start on boot
```

### 6.6 Connect from a Mac

In Finder, press **Cmd+K**, then enter:

```
smb://192.168.1.25
```

Click Connect, enter the appropriate username and password, and select the share.

To connect directly to a specific share (skipping the picker):

```
smb://192.168.1.25/media
```

### 6.7 Connect from Windows

In File Explorer, type into the address bar:

```
\\192.168.1.25\media
```

Enter credentials when prompted.

### 6.8 iPhone / iPad notes

Apple's built-in **Files** app connects to SMB shares but writes are unreliable and often appear read-only. For active mobile use:

- **Plex Camera Upload** (in the Plex iOS app) — automatic photo backup to `/mnt/nas/media/photos`. Already installed, no extra apps.
- **FE File Explorer** or **FileBrowser** (iOS App Store) — third-party file managers that handle SMB write properly.

---

## 7. Install Tailscale

Tailscale gives you secure remote access from anywhere without exposing the NAS to the internet. Free for up to 100 devices.

### 7.1 Sign up

Create a free account at `tailscale.com` (sign in with Google or Microsoft works fine — no new password required).

### 7.2 Install on the HP

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

It prints a URL. Open it on any browser, sign in with your Tailscale account, and approve the device.

Find the Tailscale IP:

```bash
tailscale ip -4
```

You'll get something like `100.115.3.97`. This IP is permanent for this device.

### 7.3 Advertise your home subnet

This lets all your other Tailscale-connected devices reach your home network through the HP, including Plex's auto-discovery:

```bash
sudo tailscale up --advertise-routes=192.168.1.0/24
```

If the command warns about IP forwarding, enable it:

```bash
sudo sysctl -w net.ipv6.conf.all.forwarding=1
sudo apt install -y ethtool
sudo ethtool -K eno1 rx-udp-gro-forwarding on rx-gro-list off
```

(Replace `eno1` with your actual interface name from `ip link show` if different.)

Then **approve the subnet route** in the Tailscale admin:

1. Go to `tailscale.com/admin`
2. Find your HP in the device list
3. Click the three dots → **Edit route settings**
4. Enable `192.168.1.0/24`
5. Save

### 7.4 Install Tailscale on phones / laptops

Get the Tailscale app for iOS, Android, macOS, or Windows. Sign in with the same account. The HP will appear in your Tailscale device list; you can now reach it at its `100.x.x.x` IP from anywhere.

> **Pro tip for iOS:** Settings → Tailscale → VPN → set to **Connect on Demand** so it stays connected automatically.

---

## 8. Plex Remote Access (Orbi Port Forwarding)

Tailscale is great for personal remote access. But if you want to share your Plex library with friends or family who **don't have Tailscale**, Plex needs a direct path from the internet to your server. This means port forwarding on your router.

> **Why?** Without port forwarding, Plex falls back to its own relay server, which is throttled to **2 Mbps per stream** — unwatchable above 480p.

### 8.1 Forward port 32400 on your Orbi

1. Log into the Orbi admin: `http://orbilogin.com` (or `http://192.168.1.1`)
   - Default username: `admin`
   - Default password: usually `password`, or check the sticker on the bottom of the router
2. Go to **Advanced → Advanced Setup → Port Forwarding / Port Triggering**
3. Click **Add Custom Service**
4. Fill in:
   - **Service Name:** `Plex`
   - **Service Type:** `TCP`
   - **External Starting Port:** `32400`
   - **External Ending Port:** `32400`
   - **Internal IP Address:** `192.168.1.25`
   - **Internal Starting Port:** `32400`
   - **Internal Ending Port:** `32400`
5. Click **Apply**

Other routers (Eero, ASUS, UniFi, etc.) work the same way — find the port-forwarding section and forward TCP 32400 to your HP's local IP.

### 8.2 Verify in Plex

Open Plex Web on the HP at `http://localhost:32400/web` and go to **Settings → Remote Access**.

You should see, in green: **"Fully accessible outside your network."**

If it still complains, check the **"Manually specify public port"** box and set it to `32400`.

---

## 9. Drive Health Monitoring (smartmontools)

Set up daily SMART tests with email alerts so you get warned before a drive fails.

### 9.1 Install smartmontools

```bash
sudo apt install -y smartmontools
```

### 9.2 Run a quick health check

```bash
sudo smartctl -H /dev/sda
sudo smartctl -H /dev/sdb
```

Both should report `PASSED`.

Run a short self-test (takes about 2 minutes):

```bash
sudo smartctl -t short /dev/sda
sudo smartctl -t short /dev/sdb
```

After 2 minutes, check results:

```bash
sudo smartctl -l selftest /dev/sda
sudo smartctl -l selftest /dev/sdb
```

### 9.3 Configure automatic monitoring

```bash
sudo nano /etc/smartd.conf
```

Comment out the existing `DEVICESCAN` line by adding `#` to the start. Then add at the bottom:

```
/dev/sda -a -o on -S on -s (S/../.././02|L/../../6/03) -m agreer26@gmail.com -M exec /usr/share/smartmontools/smartd-runner
/dev/sdb -a -o on -S on -s (S/../.././02|L/../../6/03) -m agreer26@gmail.com -M exec /usr/share/smartmontools/smartd-runner
```

Replace `agreer26@gmail.com` with your email. This schedules:

- A **short test every day at 2 AM**
- A **long test every Saturday at 3 AM**
- An email if anything fails

### 9.4 Set up Gmail to send alerts

Install the mail tools:

```bash
sudo apt install -y ssmtp mailutils
```

You'll need a **Gmail App Password** (regular Gmail passwords don't work for SMTP):

1. Go to `myaccount.google.com → Security`
2. Enable **2-Step Verification** if not already on
3. Click **App Passwords**, create one named "NAS"
4. Copy the 16-character password Google generates

Configure ssmtp:

```bash
sudo nano /etc/ssmtp/ssmtp.conf
```

Replace everything with:

```
root=agreer26@gmail.com
mailhub=smtp.gmail.com:587
AuthUser=agreer26@gmail.com
AuthPass=<paste-your-16-char-app-password-here>
UseTLS=YES
UseSTARTTLS=YES
hostname=greer
```

Test:

```bash
echo "Test from NAS" | mail -s "NAS Test Email" agreer26@gmail.com
```

Check your Gmail. If it arrived, you're set.

### 9.5 Enable the smartd service

```bash
sudo systemctl enable smartd
sudo systemctl start smartd
sudo systemctl status smartd
```

Press `q` to exit the status view.

If `enable` fails with "Unit smartd.service does not exist," create the unit file manually:

```bash
sudo nano /etc/systemd/system/smartd.service
```

Paste:

```ini
[Unit]
Description=Self Monitoring and Reporting Technology (SMART) Daemon
After=network.target

[Service]
ExecStart=/usr/sbin/smartd -n
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable smartd
sudo systemctl start smartd
```

---

## 10. Bonus: NAS Transfer Droplet (macOS)

A drag-and-drop AppleScript that `rsync`s files to the `media` share. Drop files or folders on the app icon → Terminal opens with progress → notification when done.

> **Why a droplet?** Finder's SMB transfer throws error `-8062` on large transfers (>4 GB or many files at once). `rsync` handles them reliably. The droplet wraps the `rsync` command so you don't have to type it every time.

### 10.1 Requirements

- macOS with Script Editor (built-in)
- Homebrew rsync — Apple's bundled `openrsync` has SMB bugs on macOS Tahoe:

```bash
brew install rsync
```

### 10.2 Build the droplet

1. Open **Script Editor** (Applications → Utilities)
2. **File → New**
3. Paste the contents of `NAS_Transfer.applescript` (included with this guide bundle)
4. **File → Export…**
   - **File Format:** Application
   - **Save As:** `NAS Transfer.app`
   - **Where:** Applications folder
5. Drag the resulting `.app` to your Dock

### 10.3 Use it

- Drag any file or folder onto the **NAS Transfer.app** icon
- A Terminal window opens showing `rsync` progress
- A macOS notification appears when complete

The droplet auto-mounts the `media` share if not mounted, excludes macOS metadata (`.DS_Store`, `._*`, `.Spotlight-V100`, `.Trashes`), and copies (doesn't move) files.

To target a different share (e.g. `adam`), edit the `shareName` property at the top of the script and re-export.

---

## 11. Troubleshooting & Reference

### Network / DNS issues

If `apt update` fails to reach `deb.debian.org`:

```bash
ping -c 3 8.8.8.8                 # is the network up at all?
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf   # if ping works but DNS doesn't
```

For Docker pull failures (`denied from ghcr.io`), set Docker's DNS in `/etc/docker/daemon.json` (see section 4).

### Sudo lockout

If a typo in `/etc/sudoers` locks you out: reboot, hold Shift to enter the GRUB menu, choose "Advanced options for Debian," select recovery mode, and edit sudoers as root from the rescue shell. Always use `visudo` to prevent this in the first place.

### GRUB rescue boot recovery

If an unclean shutdown drops you into a `grub rescue>` prompt, type:

```
normal
```

If that doesn't bring up the boot menu, manually boot:

```
set root=(hd0,gpt2)
linux /vmlinuz root=/dev/nvme0n1p2 ro
initrd /initrd.img
boot
```

(`gpt2` and `nvme0n1p2` are the typical Debian root partition; adjust if your install differs.)

### Samba write permissions broken

If users can read but not write to shares after a reboot:

```bash
# Quick fix (world-writable — fine for a home NAS with no public exposure):
sudo chmod -R 777 /mnt/nas

# Better fix (owner+group writable, others read-only):
sudo chown -R agreer:agreer /mnt/nas
sudo chmod -R 775 /mnt/nas
```

### Mac Finder error `-8062` on large transfers

This is a Finder SMB bug, not a server problem. Use `rsync` from Terminal:

```bash
rsync -avh --progress --exclude='.DS_Store' \
  "/path/to/source/" \
  "/Volumes/media/destination/"
```

The trailing slash on the source matters — it copies the contents of the source folder rather than the folder itself.

Or just use the **NAS Transfer Droplet** from section 10.

### Plex shows offline in the app but works in browser

Almost always Tailscale isn't connected on the device, or Plex's relay can't reach the server.

Checklist:

1. Open the Tailscale app on the device — confirm green/connected status
2. On iOS: Settings → Tailscale → VPN → enable **Connect on Demand**
3. Confirm port forwarding is active (section 8) — this enables Plex's own relay
4. On the HP: `sudo tailscale status` — confirm both the server and the client device show as connected
5. Force-close and reopen the Plex app
6. As a last resort, sign out of the Plex app and sign back in

### Containers don't restart after reboot

The compose file uses `restart: unless-stopped`, so containers should come back automatically. If they don't:

```bash
cd /home/agreer/docker
docker compose up -d
```

### RAID array not mounted after reboot

```bash
ls /mnt/nas      # if empty, the array didn't mount
sudo mount /dev/md0 /mnt/nas
```

If this happens repeatedly, double-check the `/etc/fstab` entry and that `mdadm.conf` includes the array (section 2.5).

---

## 12. Quick Reference

### Network addresses

| Access Type | Address | When to Use |
|---|---|---|
| Local network | `192.168.1.25` | Home Wi-Fi or LAN |
| Remote / VPN | `100.115.3.97` (Tailscale) | Anywhere outside the home network |

### Common paths

| Path | What |
|---|---|
| `/mnt/nas` | RAID 1 mount point |
| `/mnt/nas/media` | Plex media root (movies, tv, music, photos) |
| `/mnt/nas/backups/<user>` | Per-user private backup folder |
| `/mnt/nas/plex/config` | Plex database and metadata |
| `/home/agreer/docker/docker-compose.yml` | Plex compose file |
| `/etc/samba/smb.conf` | Samba share config |
| `/etc/smartd.conf` | Drive health monitoring config |
| `/etc/ssmtp/ssmtp.conf` | Outgoing mail config |

### Common commands

| Task | Command |
|---|---|
| Check RAID status | `cat /proc/mdstat` |
| Drive health (quick) | `sudo smartctl -H /dev/sda` |
| Drive health (full) | `sudo smartctl -a /dev/sda` |
| List Docker containers | `docker ps` |
| Restart Plex | `cd ~/docker && docker compose restart plex` |
| Restart Samba | `sudo systemctl restart smbd nmbd` |
| Tailscale status | `sudo tailscale status` |
| Tailscale IP | `tailscale ip -4` |
| Test mail | `echo "test" \| mail -s "test" you@gmail.com` |
| View Plex logs | `docker logs plex --tail 50` |
| Fix permissions (nuclear) | `sudo chmod -R 777 /mnt/nas` |

### Connecting from clients

| Client | Address |
|---|---|
| Mac (Finder) | `Cmd+K → smb://192.168.1.25` |
| Mac, direct share | `smb://192.168.1.25/media` |
| Windows | `\\192.168.1.25\media` |
| Plex Web (local) | `http://192.168.1.25:32400/web` |
| Plex Web (remote, Tailscale) | `http://100.115.3.97:32400/web` |

---

## What's Next

You've built it. From here:

- **Add media** to `/mnt/nas/media/` (use the NAS Transfer droplet or `rsync`)
- **Set up Plex Camera Upload** on each phone (Plex iOS app → Settings → Camera Upload)
- **Install Tailscale** on every device that needs remote access
- **Replace temporary Samba passwords** with strong ones using `sudo smbpasswd <user>`
- **Schedule a monthly check** of `cat /proc/mdstat` and `sudo smartctl -H /dev/sda` — drive failure is when, not if

Enjoy your NAS.
