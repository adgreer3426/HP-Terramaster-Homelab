# r/selfhosted — OUTLINE (write this in your own words)

This is scaffolding, NOT a script. Do **not** paste it. Write each section yourself — the personal specifics are what make it real, keep it from getting flagged, and make it land. Angle: owning the stack vs. renting an appliance.

---

## Title — pick an angle, then phrase it yourself
- The "I wanted to own/understand it, not rent an appliance" angle
- The "self-hosting Plex + Samba + remote access on a cheap used mini PC" angle
- Keep it concrete. If your natural style is lowercase/casual, write it that way.

## Opening — 2–4 sentences, your voice
Points to hit:
- Why you *didn't* buy a Synology — your **actual** reason (the price after drives? the locked ecosystem / EOL clock? just wanting to understand your own stack?)
- What you wanted instead
- ✍️ Add the real moment you decided to DIY — what tipped you over?

## The box — 1–2 lines
- HP EliteDesk 800 G4 Mini, used (~$200), 8th-gen + UHD 630 iGPU
- TerraMaster D2-310 USB-C, 2× 8 TB WD Red Plus, mdadm RAID 1, ~8 TB usable
- Debian 13 on the internal NVMe
- ✍️ Where you actually bought the HP and what it really cost you

## What you self-host — list each with a line on *why*
- Plex in Docker — Quick Sync hardware transcoding
- Samba — per-user family shares
- Tailscale — **no exposed ports** (lean into this, it's the sub's favorite thing)
- smartmontools — drive-health email alerts
- ✍️ Which one were you happiest to get working / do you use most?

## Pre-empt the two guaranteed comments — answer honestly, your words
- **"Why not TrueNAS / Unraid / OMV?"** → your real reason (wanted to learn the layers? already comfortable in Debian? no appliance abstraction?). Don't trash them.
- **"Why Plex and not Jellyfin?"** → your real reason; note the stack is a Docker host so swapping is trivial.
- Answering these upfront is what earns the room — don't skip them.

## Personal anecdotes — THE un-fakeable part, pick 1–2 REAL ones
- Something that actually broke and how you fixed it (the `ssmtp`→`msmtp` switch? a Tailscale/DNS gotcha? compose v1→v2?)
- How long the RAID resync really took and what you did while waiting
- A "huh, nicer than I expected" moment (remote access just... working from your phone?)
- ⚠️ These specific lived details are exactly what readers AND mod AI-detectors use to tell real from generated. Put genuine ones in, in your own phrasing — even keep your typos.

## Close
- One honest line on cost vs. a DS224+
- Offer to answer questions — and then actually reply in the thread

---

## Flair & rules (unchanged)
- **No paid link in the body.** Surface the guide only if asked, softly, in a comment.
- Flair: use a **topic flair** if one fits (Media Serving, Remote Access, etc.); otherwise a neutral one. **Avoid "Guide" and "Product Announcement."**
- You've already been flagged once here — **stay transparent** if a mod re-engages. Don't repost the same content; this rewrite needs to be genuinely yours.
