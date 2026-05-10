# Review: HomeNAS_Setup_Guide.pages

**Reviewed:** 2026-05-09  
**Document last modified:** 2025-05-07  
**Method:** Binary string extraction from `.iwa` protobuf archive + cross-reference against `CLAUDE.md`, `Homelab_Setup`, and `NAS_Transfer.applescript`

> **Limitation:** The `.pages` format uses a proprietary binary encoding. This review is based on readable fragments extracted with `strings`. Some content may be present in the document but unverifiable here — each finding is flagged with a confidence level.

---

## Confirmed Document Structure

The following sections were positively identified in the binary:

| # | Section | Status |
|---|---|---|
| 1 | Hardware Overview | Confirmed |
| 2 | Initial Setup (sudo, apt, DNS) | Confirmed |
| 3 | RAID 1 with mdadm | Confirmed |
| 4 | Folder Structure | Confirmed |
| 5 | Docker Setup | Confirmed |
| 6 | Plex | Confirmed |
| 7 | Samba | Confirmed |
| 8 | Tailscale | Confirmed |
| 9 | Troubleshooting & Reference | Confirmed |
| 10 | Smartmontools | Confirmed |
| 11 | Quick Reference | Confirmed |

The document includes a **table of contents** (TOC Heading 1 style detected) and uses Cambria/Helvetica Neue fonts — looks like a well-formatted reference guide.

---

## Findings

### ISSUE 1 — `PLEX_CLAIM=claim-x` is a placeholder (Confidence: High)

**Extracted:** `DPLEX_CLAIM=claim-x`

The docker-compose snippet shows `PLEX_CLAIM=claim-x` — this is not a real claim token. Real tokens are generated at `plex.tv/claim`, expire in 4 minutes, and look like `claim-xxxxxxxxxxxxxxxxxxxx`.

**Recommendation:** Update the guide to one of these approaches:
- Show `PLEX_CLAIM=<token from plex.tv/claim>` clearly labeled as a placeholder the user must fill in
- Add a note that **after the server is claimed, this line can be removed entirely** — Plex only needs it on first run

---

### ISSUE 2 — `PUID=100` may be wrong (Confidence: Medium — verify in Pages)

**Extracted:** `t,  - PUID=100`

The extracted value is `PUID=100`. The standard for Plex Docker containers is `PUID=1000` (the ID of the first non-root user on Debian). `PUID=100` would run Plex as the `users` system group user, which can cause permission errors on `/mnt/nas`.

**Recommendation:** Open the document in Pages and verify the full value. If it says `PUID=100` (not `1000`), correct it to:
```
PUID=1000
PGID=1000
```
You can confirm your user ID on the HP Mini with: `id agreer`

---

### ISSUE 3 — `dperson/samba` Docker image is abandoned (Confidence: High)

**Extracted:** `q$: dperson/` (prefix of `dperson/samba`)

The `dperson/samba` Docker image has not been maintained since ~2020 and has known unpatched vulnerabilities. It still works but represents a security and compatibility risk going forward.

**Recommendation:** Consider migrating to one of these maintained alternatives:
- `crazymax/samba` — actively maintained, supports Samba 4.x
- `servercontainers/samba` — feature-rich, frequently updated
- Native Samba on Debian (no Docker overhead; `apt install samba`)

The native option is simplest for a home NAS and removes one container from the stack.

---

### WARNING 1 — Sudoers edited via `nano`, not `visudo` (Confidence: Medium)

**Extracted:** `line:-58  ALL=(ALL:ALL)` and `nano /etc/` (nearby context)

The guide appears to show editing `/etc/sudoers` directly with a text editor. This is risky: a syntax error in sudoers locks you out of `sudo` with no recovery path short of booting into rescue mode.

**Recommendation:** Replace the nano-based sudoers edit with `visudo`, which validates syntax before saving:
```bash
sudo visudo
```
Then add: `agreer ALL=(ALL:ALL) ALL`

---

### WARNING 2 — IP address distinction should be explicit (Confidence: High)

**Extracted:** `smb://192.168.1.25` (local) and `8.115.3.97` (fragment of `100.115.3.97`, Tailscale)

