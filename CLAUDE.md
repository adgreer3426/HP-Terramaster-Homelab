# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a documentation/configuration repository for a home NAS and media server setup. There is no application code to build or test — the repo tracks setup notes and configurations for a homelab running on an HP Mini (Debian 13) with a TerraMaster 2-bay USB-C enclosure.

## Architecture Overview

**Hardware:**
- HP Mini running Debian 13 as the server
- TerraMaster 2-bay enclosure (USB-C) with two 7.3TB drives in software RAID 1 via `mdadm`
- RAID array mounted at `/mnt/nas`, auto-mounts on boot

**Services (all run via Docker / Docker Compose):**
- **Plex** — media server, remote access via port 32400 (forwarded on Orbi router)
- **Samba** — network file sharing with five shares: `media`, `adam`, `amanda`, `ava`, `leslie` (each user has their own password)
- **Tailscale** — VPN for secure remote access; server IP is `100.115.3.97`
- **Smartmontools** — drive health monitoring; short SMART tests daily, long tests weekly; alerts email to `agreer26@gmail.com`

## Key Operational Notes

- Use `rsync` for large file transfers — Finder throws error `-8062` on large transfers
- If permissions break on the NAS: `sudo chmod -R 777 /mnt/nas`
- Tailscale IP for the HP server: `100.115.3.97`
- Plex port: `32400`
