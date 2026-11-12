# Teclast T65 → LineageOS 23.2 (Android 16) GSI — Procédure

Appareil : Teclast T65_EEA · SoC Unisoc **UMS9230S / T7280** · board `ums9230_6h10` · **UFS** · **A/B (VAB)**
Cible : **LineageOS 23.2 (Android 16 QPR2) GSI** — `MisterZtr/LineageOS_gsi`

> Template de référence : guide XDA « Lava Yuva 3 (Unisoc T606/UMS9230) — Bootloader Unlock via
> CVE-2022-38694 », **UFS, A/B, testé et confirmé en septembre 2026** → LineageOS 23.2 GSI ✔
> Board le plus proche confirmé : **Cubot KingKong ES 3 — `ums9230_6h10` (exactement le même)**.

---

## 0. Compatibilité — pourquoi ça peut marcher

| Critère | Exigence GSI | Notre appareil | Verdict |
|---|---|---|---|
| Treble | `ro.treble.enabled` | `true` | ✔ |
| Slots | A/B | A/B + virtual A/B | ✔ |
| Archi | arm64 | `arm64-v8a` | ✔ |
| Kernel | ≥ 5.4 pour EROFS | `5.15.178` | ✔ |
| Vendor API | ≥ 30 (MisterZtr : « support Android 11 vendors ») | `ro.vendor.api_level = 33` | ✔ |
| Version | GSI ≥ Android d'origine | Android 16 → GSI Android 16 | ✔ (égal) |
| Espace `super` | GSI doit tenir | system 970 Mo < GSI 1,7–3,2 Go | ⚠️ **à libérer** |

---

## 1. Ce qui n'est PAS possible

