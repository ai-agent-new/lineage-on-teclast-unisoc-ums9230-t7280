# PLAN D'INSTALLATION — LineageOS 23.2 (Android 16) sur Teclast T65

> Rédigé le **7 novembre 2026**. Toutes les valeurs ci-dessous ont été **lues en direct sur la tablette ou compilées/vérifiées sur le Mac** — aucune n'est supposée.
> Dossier projet : `<LOCAL_PROJECT_DIR> T65`

---

## 0. VERDICT : pourquoi il n'existe qu'une seule voie

État réel lu le 7/11 (ADB, tablette démarrée) :

| Propriété | Valeur | Signification |
|---|---|---|
| `ro.boot.verifiedbootstate` | `green` | Système **non briqué**, aucune corruption matérielle |
| `ro.boot.veritymode` | `eio` | Android tolère un système **non vérifié** en le signalant → **origine du message « device is corrupt »** |
| `ro.boot.flash.locked` | `1` | **Bootloader verrouillé** |
| `ro.boot.vbmeta.device_state` | `locked` | **AVB actif et verrouillé** |
| `ro.boot.slot_suffix` | `_a` | Slot actif = **A** |
| `vbmeta.digest` | `b730f297…42b2a8` | Empreinte AVB courante (à sauvegarder) |

### Comparatif des méthodes

| Méthode | Verdict | Justification |
|---|---|---|
| **DSU + Shizuku** (GSI temporaire) | ❌ **impossible ici** | Doc officielle DSU-Sideloader : *« most GSIs requires unlocked bootloader to get them booting properly, since **only OEM-Signed GSIs are allowed to boot on locked bootloader** »*. Foire aux questions : *« DSU installation finishes with no errors, but device doesn't boot → **AVB is preventing device from booting installed images** »*. **C'est exactement ce que tu as vécu** : installation OK → AVB refuse de démarrer → message « corrupt ». |
| **`fastboot flashing unlock`** (officiel) | ❌ impossible | `flash.locked=1` + `ro.oem_unlock_supported` **absent** → le firmware ne propose même pas le déverrouillage OEM. |
| **Magisk sur ROM stock** (root) | ⚠️ possible mais écarté | Ne donne pas LineageOS ; nécessite *aussi* un déverrouillage. |
| **CVE-2022-38694** (BootROM Unisoc) | ✅ **seule voie** | Exploit au niveau **BootROM via USB direct**, **sans fastboot et sans signature requise**. |

> **Conclusion : il faut déverrouiller le bootloader. Il n'y a aucun raccourci.** Le DSU que tu as tenté était la bonne idée — mais elle plafonne par conception sur un appareil verrouillé.

---

## 1. CE QUI EST DÉJÀ PRÊT (côté Mac — zéro risque, rien n'a touché la tablette)

```
6_TECHNICS/TECLAST T65/
├── 01_outils/CVE-2022-38694_unlock_bootloader/
│   ├── chsize              ✅ compilé natif arm64  (tronque un dump DHTB à sa taille réelle)
│   ├── gen_spl-unlock      ✅ compilé natif arm64  (génère u-boot-spl-16k-sign.bin + spl-unlock.bin)
│   ├── spreadtrum_flash/spd_dump  ✅ compilé natif arm64 (libusb 1.0.30)
│   └── soc/ums9230/custom_exec_no_verify_65015f08.bin   ← payload d'exploit SPÉCIFIQUE ums9230
├── 02_unlock_package/
│   ├── ums9230_universal_unlock_UFS.dangerous.zip
│   └── UFS_package/  (fdl1-dl.bin, fdl2-dl.bin, fdl2-cboot.bin, misc-wipe.bin,
│                      custom_exec_no_verify_65015f08.bin, unlock_autopatch_9230.bat)
├── 03_gsi/            (téléchargement LineageOS 23.2 en cours)
├── 04_backup/         (vide — recevra les dumps de la phase A)
└── logs/
```

**Point important vérifié** : l'adresse du payload d'exploit `0x65015f08` **correspond exactement** au fichier `soc/ums9230/custom_exec_no_verify_65015f08.bin`. L'exploit est donc bien **calibré pour le ums9230** (donc ton T7280). Ce n'est pas un paquet « au hasard ».

