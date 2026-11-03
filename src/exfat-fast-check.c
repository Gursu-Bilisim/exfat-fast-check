/*
 * exfat-fast-check: wrapper installed over /system/bin/fsck.exfat
 * Author: kgursu (Gursu-Bilisim @ GitHub)
 *
 * vold checks public volumes with "fsck.exfat -y <device>" and kills the
 * check after 45 seconds. On large, well-filled cards a full check takes
 * longer; the killed exfatprogs run leaves the VolumeDirty bit set and the
 * card stays "unmountable" on every boot.
 *
 * Only for vold's call form (exactly "-y <device>"): if the boot sector is
 * exFAT and VolumeFlags has VolumeDirty (bit 1) and MediaFailure (bit 2)
 * clear, the full check is skipped and 0 is returned. In every other case
 * the real check (fsck.exfat-full) runs with the same arguments.
 */
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define FULL "/system/bin/fsck.exfat-full"

int main(int argc, char **argv) {
    if (argc == 3 && strcmp(argv[1], "-y") == 0) {
        const char *dev = argv[2];
        unsigned char b[512];
        int fd = open(dev, O_RDONLY | O_CLOEXEC);
        if (fd >= 0) {
            ssize_t n = pread(fd, b, sizeof b, 0);
            close(fd);
            if (n == (ssize_t)sizeof b && memcmp(b + 3, "EXFAT   ", 8) == 0 &&
                b[510] == 0x55 && b[511] == 0xAA) {
                unsigned flags = (unsigned)b[106] | ((unsigned)b[107] << 8);
                if ((flags & 0x6u) == 0) {
                    printf("exfat-fast-check: %s clean (VolumeFlags=0x%04x), full check skipped\n",
                           dev, flags);
                    return 0;
                }
                printf("exfat-fast-check: %s dirty (VolumeFlags=0x%04x), running full check\n",
                       dev, flags);
                fflush(stdout);
            }
        }
    }
    argv[0] = (char *)FULL;
    execv(FULL, argv);
    perror("exfat-fast-check: execv " FULL);
    return 8;
}
