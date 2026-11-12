# Teclast T65 — Audit ROM & pistes de flash (Android plus léger)

Date de l'audit : 2026-11-07 · Appareil connecté en ADB, **lecture seule**.

---

## 1. Audit de la ROM (faits mesurés sur l'appareil)

| Élément | Valeur |
|---|---|
| Modèle | Teclast **T65**_EEA (appareil `T65`) |
| SoC | **UMS9230S** (nom marketing Unisoc **T7280**) |
| Board / hardware | `ums9230_6h10` |
| Android | **16** (SDK 36), build `BP2A.250605.031.A3` / `20260413` |
| Patch sécurité | 2026-03-05 |
| Couche vendor | Android **13** (SDK 33) — ancienne, typique Unisoc |
| Stockage | **UFS** (contrôleur `20200000.ufs`) — LUN `sda` (74 part.), `sdb` (spl_a), `sdc` (spl_b) |
| Slots | **A/B** + virtual A/B + compression activés |
| Partitions | **79** entrées `/dev/block/by-name` |
| `super` (dynamique) | system 970 Mo · vendor 850 Mo · product 1,9 Go |
| `userdata` | 110 Go (13 Go utilisés) |
| Treble/GSI | `ro.treble.enabled = true`, `arm64-v8a` |

### État du démarrage sécurisé — **verrouillé**

```
ro.boot.flash.locked        = 1
ro.boot.vbmeta.device_state = locked
ro.boot.verifiedbootstate   = green
ro.secure_boot.state        = 1
ro.boot.avb_version         = 1.3    (AVB actif)
vbmeta digest               = b730f297…42b2a8 (sha256)
```

- **Aucune** propriété `ro.oem_unlock_supported` ni `sys.oem_unlock_allowed` → fastboot ne propose pas de déverrouillage.
- Confirmé par un post XDA sur le T65 exact : *« After enabling OEM unlocking in dev menu… 'flashing unlock'/'OEM unlock' cmd doesn't work. I get: 'Flashing Lock Flag is locked.' »*

### Apps préinstallées système (encore présentes)

`GlobalSidebar`, `floatball`, `SktlDeviceInfo`, `TeclastUserFeedback`, `Traceur`, `Stk`, `BasicDreams`…

> Bonne nouvelle : nos désactivations « niveau 2 » n'ont fait que **désactiver au niveau utilisateur** (`pm disable-user`) — les paquets système sont intacts, donc **tout est réversible**.

---

## 2. Pourquoi on ne peut pas simplement flasher aujourd'hui

Le bootloader est verrouillé **au niveau firmware**, et Unisoc a retiré les commandes de déverrouillage de fastboot. Aucune GSI, aucun Magisk, aucune ROM custom ne peut s'écrire sans casser AVB. **Blocage : le verrou.** Tout le reste en découle.

---

## 3. La piste réelle : exploit BootROM CVE-2022-38694

Faille matérielle (BootROM) documentée par **NCC Group** : on peut écrire un pointeur de fonction avant la fin de la vérification de signature, et donc exécuter son propre code avec les privilèges du BootROM. Le simple fait de faire tourner un `spl-unlock` aux vérifications retirées **bascule le flag de verrou** dans `miscdata`.

### Le SoC est explicitement supporté

Liste officielle du projet (wiki `SupportList`) :

```
ums9230 | T606/T612/T616  T72xx | LPDDR4X | FDL1 0x65000800 | FDL2 0x9efffe00 | eMMC/UFS
```

→ **T7280 = T72xx = supporté.** Notre board `ums9230_6h10` est identique à celui d'appareils déjà déverrouillés.

### Outil de référence

`github.com/TomKing062/CVE-2022-38694_unlock_bootloader` — release **1.72** (~630 ★).
Outils internes : `spd_dump` (protocole SPRD/BROM), `gen_spl-unlock`, `chsize`.

### ⚠️ Piège critique du UFS

Le projet avertit noir sur blanc :

> **« UMS9230 UFS devices: Don't use fdl1/2 of UMS9230 EMMC devices. Don't use UnlockTool. »**
> « ums9230 ufs devices might get erased with fdl from other emmc/ufs devices »

Notre tablette est **UFS** → il faut le paquet UFS, dont le nom porte l'avertissement lui-même :

```
ums9230_universal_unlock_UFS.dangerous.zip
```

**Il n'existe aucun paquet spécifique Teclast T65.** On utiliserait le « universal UFS », ce qui signifie que les offsets FDL ne sont pas validés pour notre modèle exact.