**Pourquoi le paquet UFS ne contient pas `spl-unlock.bin`** : parce qu'il doit être **dérivé du SPL propre à TON appareil**. `gen_spl-unlock` le fabrique à partir du `splloader` **dumpé de la tablette** (il remplace les instructions de contrôle du verrou par des `NOP` `0xD503201F`). → **On n'a pas besoin de la ROM stock pour déverrouiller.** C'est une bonne nouvelle.

---

## 2. LES TROIS PHASES

| Phase | Nature | Effet sur la tablette | Réversible ? |
|---|---|---|---|
| **A — Sauvegarde** | Lecture seule | Aucun | — |
| **B — Déverrouillage BootROM** | Écriture | ⚠️ **WIPE COMPLET OBLIGATOIRE** | ❌ non |
| **C — Flash GSI** | Écriture | ⚠️ **WIPE COMPLET OBLIGATOIRE** | ❌ non |

---

## 3. PHASE A — SAUVEGARDE (lecture seule) — À FAIRE AVANT TOUT

Objectif : pouvoir revenir en arrière coûte que coûte.

**A.1 — Dumps des partitions critiques** (via `spd_dump` en lecture, ou ADB root si dispo) :
`boot_a`, `init_boot_a`, `dtbo_a`, `vbmeta_a`, `splloader`, `uboot`, `miscdata`, `super` (si possible), `nvdata`/`nvram` (**IMPORTANT** : contient les IMEI/calibration modem).

**A.2 — Feuille de secours ultime** : télécharger le **PAC stock officiel** « Teclast T65 A6D6 Android-16 ROW » (Needrom) et le stocker dans `04_backup/`. Ce PAC se reflashe sous **Windows** avec *ResearchDownload* — c'est le seul retour à l'état d'usine garanti si tout tourne mal. (Windows requis → à anticiper.)

**A.3 — Sauvegarde des données utilisateur** : contacts, photos, l'écran d'accueil — le WIPE effacera tout.

---

## 4. PHASE B — DÉVERROUILLAGE BOOTROM (CVE-2022-38694)

> **⚠️ À ne lancer qu'avec ton feu vert explicite, tablette chargée, câble USB de données de qualité.**

**B.0 — Entrer en mode BROM** : tablette ÉTEINTE, maintenir **Vol+ et Vol−** puis brancher l'USB au Mac (ou Vol+ + Power selon la variante).

**B.1 — Dump du SPL et de l'uboot** (lecture, avec la faille) :
```bash
cd "02_unlock_package/UFS_package"
cp ../../01_outils/CVE-2022-38694_unlock_bootloader/{chsize,gen_spl-unlock} .
cp ../../01_outils/CVE-2022-38694_unlock_bootloader/spreadtrum_flash/spd_dump .

./spd_dump --wait 300 exec_addr 0x65015f08 \
  fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec \
  r splloader r uboot e splloader e splloader_bak reset
```

**B.2 — Générer le payload de déverrouillage** :
```bash
./gen_spl-unlock splloader.bin     # → produit spl-unlock.bin  ET  patche splloader.bin
mv splloader.bin u-boot-spl-16k-sign.bin
./chsize uboot.bin                 # tronque le dump à sa taille réelle
mv uboot.bin uboot_bak.bin
```

**B.3 — Poser le cboot dans `uboot`** :
```bash
./spd_dump --wait 300 exec_addr 0x65015f08 \
  fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec \
  w uboot fdl2-cboot.bin reset
```

**B.4 — EXÉCUTER LE DÉVERROUILLAGE** (peut devoir être lancé **deux fois**) :
```bash
./spd_dump exec_addr 0x65015f08 fdl spl-unlock.bin 0x65000800
```

**B.5 — VÉRIFIER l'état du verrou** (lecture de `miscdata`) :
```bash
./spd_dump exec_addr 0x65015f08 \
  fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec \
  verbose 2 read_part miscdata 8192 64 m.bin reset
```
> **Lecture du résultat** : **64 octets de zéros = ENCORE VERROUILLÉ** · **32 caractères + 16 d'empreinte + 16 d'empreinte = DÉVERROUILLÉ**.

