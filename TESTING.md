# Test notes

[Türkçe](TESTING.tr.md)

Device: SM-T970 (gts7xlwifi), LineageOS `24.0-20261029-nightly`, FolkPatch 115404 (KernelPatch 0.13.9), Hybrid Mount 6.2.5 (OverlayFS mode). Card: 2 TB exFAT, 8730 directories, 35329 files. exfatprogs 1.4.3. Tests made with the earlier Turkish-named build (`exfat-hizli-denetim` v1.1 and v1.3); v1.0 of this repository has the same logic with English names.

## Before the module

- Every boot: `Check failed (code 110)`, card `unmountable`.
- Root, read-only full check: `clean`, 1m17.56s real.
- After a manual `fsck.exfat -y`: VolumeFlags `00 00`. After the next `sm mount` (killed at 45 s): `02 00` again.

## Wrapper in place

`ls -lZ` shows `/system/bin/fsck.exfat` (27304 bytes) and `/system/bin/fsck.exfat-full` (77624 bytes), both `u:object_r:fsck_exec:s0`. No `avc` denial from the module.

## Clean card, normal reboot

```
03:38:56  I vold : Check OK
public:179,1 mounted 5A75-7508
```

## Card marked dirty on purpose

Card unmounted, VolumeFlags set to `02` by hand, reboot. vold's check (real check via the wrapper) was killed at 45 s, then `service.sh`:

```
06:34:40 boot completed
06:35:33 public:179,1 (5A75-7508): unmountable, VolumeFlags=0x02, full check started
/dev/block/vold/public:179,1: clean. directories 8731, files 35329
06:36:50 public:179,1: full check finished, exit code 0
06:36:51 public:179,1: sm mount requested
06:36:57 public:179,1 (5A75-7508): mounted
```

## Release zip (v1.0, SHA-256 d88419163b49cfcf…)

Installed over the test build at 08:46 and rebooted from the installer's Reboot button. The card came up dirty and was repaired by `service.sh`:

```
08:48:20  E vold : Check failed (code 110)
08:48:23  public:179,1 (5A75-7508): unmountable, VolumeFlags=0x02, full check started
08:49:40  public:179,1: full check finished, exit code 0
08:49:40  I vold : Check OK
08:49:46  public:179,1 (5A75-7508): mounted
```

Wrapper and copy in place (`grep -c` = 2, both files `u:object_r:fsck_exec:s0`); the earlier Turkish-named module was removed by the installer.

Normal reboot from the power menu afterwards (09:11), no repair needed:

```
09:11:57 boot completed
09:12:04 I vold : Check OK
09:12:08 public:179,1 (5A75-7508): mounted
```

Read-only full check after the tests: `clean. directories 8731, files 35329`.

## Found during testing

- `sys.boot_completed` is set before vold lists the card; at that moment `sm list-volumes public` returns nothing and the card appears about 10 seconds later as `checking`. `service.sh` therefore polls the list for up to 5 minutes.
- With Hybrid Mount, the manager accepts other modules only after one reboot following the Hybrid Mount install.
- Rebooting with the Reboot button on FolkPatch's install screen left the card dirty in all three cases (08:09, 08:47, 09:02); a reboot from the power menu (03:38, 09:11) left it clean. In both cases the card was mounted at the end.

## Not tested yet

- Magisk, KernelSU, APatch
- Card inserted after boot
- FAT32 cards (the wrapper only handles exFAT; other file systems go to their own checker unchanged)
