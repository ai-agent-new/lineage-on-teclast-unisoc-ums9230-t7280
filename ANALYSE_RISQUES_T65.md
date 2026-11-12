# ANALYSE DES RISQUES — Teclast T65 (UMS9230S / T7280) — Déverrouillage + LineageOS 23.2

> Rédigé après lecture intégrale des sources primaires : dépôt `TomKing062/CVE-2022-38694_unlock_bootloader`,
> `unlock_autopatch_9230.bat` officiel, `gen_spl-unlock.c`, `stack-info-ums9230.csv`,
> guide XDA Cubot KingKong ES 3 (même carte mère `ums9230_6h10`), guide XDA Hotwav T606.

---

## 0. CORRECTION DE MES PROPRES PROPOS

Ce que j'ai écrit dans le chat était **imprécis** et je le corrige :

| Ce que j'ai dit | Réalité (source : guide Hotwav, texte intégral) |
|---|---|
| « l'auteur a brické à cause du Secure Boot hardware-enforced » | **FAUX.** L'auteur écrit : *« My phone is still bricked. **I don't have the stock firmware.** »* et *« I ran a command I didn't fully understand. And it cost me. »* |
| « une GSI ne bootera pas si Secure Boot est hardware-enforced » | **VRAI mais c'est autre chose** : l'encadré `secure: yes` dit *« You need stock firmware. GSIs won't boot. »* → c'est un avertissement sur **l'objectif GSI**, pas sur la brique. |

**Conclusion corrigée : la brique définitive vient de l'ABSENCE D'IMAGE DE RESTAURATION, pas du Secure Boot.**

---

## 1. POURQUOI LE T65 EST DANS UNE POSITION BEAUCOUP PLUS SÛRE

Le facteur unique qui a tué l'appareil Hotwav est **précisément celui que nous avons déjà couvert**.

| Critère | Hotwav T606 | Cubot ES3 (succès) | **Teclast T65** |
|---|---|---|---|
| Carte mère identique à un succès prouvé | ❌ | ✅ `ums9230_6h10` | ✅ **`ums9230_6h10` (identique)** |
| Firmware stock disponible | ❌ **NON → mort définitive** | ✅ extrait du `.pac` | ✅ **officiel Teclast 2,75 Go** |
| Sauvegarde avant écriture | ❌ | ⚠️ partielle | ✅ **`all_lite` complète prévue** |
| Outillage compilé/macOS | ❌ | ✅ | ✅ **fait et testé** |
| Issue observée | ☠️ perdu | ✅ brické **puis récupéré** | — |

Le guide Cubot dit explicitement : *« Bricking is part of the process — **Recovery is possible by flashing stock lk-sign.bin back** »*.
Autrement dit : **un brick n'est définitif QUE sans image de restauration.**

---

## 2. GARANTIE STRUCTURELLE : LA BROM EST INALTÉRABLE

Le mode BROM réside dans la **ROM de masque** du SoC — gravée en usine, **jamais réinscriptible**.
Elle s'exécute **avant** le splloader, donc :

> **Aucune écriture sur la mémoire flash ne peut détruire l'accès au mode BROM.**

Corollaire : tant que (a) la BROM reste joignable — **prouvé**, elle l'est — et (b) on possède une copie
d'origine des partitions écrasées, **la restauration est toujours possible**. C'est exactement pourquoi
l'auteur Hotwav a échoué et l'auteur Cubot a réussi.

---

## 3. LES 7 ERREURS DES GUIDES — ET NOS CORRECTIFS

| # | Erreur constatée | Correctif appliqué |
|---|---|---|
| 1 | Aucune sauvegarde avant d'écrire | **Phase A** : `r all_lite` + `splloader` + `uboot` **avant tout `w`** |
| 2 | Sauvegarde sur la seule machine | SHA-256 de chaque fichier + **copie hors Mac** |
| 3 | Pas de firmware stock | **PAC officiel Teclast** téléchargé, intégrité vérifiée (`.rar` testé) |
| 4 | Écriture sans connaître la table de partitions | **`p\|print` + `partition_list`** exportés **avant** toute écriture |
| 5 | Aucune répétition de la restauration | **Script de restauration écrit et testé AVANT** d'en avoir besoin |
| 6 | État Secure Boot inconnu | Vérifié avant écriture (voir §5) |
| 7 | One-liner instable sur macOS | **Mode interactif `FDL2>`** — déjà corrigé, c'était la cause du `LIBUSB_ERROR_TIMEOUT` |