**B.6 — RESTAURER le SPL, l'uboot et remettre `misc`** :
```bash
./spd_dump exec_addr 0x65015f08 \
  fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec \
  r boot w splloader u-boot-spl-16k-sign.bin w uboot uboot_bak.bin \
  w misc misc-wipe.bin reset
```

✅ À ce stade la tablette doit démarrer avec l'avertissement **« Orange State — device unlocked »** (c'est normal et **définitif**).

---

## 5. PHASE C — INSTALLATION DE LineageOS 23.2 GSI

### C.0 — Contrainte d'espace (mesurée, pas estimée)

| Élément | Taille réelle |
|---|---|
| `super` | `0x1f4000000` = **8 000 Mio** |
| Slot complet (system 970 + system_ext 297 + vendor 850 + odm 11 + product **1 940** + vendor_dlkm 11) | ≈ **4 079 Mio** |
| 2 slots | **8 158 Mio → NE TIENT PAS dans 8 000 Mio** |
| GSI VANILLA EROFS — **téléchargée et vérifiée** (magic `e2e1f5e0` OK) | **1,66 Gio** (1 782 611 968 o) |
| GSI VANILLA EXT4 — **téléchargée et vérifiée** (magic `53ef` OK) | **2,55 Gio** (2 733 260 800 o) |
| Espace libre dans `super` (8 000 − 4 079 Mio) | ≈ **3 921 Mio** |

→ **Conclusion corrigée** : les 3,9 Gio libres dans `super` **suffisent** à agrandir `system` pour accueillir la GSI (fastbootd redimensionne automatiquement la partition logique). Supprimer **`product_a`** (1 940 Mio de bloat Teclast) reste **conseillé** pour la propreté, mais **n'est plus bloquant**.

### C.1 — Démarrer en mode **fastbootd** (et non le bootloader classique)
```bash
adb reboot bootloader
fastboot reboot fastboot        # ← indispensable : fastbootd sait gérer les partitions logiques
fastboot getvar is-userspace      # doit répondre : yes
```

### C.2 — Libérer la place et flasher
```bash
fastboot delete-logical-partition product_a
fastboot delete-logical-partition product_b     # si présente
fastboot flash system <system.img extrait de la GSI>
fastboot -w                                      # WIPE
```
> **Vitesse** : préparer l'image en **raw** (décompresser le `.img` si sparsé) pour éviter les erreurs de flash sur `super`.

### C.3 — Neutraliser dm-verity (sinon boucle de démarrage)
```bash
fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
```
> `vbmeta.img` : créer une image **vide de la bonne taille** (`avbtool make_vbmeta_image`) ou réutiliser le `vbmeta` dumpé en **phase A**.

### C.4 — Redémarrer
```bash
fastboot reboot
```
Premier démarrage : **5 à 15 minutes**, c'est normal.

---

## 6. RISQUES ASSUMÉS (honnêtement)

| Risque | Probabilité | Mitigation |
|---|---|---|
| Le paquet UFS « dangerous » n'a **jamais été testé sur un T65** | moyenne | Dump complet en phase A + PAC stock en secours |
| Offsets spécifiques au T65 inconnus | **faible** | L'exploit est calibré ums9230 (`0x65015f08`) et le SoC est le bon |
| `not enough space to resize partition` au flash | moyenne | Suppression de `product_a` (C.2) |
| dm-verity non désactivable même déverrouillé | faible | `--disable-verity` + vbmeta patché (C.3) |
| Caméra / modem partiellement fonctionnels sous GSI | **moyenne** | À tester ; retour au PAC stock possible |
| Wipe définitif des données | **certaine** | Sauvegarde en phase A.3 |

---

## 7. ORDRE D'EXÉCUTION RECOMMANDÉ

1. **Attendre la fin du téléchargement GSI** et vérifier l'image.
2. **Phase A** (sauvegarde) — sans risque, à faire tranquillement.
3. Récupérer le **PAC stock** (secours).
4. **Phase B** (déverrouillage) — sur décision explicite.
5. **Phase C** (flash) — immédiatement après, tant qu'on est en mode BROM/fastboot.