- **LineageOS officielle pour Teclast T65 : elle n'existe pas.** Teclast n'est pas dans la liste des appareils officiellement supportés. On passe donc obligatoirement par une **GSI** (= seule la partition `system` est remplacée ; `vendor` et le noyau Unisoc restent d'origine).
- **Flash par fastboot seul : impossible** (bootloader verrouillé au firmware, commandes d'unlock retirées).

---

## 2. Déverrouillage par BootROM — **on ne passe pas par fastboot**

Faille **CVE-2022-38694** (BootROM Unisoc, NCC Group) : `spd_dump` parle directement au BootROM en USB.
Le SoC est dans la liste supportée officielle : `ums9230 = T606/T612/T616 T72xx` → **T7280 ✔**

> ⚠️ **Avertissement du projet, à respecter absolument :**
> « UMS9230 **UFS** devices: Don't use fdl1/2 of UMS9230 **EMMC** devices. »
> Notre tablette est UFS → **seul** le paquet `ums9230_universal_unlock_UFS.dangerous.zip` convient.

### Outils à préparer (macOS arm64 → compilation native)

```bash
brew install libusb
git clone https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader
cd CVE-2022-38694_unlock_bootloader
git submodule update --init --recursive
gcc chsize.c -o chsize
gcc gen_spl-unlock.c -o gen_spl-unlock
cd spreadtrum_flash && make && cd ..

# Paquet UFS (PAS eMMC)
curl -LO https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/releases/download/1.72/ums9230_universal_unlock_UFS.dangerous.zip
unzip ums9230_universal_unlock_UFS.dangerous.zip -d ums9230_ufs
cp chsize gen_spl-unlock spreadtrum_flash/spd_dump ums9230_ufs/
cd ums9230_ufs
```

### Mode BROM

1. Tablette **éteinte complètement**
2. Maintenir **Volume bas** (essayer aussi Vol.+ / Vol.+/−  si échec)
3. Brancher l'USB en maintenant
4. **Écran noir = normal.** Vérifier : `sudo ./spd_dump --wait 10` → doit afficher `BSL_REP_VER: "SPRD3"`

### Les 6 étapes (chacune = refaire le mode BROM)

```bash
# 1-2. Dumper + effacer le SPL
sudo ./spd_dump --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec \
  r splloader r uboot e splloader e splloader_bak reset
cp splloader.bin uboot.bin BACKUP/        # ← SAUVEGARDE OBLIGATOIRE

# 3. Patcher le SPL
./gen_spl-unlock splloader.bin            # doit afficher un offset hex (ex 0xf9d8) = OK
mv splloader.bin u-boot-spl-16k-sign.bin
./chsize uboot.bin
mv uboot.bin uboot_bak.bin

# 4. Flasher l'uboot modifié
sudo ./spd_dump --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec \
  w uboot fdl2-cboot.bin reset

# 5. Exécuter le payload de déverrouillage
sudo ./spd_dump --wait 300 exec_addr 0x65015f08 fdl spl-unlock.bin 0x65000800
# → CHECK_BAUD FAIL puis CMD_CONNECT FDL1 = SUCCÈS. Le timeout final est normal.

# 6. VÉRIFIER (ne pas croire le log, lire le flag)
sudo ./spd_dump --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec \
  verbose 2 read_part miscdata 8192 64 m.bin reset
xxd m.bin     # 64 octets à zéro = encore verrouillé → refaire l'étape 5
              # données non nulles = DÉVERROUILLÉ ✔

# 7. Restaurer SPL/uboot + forcer le wipe
sudo ./spd_dump --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec \
  r boot w splloader u-boot-spl-16k-sign.bin w uboot uboot_bak.bin w misc misc-wipe.bin reset
```

→ La tablette redémarre, se réinitialise, et affiche l'écran **« Orange State » / LOCK FLAG IS: UNLOCK** en haut à gauche. **C'est le succès.**

---

## 3. Flash de la GSI LineageOS 23.2

Télécharger sur SourceForge (`MisterZtr/LineageOS_gsi`, release `v2026.05.24-lineage23.2`) :

| Fichier | Taille | Note |
|---|---|---|
| `LineageOS-23.2-20260524-VANILLA-EXT4-GSI.7z` | 2,5 Go | **recommandé pour le 1er essai** — aucune appli Google, entièrement inscriptible |
| `LineageOS-23.2-20260524-VANILLA-EROFS-GSI.7z` | 1,7 Go | plus rapide, plus léger — kernel ≥5.4 ✔ |
| `…-GAPPS-…` | +0,7 Go | seulement si tu veux Play Store |

```bash
# 0. (si erreur "not enough space to resize partition") libérer la place :
#    supprimer product_a (le bloat Teclast) => ~1,9 Go
adb reboot bootloader
fastboot reboot fastboot          # → fastbootd (écran type Recovery, « FASTBOOTD » en jaune)
fastboot devices                  # doit afficher  <serial>  fastbootd
fastboot delete-logical-partition product_a

# 1. Flasher la GSI sur le slot actif
fastboot flash system_a gsi.img
fastboot erase userdata
fastboot reboot
```

> Ne PAS toucher `vendor`. Ne pas recréer `system` manuellement sauf erreur d'espace réelle.

---

## 4. Risques — sans enrobage

| Risque | Gravité | Mitigation |
|---|---|---|
| Wipe total des données | certain | sauvegarder avant |
| Paquet `.dangerous` non testé sur T65 | élevé | BROM non-brickable en théorie ; PAC stock officiel de secours |
| Mauvais FDL (eMMC au lieu d'UFS) → effacement de partitions | élevé | utiliser **uniquement** le paquet UFS |
| `not enough space to resize partition` | moyen | supprimer `product_a` |
| GSI qui bootloop / boot animation en SIGSEGV | moyen | retenter une autre variante (EXT4 ↔ EROFS), ou rester stock |
| Caméra / modem / Bluetooth partiels | possible | `vendor` reste d'origine → souvent OK, jamais garanti |
| macOS arm64 : `spd_dump` non fourni | moyen | compiler nativement (libusb) — étape faisable |
| Pas de tool de restauration macOS | moyen | `C-Hidery/sfd_tool` (Linux) ou ResearchDownload (Windows) + PAC Needrom |

### Feuille de secours (si tout part mal)

PAC stock officiel : **Needrom « Teclast T65 (A6D6) — Android-16.0_ROW_V1.10_20260209 » (ONLY Unisoc T7280)**
→ flash via **ResearchDownload / UpgradeDownload** (**Windows**). Le SoC en BROM étant non-brickable, il y a toujours un chemin de retour.