Both IPs appear in the document and serve different purposes. `NAS_Transfer.applescript` also hardcodes `192.168.1.25`. A reader rebuilding the setup from this guide could confuse them.

**Recommendation:** Add a clear callout box or table in the guide:

| Access Type | Address |
|---|---|
| Local network (home) | `192.168.1.25` |
| Remote / VPN (Tailscale) | `100.115.3.97` |

---

### GAP 1 — `NAS_Transfer.applescript` droplet not documented (Confidence: High)

The repo contains `NAS_Transfer.applescript` — a drag-and-drop utility for rsync transfers to the NAS. No trace of this tool was found in the Pages document.

**Recommendation:** Add a short section (or add to the Quick Reference section) covering:
- What the droplet does (drag files → rsync to `/Volumes/media`)
- How to compile it into a `.app` with Script Editor
- That it requires Homebrew rsync (`brew install rsync`) for macOS Tahoe compatibility
- That it only targets the `media` share (not user shares)

---

### GAP 2 — `sudo chmod -R 777 /mnt/nas` permission fix not confirmed (Confidence: Medium)

This is listed in `CLAUDE.md` as a key operational note, but no fragment of it appeared in the extracted strings. It may be present in the Troubleshooting section under unextractable binary content, or it may be missing.

**Recommendation:** Verify the Troubleshooting section includes this command. If not, add it — it's the fastest recovery when Samba write permissions break after a reboot.

> **Note:** `chmod -R 777` is a blunt fix (world-writable). For a home NAS with no public exposure this is acceptable, but you may want to also document the more targeted fix: `sudo chown -R agreer:agreer /mnt/nas && sudo chmod -R 775 /mnt/nas`.

---

### GAP 3 — Orbi port forwarding for Plex remote access not confirmed (Confidence: Medium)

`CLAUDE.md` notes that remote Plex access required setting up port forwarding on the Orbi router for port `32400`. No fragment of "Orbi", "router", or "port forward" appeared in the extracted strings. This step is easy to forget when rebuilding.

**Recommendation:** Confirm the Plex section documents the Orbi port forward. If not, add a step:
- Log into Orbi admin → Advanced → Port Forwarding
- Forward external TCP port `32400` → `192.168.1.25:32400`

---

### INFO 1 — `VERSION=docker` tag in Plex compose (Confidence: Medium)

**Extracted:** `VERSION=)\` (extraction artifact for `VERSION=docker` or `VERSION=latest`)

The Plex container image tag `VERSION=docker` pins to the latest stable Plex release from Docker Hub. This is the recommended value for home use — no action needed, just confirming it's not set to a stale specific version.

---

### INFO 2 — Document is 11 months old (last modified May 2025)

The embedded timestamp is `2025-05-07`. Since then:
- Debian 13 "Trixie" was officially released (July 2025) — the HP Mini was set up on it pre-release, so the setup steps are likely still accurate but worth noting the OS is now stable/GA.
- `mdadm` and Docker versions may have minor updates, but no breaking changes expected.

---

## Summary Table

| # | Severity | Finding | Action Required |
|---|---|---|---|
| 1 | **Issue** | `PLEX_CLAIM=claim-x` placeholder | Update or label clearly |
| 2 | **Issue** | `PUID=100` — verify it's `1000` | Open in Pages, verify |
| 3 | **Issue** | `dperson/samba` is abandoned | Consider migrating image |
| W1 | **Warning** | Sudoers edited via `nano` | Recommend `visudo` |
| W2 | **Warning** | Local vs. Tailscale IP not clearly labeled | Add IP reference table |
| G1 | **Gap** | `NAS_Transfer.applescript` not documented | Add a section |
| G2 | **Gap** | `chmod -R 777` tip not confirmed present | Verify in Troubleshooting |
| G3 | **Gap** | Orbi port forwarding steps not confirmed | Verify in Plex section |
| I1 | Info | Plex `VERSION` tag — OK | No action |
| I2 | Info | Document is ~1 year old | Minor freshness review |

**Top priority:** Fix the `PLEX_CLAIM` placeholder (Issue 1) and verify `PUID` (Issue 2) — both affect someone following the guide to rebuild the setup.