---

## 4. LE `.bat` OFFICIEL CONTIENT DÉJÀ DEUX FILETS DE SÉCURITÉ

`unlock_autopatch_9230.bat` (source officielle, 27 lignes) :

### 4.1 Une VÉRIFICATION OBJECTIVE du déverrouillage
```
spd_dump ... exec verbose 2 read_part miscdata 8192 64 m.bin reset
:: check unlock (if get 64 zeros, locked; if 32 string + 16 hash + 16 hash, unlocked)
```
→ **64 octets nuls = verrouillé ; 32 car. + 16 hash + 16 hash = déverrouillé.**
Aucune interprétation subjective : on lit l'état réel.

### 4.2 Une RESTAURATION DÉTERMINISTE
```
spd_dump ... exec r boot w splloader u-boot-spl-16k-sign.bin w uboot uboot_bak.bin w misc misc-wipe.bin reset
```

### 4.3 Le fichier « manquant » n'en est pas un — RÉSOLU
`gen_spl-unlock` (lu intégralement, source C) prend le `splloader.bin` **dumpé** et produit **deux fichiers** :
- `splloader.bin` → **patché** (4 instructions remplacées par `NOP` = `0xD503201F` → bypass vérification signature)
- `spl-unlock.bin` → **le payload de déverrouillage**

→ `spl-unlock.bin` est **GÉNÉRÉ**, pas téléchargé. Chaîne complète, aucune pièce manquante.

---

## 5. ÉTAT SECURE BOOT — À VÉRIFIER AVANT ÉCRITURE (porte GO/NO-GO)

**Test décisif, sans risque** : si `exec_addr 0x65015f08` s'exécute et que le prompt `FDL2>` devient
disponible, alors on a **exécution non signée** → le Secure Boot **est déjà contourné** pour notre usage.

Indices déjà collectés sur le T65 : `verifiedbootstate = green`, `flash.locked = 1`, `vbmeta.dev_state = locked`.

**Porte** : si l'exploit fonctionne → GO. Si la BROM refuse → NO-GO, aucun risque pris.

---

## 6. LE RISQUE RÉELLEMENT IRRÉDUCTIBLE

| Phase | Écrit sur la tablette ? | Risque |
|---|---|---|
| Phase A — sauvegarde | ❌ **lecture seule** | **NUL** |
| Phase B — `w uboot fdl2-cboot.bin` + `fdl spl-unlock.bin` | ✅ oui | ⚠️ **c'est ICI que le Cubot a montré un écran noir** |
| Phase B — `w splloader` (patché) | ✅ oui | ⚠️ idem |
| Restauration | ✅ oui | récupération |

**Le seul moyen de perdre définitivement l'appareil** = écraser une partition **sans** en posséder l'original.
→ Nous posséderons `all_lite` + le PAC stock. **Condition remplie.**

---

## 7. OBJECTIF « LINEAGEOS 23.2 » — HONNÊTETÉ

- Le précédent de **même carte mère** (Cubot) a obtenu **déverrouillage + root Magisk sur ROM stock**.
- Il **n'a PAS flashé de GSI**. Donc « le T65 bootera-t-il une GSI LineageOS 23.2 ? » reste **INCONNU**.
- **Échec de boot GSI ≠ brique** : on reflashe le stock. Mais l'objectif « LineageOS » peut échouer.

### Recommandation : découper en deux paliers

| Palier | Contenu | Prévisibilité |
|---|---|---|
| **1** | Déverrouillage + root sur **ROM stock**, puis débloat profond | ✅ **prouvé sur cette carte mère** |
| **2** | Flash de la **GSI LineageOS 23.2** (déjà téléchargée et vérifiée) | ⚠️ inconnu, restauration stock si échec |

Le palier 1 répond déjà à l'objectif initial (« Android plus léger ») **sans le risque du palier 2**.
Le palier 2 reste possible, mais comme une **expérience réversible**.

---

## 8. DÉCISION

Aucune écriture n'a eu lieu sur la tablette. Rien ne sera écrit avant un **GO explicite**.

- **GO Phase A** (sauvegarde complète, lecture seule) → **risque nul**, c'est le correctif n°1.
- **GO Phase B** (déverrouillage) → à donner **après** Phase A verte et PAC vérifié.
