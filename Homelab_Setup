Hardware Setup
You built a home NAS using an HP Mini running Debian 13 as the server, with a TerraMaster 2-bay enclosure connected via USB-C holding two 7.3TB drives.
RAID 1
Set up software RAID 1 using mdadm, mirroring both drives so either can fail without data loss. The array is mounted at /mnt/nas and auto-mounts on boot.
Docker
Installed Docker and Docker Compose to run Plex and Samba as isolated containers, making updates easier and keeping apps separate from the OS.
Plex
Installed Plex via Docker, claimed the server, set up media libraries and got it working on iPhone, Mac and TV. Fixed remote access by setting up port forwarding on your Orbi router for port 32400.
Samba
Set up Samba for network file sharing with five shares — media plus private folders for adam, amanda, ava and leslie each with their own passwords.
Tailscale
Installed Tailscale on the HP and iPhone giving secure remote access from anywhere using IP 100.115.3.97.
Smartmontools
Installed drive health monitoring with automatic email alerts to agreer26@gmail.com if either drive starts failing. Short tests run daily, long tests weekly.
Troubleshooting solved
Network/DNS issues, sudo permissions, GRUB boot failure, Plex discovery, Samba permissions, and large file transfers using rsync instead of Finder.
Ongoing tips
Use rsync instead of Finder for large transfers to avoid error -8062, and run sudo chmod -R 777 /mnt/nas if permissions ever cause issues again.
