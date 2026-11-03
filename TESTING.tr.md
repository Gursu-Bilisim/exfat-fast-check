# Test notları

[English](TESTING.md)

Cihaz: SM-T970 (gts7xlwifi), LineageOS `24.0-20261029-nightly`, FolkPatch 115404 (KernelPatch 0.13.9), Hybrid Mount 6.2.5 (OverlayFS kipi). Kart: 2 TB exFAT, 8730 dizin, 35329 dosya. exfatprogs 1.4.3. Testler Türkçe adlı önceki derlemeyle (`exfat-hizli-denetim` v1.1 ve v1.3) yapıldı; bu deponun v1.0 sürümü aynı mantığı İngilizce adlarla içeriyor.

## Modülden önce

- Her açılışta: `Check failed (code 110)`, kart `unmountable`.
- Root ile salt okunur tam denetim: `clean`, 1m17.56s.
- Elle `fsck.exfat -y` sonrası VolumeFlags `00 00`. Sonraki `sm mount` (45. saniyede kesildi) sonrası yine `02 00`.

## Sarmalayıcı yerinde

`ls -lZ`: `/system/bin/fsck.exfat` (27304 bayt) ve `/system/bin/fsck.exfat-full` (77624 bayt), ikisi de `u:object_r:fsck_exec:s0`. Modülden kaynaklanan `avc` reddi yok.

## Temiz kart, normal yeniden başlatma

```
03:38:56  I vold : Check OK
public:179,1 mounted 5A75-7508
```

## Bilerek kirli işaretlenen kart

Kart ayrıldı, VolumeFlags elle `02` yapıldı, yeniden başlatıldı. vold'un denetimi (sarmalayıcı üzerinden gerçek denetim) 45. saniyede kesildi, ardından `service.sh`:

```
06:34:40 boot completed
06:35:33 public:179,1 (5A75-7508): unmountable, VolumeFlags=0x02, full check started
/dev/block/vold/public:179,1: clean. directories 8731, files 35329
06:36:50 public:179,1: full check finished, exit code 0
06:36:51 public:179,1: sm mount requested
06:36:57 public:179,1 (5A75-7508): mounted
```

## Yayın zip'i (v1.0, SHA-256 d88419163b49cfcf…)

08:46'da test derlemesinin üzerine kuruldu, kurulum ekranındaki Yeniden Başlat ile açıldı. Kart kirli geldi ve `service.sh` onardı:

```
08:48:20  E vold : Check failed (code 110)
08:48:23  public:179,1 (5A75-7508): unmountable, VolumeFlags=0x02, full check started
08:49:40  public:179,1: full check finished, exit code 0
08:49:40  I vold : Check OK
08:49:46  public:179,1 (5A75-7508): mounted
```

Sarmalayıcı ve kopya yerinde (`grep -c` = 2, iki dosya da `u:object_r:fsck_exec:s0`); Türkçe adlı önceki modülü kurulum kaldırdı.

Ardından güç menüsünden normal yeniden başlatma (09:11), onarım gerekmedi:

```
09:11:57 boot completed
09:12:04 I vold : Check OK
09:12:08 public:179,1 (5A75-7508): mounted
```

Testlerden sonra salt okunur tam denetim: `clean. directories 8731, files 35329`.

## Test sırasında bulunanlar

- `sys.boot_completed`, vold kartı listeye eklemeden önce geliyor; o anda `sm list-volumes public` boş dönüyor, kart yaklaşık 10 saniye sonra `checking` olarak görünüyor. `service.sh` bu yüzden listeye 5 dakikaya kadar bakıyor.
- Hybrid Mount ile yönetici uygulama, Hybrid Mount kurulduktan sonra bir açılış geçmeden başka modül kabul etmiyor.
- Yeniden başlatma yolu ve sonraki açılışta kartın durumu:

  | Yeniden başlatma | Kart |
  |---|---|
  | FolkPatch kurulum ekranındaki Yeniden Başlat (08:09, 08:47, 09:02) | kirli, `service.sh` onardı |
  | Sistem güç menüsü (09:11) | temiz, `Check OK` |
  | FolkPatch ana ekranındaki güç simgesi (09:25) | temiz, `Check OK` (denetim 9 ms) |
  | Modül yeniden kuruldu, kurulum ekranından Geri ile çıkıldı, güç menüsü (09:31) | temiz, açılış tamamlandıktan 6 sn sonra bağlandı |

  Kurulumun kendisi kartı kirletmiyor; kirleten kurulum ekranındaki Yeniden Başlat düğmesi. Her durumda kart sonunda bağlandı.
- Modülü yeniden kurmak klasörünü değiştirdiği için `check.log` her kurulumdan sonra boş başlıyor.

## Henüz denenmeyenler

- Magisk, KernelSU, APatch
- Açılıştan sonra takılan kart
- FAT32 kartlar (sarmalayıcı yalnızca exFAT ile ilgilenir; diğer dosya sistemleri kendi denetim araçlarına değişmeden gider)
