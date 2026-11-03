# Changelog

## v1.0 (2026-11-03)

- First public release under the name `exfat-fast-check`.
- Same logic as the tested Turkish-named build `exfat-hizli-denetim` v1.3: wrapper for `fsck.exfat`, copy of the real checker as `fsck.exfat-full`, `sepolicy.rule`, `service.sh` with a 5-minute polling loop.
- Installer removes `exfat-hizli-denetim` on the next reboot if present.
- Bilingual installer messages; English log messages (`check.log`).
