# exFAT Fast Check: install / kurulum
# Author: kgursu (Gursu-Bilisim @ GitHub)
# SPDX-License-Identifier: GPL-3.0-or-later
ID=exfat-fast-check
OLD_ID=exfat-hizli-denetim

[ "$ARCH" = "arm64" ] || abort "! arm64 only / Yalnizca arm64 (found/bulunan: $ARCH)"
[ -f /system/bin/fsck.exfat ] || abort "! /system/bin/fsck.exfat not found / bulunamadi"

# Copy of the real fsck.exfat. If this module (or its earlier Turkish-named
# build) is active, /system/bin/fsck.exfat is the wrapper itself.
if grep -q "exfat-fast-check" /system/bin/fsck.exfat 2>/dev/null; then
  SRC=/data/adb/modules/$ID/system/bin/fsck.exfat-full
elif grep -q "exfat-hizli-denetim" /system/bin/fsck.exfat 2>/dev/null; then
  SRC=/data/adb/modules/$OLD_ID/system/bin/fsck.exfat-tam
else
  SRC=/system/bin/fsck.exfat
fi
[ -f "$SRC" ] || abort "! Real fsck.exfat not found / Gercek fsck.exfat bulunamadi: $SRC"
cp -f "$SRC" "$MODPATH/system/bin/fsck.exfat-full" || abort "! Copy failed / Kopyalama basarisiz"
ui_print "- Real check / Gercek denetim: $SRC -> fsck.exfat-full"

if [ -d "/data/adb/modules/$OLD_ID" ]; then
  touch "/data/adb/modules/$OLD_ID/remove"
  ui_print "- $OLD_ID will be removed on reboot / yeniden baslatmada kaldirilacak"
fi

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/system/bin/fsck.exfat" 0 2000 0755 u:object_r:fsck_exec:s0
set_perm "$MODPATH/system/bin/fsck.exfat-full" 0 2000 0755 u:object_r:fsck_exec:s0
set_perm "$MODPATH/service.sh" 0 0 0755
ui_print "- Reinstall after a ROM update (refreshes the fsck.exfat copy)."
ui_print "- ROM guncellemesinden sonra yeniden kurun (fsck.exfat kopyasi yenilenir)."