### Précédents réels (source d'espoir ET de prudence)

| Appareil | Board | OS | Résultat |
|---|---|---|---|
| **Teclast T60** (G6A1) | T620 = UMS9230 | Android 14 | Débloqué + rooté **via `ums9230_universal_unlock`** ✔ |
| **Cubot KingKong ES 3** | **`ums9230_6h10`** (identique !) | A/B, UFS | Débloqué + Magisk, **fait depuis macOS** ✔ |
| ATOZEE P12 | UMS9230 (T615) | Android 14 | Débloqué + root ✔ |

Le guide du **Cubot** est le meilleur modèle : même board, UFS, A/B… et fait sous macOS avec `spd_dump` compilé nativement.

---

## 4. La procédure (résumé)

Mode **BROM** = tablette éteinte + appui volume + câble USB. L'appareil apparaît en `1782:4d00`.

1. **Sauvegarde** : dumper `splloader` et `uboot` (les seuls non-récupérables autrement).
2. **Flash du `spl-unlock`** : `spd_dump exec_addr 0x65015f08 fdl spl-unlock.bin 0x65000800` → bascule le flag.
3. **Vérification** : lire `miscdata` — 64 zéros = encore verrouillé ; chaîne + hashes = **déverrouillé** ✔
4. **Restauration** : réécrire `splloader`/`uboot` d'origine + écrire `misc-wipe.bin` → **factory reset**.
5. Résultat attendu : **écran « Orange State »** au démarrage.

Ensuite, deux voies :

- **Voie A — Magisk seul** : root sur la ROM stock (dégraissable réellement ensuite). Le plus raisonnable.
- **Voie B — GSI** (Android 15/16 GSI d'AndyYan) flashée via `fastbootd` : « Android plus léger » au sens strict.

---

## 5. Angles morts (à lire avant de décider)

- **Effacement total obligatoire** (le déverrouillage wipe `userdata`).
- **Aucun test sur T65** : on serait les premiers. Le paquet est littéralement nommé `.dangerous`.
- **BROM = non-brickable en théorie**, mais le PAC stock officiel de secours (**Needrom « Teclast T65 (A6D6) Android-16.0_ROW_V1.10_20260209 »**, uniquement T7280) se reflashe avec **ResearchDownload/UpgradeDownload → Windows uniquement**.
- **UFS risque spécifique** : le mauvais FDL « peut effacer toutes les partitions ».
- **GSI sur Unisoc = chantier** : retours XDA récurrents « not enough space to resize partition » (« pas assez d'espace pour redimensionner »), et parfois **dm-verity impossible à désactiver même déverrouillé**. Résultat incertain après plusieurs heures.
- **Notre Mac est arm64** : `spd_dump` n'est distribué qu'en Linux x86_64 / Windows .exe → il faut le **compiler nativement pour macOS arm64** (dépendance `libusb`), comme l'a fait l'auteur du guide Cubot. Faisable, mais c'est une étape à part entière.

---

## 6. Synthèse des options

| # | Option | Wipe | Risque | Gain |
|---|---|---|---|---|
| 0 | Rester là (dégraissage niveau 1+2) | non | nul | modéré |
| 1 | Mettre à jour vers la ROM officielle ROW (par-dessus, sans unlock) | non | faible | faible |
| 2 | Débloquer + **Magisk root** sur ROM stock | **oui** | **moyen-élevé** | élevé (dégraissage réel) |
| 3 | Débloquer + **GSI** | **oui** | **élevé** | maximal, **incertain** |

---

## Sources

- `github.com/TomKing062/CVE-2022-38694_unlock_bootloader` (release 1.72, wiki SupportList / Unlock)
- `github.com/KiMiGuel/Root-Guide-Cubot-KingKong-ES-3---Unisoc-T615-ums9230-` (macOS, board identique)
- XDA : « Teclast T60 — T620 is essentially a UMS9230 » (unlock/root réussi)
- XDA : « [GUIDE][UNLOCK][ROOT][GSI] Tecno Spark GO 1 » / « ATOZEE P12 UMS9230 »
- XDA tags teclast : T65 = `Flashing Lock Flag is locked`
- Needrom : « Teclast T65 (A6D6) — Android-16.0_ROW_V1.10_20260209 (ONLY Unisoc T7280) »
- NCC Group : *There's another hole in your SoC — Unisoc ROM vulnerabilities* (CVE-2022-38694)
