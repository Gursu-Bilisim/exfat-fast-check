# exFAT Fast Check

[English](README.md)

`vold`'un dosya sistemi denetimini 45 saniyede kestiği Android sürümlerinde büyük exFAT SD kartların açılışta bağlanmasını sağlayan bir root modülü.

Yazar: kgursu (Gursu-Bilisim @ GitHub)

## Sorun

`vold` her harici kartı bağlamadan önce `fsck.exfat -y <aygıt>` ile denetliyor ve denetimi 45 saniye sonra durduruyor (`kUntrustedFsckSleepTime`). Logda şu satırlar çıkıyor:

```
E vold    : Check failed (code 110)
E vold    : public:179,1 failed filesystem check
```

Kart da bozuk olarak gösteriliyor ("SD kartla ilgili sorun"). 110 kodu `ETIMEDOUT`. Büyük ve dolu bir kartta dosya sistemi sağlam olsa bile tam denetim bu süreyi aşıyor. Test cihazından örnek (2 TB kart, 8730 dizin, 35329 dosya, exfatprogs 1.4.3, root ile):

```
fsck.exfat -n /dev/block/mmcblk0p1: clean. directories 8730, files 35329
    1m17.56s real     0m01.99s user     0m08.21s system
```

Kesilen denetim VolumeDirty bitini de açık bırakıyor (106. bayttaki VolumeFlags zaman aşımından sonra `02 00`, tamamlanan denetimden sonra `00 00`). Kart her açılışta aynı durumda kalıyor.

İlgili kayıtlar: [LineageOS/issues #712](https://github.com/LineageOS/issues/issues/712), [exfatprogs #384](https://github.com/exfatprogs/exfatprogs/issues/384).

## Modül nasıl çalışıyor

| Dosya | Görev |
|---|---|
| `system/bin/fsck.exfat` | Küçük statik sarmalayıcı ([kaynak](src/exfat-fast-check.c)). Yalnızca vold'un `-y <aygıt>` çağrısında çalışır: açılış sektörü exFAT ise ve VolumeDirty ile MediaFailure kapalıysa hemen 0 döner. Diğer durumlarda gerçek denetimi aynı argümanlarla çalıştırır |
| `system/bin/fsck.exfat-full` | Kurulum sırasında alınan, ROM'un kendi `fsck.exfat` kopyası |
| `sepolicy.rule` | vold'un denetim etki alanının (`fsck_untrusted`) bu kopyayı çalıştırmasına izin verir |
| `service.sh` | Açılıştan sonra vold'un kendi denetimini 5 dakikaya kadar bekler; bir exFAT birim hâlâ `unmountable` ise tam denetimi süre sınırı olmadan yapar ve vold'dan kartı yeniden bağlamasını ister |

Modül kirli işaretli bir kartın denetimini atlamaz: tam denetim yine yapılır, yalnızca vold'un süre sınırının dışında. Kayıt dosyası: `/data/adb/modules/exfat-fast-check/check.log`.

## Gereksinimler

- arm64 cihaz
- Modüllerin `system/` dosyalarını bağlayan ve `sepolicy.rule` okuyan bir root çözümü
- Denendiği ortam: SM-T970 (gts7xlwifi), LineageOS 24 (`24.0-20261029-nightly`), FolkPatch 115404 ve Hybrid Mount (OverlayFS kipi). Magisk ve KernelSU'da henüz denenmedi; geri bildirim beklenir.

## Kurulum

1. Releases sayfasından `exfat-fast-check-<sürüm>.zip` dosyasını indir.
2. Dosyayı cihaza kopyala. Dosya yöneticisi veya USB dosya aktarımı kullanabilir ya da adb ile gönderebilirsin:
   ```
   adb push exfat-fast-check-v1.0.zip /sdcard/Download/
   ```
3. FolkPatch / APatch / KernelSU: yönetici uygulaman `system/` dosyaları için bir metamodül istiyorsa (örneğin Hybrid Mount) önce onu kur ve bir kez yeniden başlat. Yeniden başlatmadan uygulama başka modül kabul etmiyor.
4. Yönetici uygulamada: Modüller → Depolamadan yükle → `Download/exfat-fast-check-v1.0.zip`.
   <!-- ekran görüntüsü: docs/img/tr/01-depolamadan-yukle.png -->
5. Yeniden başlat.

## Sonucu kontrol etme

Açılıştan sonra (kart kirliyse 3 dakika bekle):

```
adb shell "sm list-volumes all"
```

Kart `mounted` görünmeli. Sarmalayıcının yerinde ve doğru etiketli olduğunu görmek için:

```
adb shell "su -c 'grep -c exfat-fast-check /system/bin/fsck.exfat; ls -lZ /system/bin/fsck.exfat /system/bin/fsck.exfat-full'"
```

Beklenen: 1 veya daha büyük bir sayı ve iki dosyada da `u:object_r:fsck_exec:s0`.

Açılışta ne olduğu:

```
adb shell "su -c 'cat /data/adb/modules/exfat-fast-check/check.log'"
adb shell "logcat -d -b all | grep -iE 'exfat-fast-check|Check OK|Check failed|avc.*fsck'"
```

Temiz bir kartta açılıştan birkaç saniye sonra `I vold : Check OK` görünür. `avc ... fsck_exec` reddi, root çözümünün `sepolicy.rule` dosyasını yüklemediğini ya da dosya etiketlerini korumadığını gösterir.

## Elle kullanım

- Salt okunur tam denetim: `su -c '/system/bin/fsck.exfat-full -n /dev/block/mmcblk0p1'`
- Açılıştan sonra bağlanamaz hale gelen kartı (örneğin sonradan takılan) onarmak: `su -c sh /data/adb/modules/exfat-fast-check/service.sh`

## ROM güncellemesinden sonra

Modülü yeniden kur. Kurulum ROM'un `fsck.exfat` dosyasının güncel kopyasını alır.

## Kaldırma

Modülü yönetici uygulamadan kaldır ve yeniden başlat. `/system/bin/fsck.exfat` yeniden ROM'un kendi dosyası olur.

## Derleme

```
./build.sh
```

`zig` (ya da `pip install ziglang`) ve `zip` gerekir. Zip dosyası `dist/` altına yazılır.

## Lisans

GPL-3.0-or-later. Ayrıntı: [LICENSE](LICENSE).

Modül exfatprogs içermez: `fsck.exfat-full` kurulum sırasında cihazdaki ROM'dan kopyalanır.
