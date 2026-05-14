# Gumroad Listing — HomeNAS Setup Guide

Draft copy for the Gumroad product page. Fields below map 1:1 to Gumroad's product form. Two voice options are offered for the title and tagline — pick one, delete the other.

---

## Product name (max ~60 chars)

**Option A (recommended — direct):**
> Build a Home NAS: The Synology Alternative

**Option B (cost-led):**
> The $500 Home NAS: Skip the Synology Tax

---

## Tagline / subtitle (Gumroad shows under the title)

**Option A:**
> A battle-tested recipe for a 14 TB Plex + file-share NAS — for half the cost of a Synology DS224+.

**Option B:**
> Used HP Mini + TerraMaster + Debian + RAID 1. Roughly $500 all in. No proprietary OS, no licensing surprises.

---

## Hero description (the first paragraph buyers see)

You can build a better NAS than the Synology DS224+ for roughly half the price — and the only thing standing between you and that is a weekend of clear instructions.

This is the recipe I used to build mine: an HP Mini running Debian 13, two NAS-grade drives in software RAID 1 inside a TerraMaster USB-C enclosure, Plex for media, Samba for the family file shares, Tailscale for secure remote access, and Smartmontools watching the drives.

No subscription. No proprietary firmware that goes end-of-life on a vendor's schedule. No surprise paywalls on the apps that ship "free" with a Synology and then aren't. You own the whole stack.

---

## What's included

- **HomeNAS Setup Guide** — 70+ page step-by-step PDF, every command shown in full, every config file explained.
- **Drop-in bonus pack** with the configs and helpers I use on mine:
  - Plex `docker-compose.yml`
  - Samba `smb.conf` with per-user shares
  - Smartmontools `smartd.conf` for daily/weekly health tests
  - `msmtprc` template for Gmail alerts
  - Tailscale persistent IP-forwarding and ethtool systemd unit
  - **macOS** drag-and-drop NAS transfer droplet (AppleScript)
  - **Windows** drag-and-drop Robocopy transfer script
- **Bill of materials** with exact part recommendations and price ranges.
- **Threat model + backup chapter** — RAID is not a backup. Cloud and rotated-external-drive workflows included.

---

## What you'll have at the end

- A 14 TB redundant NAS (either drive can fail with zero data loss)
- Plex streaming to phones, TVs, laptops — on your network and remotely
- Per-user Samba file shares for the whole household
- Secure remote access from anywhere via Tailscale (no exposed ports)
- Daily drive-health monitoring with email alerts
- A working offsite backup plan

All for **roughly $450–$650 in hardware**, depending on used-HP pricing. A Synology DS224+ with the same 14 TB usable is closer to $1,000.

---

## Who this is for

- Anyone who's been pricing Synology and balked.
- DIYers comfortable copy-pasting shell commands. (No prior Linux expertise required — every step is shown.)
- Households who want their photos, media, and backups under their own roof.
- Plex users who want hardware-acceleration without a black-box appliance.

---

## Who this is **not** for

- People who want a one-click NAS appliance with a polished GUI. Buy a Synology — it's the right product for that need.
- Total beginners who've never opened a terminal. This guide assumes you can paste commands and read error messages. It's friendly, but it's not hand-holding.
- People who consider self-hosting itself a hobby rather than a means to an end. This is the shortest path to a working NAS, not a tour of every alternative.

---

## Tech stack

Debian 13 · `mdadm` software RAID 1 · Docker (Plex via linuxserver.io) · native Samba 4 · Tailscale (free tier) · Smartmontools + msmtp · ext4. Everything is mainline upstream — no proprietary forks.

---

## FAQ

**How long does the build take?**
A weekend. ~2 hours of hands-on work spread over the RAID sync (which takes 6–10 hours in the background but doesn't block anything).

**Do I need to know Linux?**
No. You need to be comfortable opening a terminal and pasting commands. Every command and every config is shown explicitly. Common errors are anticipated with troubleshooting steps.

**What if a drive dies?**
RAID 1 keeps the array running on the surviving drive until you replace the failed one. The guide walks through monitoring (so you find out before it's urgent) and replacement (which is undramatic). Section 13 covers what RAID *doesn't* protect against and how to set up real backups.

**Does the HP Mini transcode 4K Plex streams?**
Yes — 8th-gen Intel iGPU handles hardware-accelerated transcoding for several simultaneous streams when paired with Plex Pass (covered in §5.6). Plex Pass is not required to follow the guide but unlocks the transcoding wins.

**Can I use different hardware?**
Yes. The HP Mini is a convenient cheap server, not a requirement. Any small Linux-capable machine with USB-C works. The guide notes substitution points throughout.

**Is this just a glorified blog post?**
No. It's a complete, tested, sanitized walkthrough — every command, every config, every gotcha. Plus the bonus pack saves you typing out long configs. If you only need quick pointers, free blog posts cover the topic. This is for people who want the full recipe in one place.

**What's your refund policy?**
30-day no-questions refunds if you're not satisfied. Email me and I'll process it.

**Will this work on (other distro / Raspberry Pi / etc.)?**
The exact commands are Debian 13 — paste-ready. Most translate cleanly to Ubuntu LTS. Raspberry Pi works for Samba + Tailscale but the iGPU transcoding story changes. The architecture (RAID 1 + Docker + Samba + Tailscale + smartmontools) is platform-agnostic.

**Does the price ever change?**
Launch price is locked in for the first 100 buyers. After that I may raise to $29 as I add the YouTube walkthrough bundle.

---

## Pricing

| Tier | Price | What you get |
|---|---|---|
| **Guide + Bonus Pack** | **$19** (launch) / $29 (regular) | The full PDF + drop-in configs + helper scripts |
| **Guide + YouTube Walkthrough** (future) | $29 / $39 | Above + a full video walkthrough following the same chapters |

The bundle tier is a placeholder until the YouTube walkthrough exists. Don't list it yet — just the $19 launch tier.

---

## Cover image

Use `cover.png` (already in the repo). 1500×1500 minimum on Gumroad; scale if needed.

---

## Tags (Gumroad searchability)

`nas`, `plex`, `synology alternative`, `homelab`, `home server`, `debian`, `raid`, `tailscale`, `self hosted`, `selfhosted`, `docker`, `media server`, `smb`, `samba`, `usb-c nas`, `terramaster`, `hp mini`, `diy nas`

---

## Author note (optional — Gumroad supports an "About the creator" block)

I'm a software engineer who got tired of paying the Synology premium and wanted a NAS I could actually understand, repair, and outlive any one vendor. I built this exact setup in my home, ran it for [X months/years], debugged it through the typical homelab teething, and turned the notes into this guide. Every command in the PDF is one I ran on my own machine. If you hit something the guide doesn't cover, email me — I read everything.

---

## Pre-launch checklist (for the author)

- [ ] Final PDF review — read it cover-to-cover one more time
- [ ] Run `make zip` and inspect the bundle (PDF + bonus/ folder, no junk)
- [ ] Set up Gumroad account, verify payout method
- [ ] Upload cover image (cover.png)
- [ ] Paste this listing copy (pick voice options)
- [ ] Set launch price to $19, schedule increase to $29 after first 100 sales
- [ ] Enable Gumroad's "ratings" widget
- [ ] Test buying flow with a $0 discount code (sanity check the download)
- [ ] Carrd landing page live and pointed at Gumroad URL
- [ ] First social post: r/selfhosted, r/homelab, r/DataHoarder, r/PleX, HN Show
