# r/DataHoarder — OUTLINE (write this in your own words)

Scaffolding, NOT a script — don't paste. Write it yourself. Angle: the data — honest capacity, drives, redundancy vs. backup, integrity. This sub is sharp; real lived detail is what works.

---

## Title — pick an angle, phrase it yourself
- The "protecting ~8 TB on the cheap, honestly" angle
- The "here are the tradeoffs I made and what they cost" angle
- Lead with the **real usable number (~8 TB)** — never "14 TB."

## Opening — your voice
- Frame it as a deliberately cheap setup and that you're being upfront about the tradeoffs
- State capacity honestly: 2× 8 TB in RAID 1 = ~8 TB usable, **mirror not stripe**
- ✍️ Why cheap — budget, principle, or both?

## The drives — your words
- 2× 8 TB WD Red Plus, **CMR not SMR** — and *why that matters here* (SMR can drop out of an array mid-resync)
- You checked the model number, not just the tier
- ✍️ Did you almost grab an SMR drive? How did you verify CMR?

## Redundancy
- mdadm software RAID 1 on the D2-310 USB-C bay, driven by the HP EliteDesk
- Why RAID 1 over 5/6 — simple mirror rebuild, no parity hammering during resync

## Monitoring
- smartmontools: short SMART tests daily, long weekly, + email alerts
- Goal: replace a drive *before* it dies, not during a panic

## Backup — the part RAID doesn't do (≈ 3-2-1)
- Local: the RAID 1 array (single-drive death only)
- Offsite cloud: irreplaceable stuff only (photos/docs) via `rclone` → Backblaze B2; not the media library
- Offline/offsite: a rotated external drive, so a copy is always unplugged
- ✍️ What do you actually back up vs. skip? Have you ever had to restore from it?

## Pre-empt the two objections — answer honestly
- **"RAID over USB-C?"** → your honest take; it's a budget tradeoff, not USB=HBA; LSI HBA in IT mode is the upgrade path
- **"Why not ZFS/btrfs for bit-rot?"** → honest: you gave up block checksumming for dead-simple recovery on USB hardware (ZFS over USB is worse); SMART + backups are your corruption defense; ZFS on a real HBA is the right move if integrity is your #1 priority
- Don't oversell — honesty *is* the credibility here.

## Personal anecdotes — the un-fakeable part, add REAL ones
- The CMR-vs-SMR research rabbit hole
- A real SMART alert (or your test of the alert pipeline)
- How long the resync actually took
- Setting up the rclone/B2 job — what tripped you up
- ⚠️ Specific lived detail in your own words is what separates this from AI-generated filler. Use real ones.

## Close
- Offer to get into the rclone/B2 job, smartd config, or CMR/SMR weeds — then actually reply

---

## Flair & rules (unchanged)
- Flair: **"Hoarder-Setups"** (their show-your-rig category).
- **No paid link in the body** — this sub detects self-promo fast; let the writeup earn it, mention the guide only if asked.
- Photos/terminal output help: a healthy `cat /proc/mdstat` and a SMART summary land well.
- Check current sub rules first.
