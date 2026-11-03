#!/system/bin/sh
# exFAT Fast Check: after boot, repairs exFAT volumes that stayed
# "unmountable" because they are marked dirty, without vold's time limit,
# then asks vold to mount them.
# Author: kgursu (Gursu-Bilisim @ GitHub)
# SPDX-License-Identifier: GPL-3.0-or-later
# Manual run: su -c sh /data/adb/modules/exfat-fast-check/service.sh
export PATH=/system/bin:/system/xbin:/vendor/bin:$PATH
MODDIR=/data/adb/modules/exfat-fast-check
[ -f "${0%/*}/module.prop" ] && MODDIR=$(cd "${0%/*}" && pwd)
LOG=$MODDIR/check.log
FULL=$MODDIR/system/bin/fsck.exfat-full
LIMIT=60   # 60 x 5 s = 5 minutes

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }
volumes() { /system/bin/sm list-volumes public 2>>"$LOG"; }

repair() {   # $1 volume id, $2 uuid
  dev=/dev/block/vold/$1
  [ -b "$dev" ] || { log "$1: $dev missing"; return; }
  sig=$(dd if="$dev" bs=1 skip=3 count=8 2>/dev/null)
  [ "$sig" = "EXFAT   " ] || { log "$1: not exFAT, left alone"; return; }
  flags=$(dd if="$dev" bs=1 skip=106 count=1 2>/dev/null | od -An -tx1 | tr -d ' ')
  log "$1 ($2): unmountable, VolumeFlags=0x$flags, full check started"
  "$FULL" -y "$dev" >> "$LOG" 2>&1
  rc=$?
  log "$1: full check finished, exit code $rc"
  case $rc in
    0|1) /system/bin/sm mount "$1" 2>>"$LOG"; log "$1: sm mount requested" ;;
    *) log "$1: could not be repaired, check manually" ;;
  esac
}

if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 65536 ]; then mv -f "$LOG" "$LOG.1"; fi
log "service.sh started"

i=0
until [ "$(/system/bin/getprop sys.boot_completed)" = "1" ]; do
  sleep 5; i=$((i + 1))
  [ $i -eq 120 ] && log "still waiting for sys.boot_completed after 10 minutes"
done
log "boot completed"

# Cards appear in the list a few seconds after boot and vold runs its own
# check first. Wait while the list is empty or a volume is checking or
# unmounted; repair each unmountable exFAT volume once.
done_ids=" "
i=0
while [ $i -lt $LIMIT ]; do
  list=$(volumes)
  wait_more=0
  [ -n "$list" ] || wait_more=1
  while read -r id state uuid; do
    [ -n "$id" ] || continue
    case "$state" in
      checking|unmounted) wait_more=1 ;;
      unmountable)
        case "$done_ids" in
          *" $id "*) ;;
          *) done_ids="$done_ids$id "; repair "$id" "$uuid"; wait_more=1 ;;
        esac ;;
    esac
  done <<LIST
$list
LIST
  [ $wait_more -eq 0 ] && break
  sleep 5; i=$((i + 1))
done
[ $i -ge $LIMIT ] && log "5 minutes passed, stopped waiting"

volumes | while read -r id state uuid; do log "$id ($uuid): $state"; done
[ -n "$(volumes)" ] || log "no public volumes"
