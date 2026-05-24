# r/homelab build write-up

Draft for r/homelab. Goal: genuine build post that earns credibility. **No paid link in the body** — see the "How to mention the guide" notes at the bottom.

---

## Title (pick one)

> Built a 2-bay NAS to skip the Synology tax — HP Mini + TerraMaster USB-C, Debian + mdadm RAID 1

Alt:
> My budget Synology alternative: HP EliteDesk 800 G4 Mini + TerraMaster D2-310, Debian 13 + RAID 1 over USB-C

---

## Body

I'd been pricing a Synology DS224+ for months and was hesitant — by the time you add drives you're north of a grand, and you're entering into a software ecosystem you don't control. So I built my own with parts I could understand, repair, and would outlive any one vendor. I am sharing the build because the USB-C-RAID question came up a lot in my own research and the answers were all over the place.

**The hardware (~$400–$500 all in):**

- **HP EliteDesk 800 G4 Mini** (8th-gen Intel, UHD 630 iGPU, used) — the whole compute side. That iGPU does hardware-accelerated Plex transcoding via Quick Sync, which is the part that makes a cheap mini PC punch way above its weight. (The DS224+ can't hardware-transcode at all — no Quick Sync))
- **TerraMaster D2-310** — 2-bay USB-C enclosure. Important: it's a *dumb* bay. No hardware RAID, no proprietary anything. Just two drives hanging off USB-C.
- **2× 8 TB NAS drives** (WD Red Plus, CMR — not the SMR variant) in **RAID 1**, so ~8 TB usable and either drive can die without data loss.
- Debian 13 on the internal NVMe.

**The stack (all Docker except Samba):**

- **mdadm** software RAID 1 — Linux is the RAID controller, not the enclosure. Mounted at `/mnt/nas`, auto-mounts on boot.
- **Plex** (linuxserver.io image) with iGPU transcoding.
- **Samba** for per-user family file shares.
- **Tailscale** for remote access — no exposed ports except Plex's, everything else stays on the tailnet.
- **smartmontools** running daily short / weekly long SMART tests, emailing me if a drive starts throwing errors.

**Let me get ahead of the obvious objection: yes, it's RAID over USB-C.**

I know the reflexive reaction here ("USB enclosures drop drives, UAS resets, don't trust mdadm over USB"). It's a fair concern and I went in skeptical. What's made it solid for me: the D2-310 presents each drive cleanly to the OS, I'm monitoring SMART proactively so I'd see a flaky drive before it became a resync emergency, and RAID 1 (not 5/6) means a rebuild is a simple mirror copy, not a stressful parity recompute. It's a deliberate budget tradeoff, not me pretending USB is as good as a SAS backplane. If I outgrow it, the drives and the whole software stack move to a proper HBA without re-learning anything.

**Gotchas, things to consider in the future:**

- **Say it with me, RAID is not a backup.** Mirrored deletes are still deletes. I run a separate offsite backup (cloud for the irreplaceable stuff, rotated external drive for the rest). 
- **Debian 13 broke a couple of my old habits** — `ssmtp` is gone (moved to `msmtp` for the SMART alert emails), and `docker-compose` v1 is dead (compose v2 plugin).
- **Buy CMR drives, not SMR.** SMR drives can fall out of a RAID array during resync. Check the model, not just the capacity.
- **Tailscale + a persistent IP-forwarding sysctl** beat poking holes in the router for everything. The only forwarded port is Plex's.

Cost comparison that started all this: a DS224+ with the same 2× 8 TB is roughly $900–$1,100 by the time you're done. This came in around half that, and I actually know what every piece does.

Happy to answer anything on the mdadm-over-USB setup, the Plex transcoding config, or the backup workflow.

---

## How to mention the guide (read before posting)

- **Do NOT put the Gumroad link in the post body.** r/homelab's self-promo filter (and the community) will nuke an obvious ad, especially from a low-karma account.
- Lead with value. The post above *is* the value — it stands on its own with zero link.
- If people ask "did you document this?" / "any chance you wrote this up?", *then* reply in a comment: something like "yeah, I wrote the whole thing up step-by-step for myself — turned it into a guide, happy to DM the link if that's allowed here, don't want to spam." Let them pull it from you.
- Check the subreddit rules first (they have a specific self-promotion policy and it changes). Some require flair, some forbid any commercial links outright.
- Don't post from a brand-new throwaway. Have some genuine comment history first or it reads as a plant.

## Photo checklist (r/homelab is photo-driven — posts with pics get 5–10× the engagement)

- [ ] The HP Mini + TerraMaster on the shelf (the actual rig)
- [ ] `lsblk` / `cat /proc/mdstat` showing the healthy array
- [ ] Plex dashboard mid-transcode (showing hardware transcode)
- [ ] Optional: a quick architecture sketch (you already have one in the guide)
