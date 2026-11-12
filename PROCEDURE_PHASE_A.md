# PROCÉDURE PHASE A — Sauvegarde technique (lecture seule)

> Teclast T65 (Unisoc UMS9230S / T7280) — exploit CVE-2022-38694
> **Ce qui est fait ici N'ÉCRIT RIEN sur la tablette.**

---

## 1. Avant de commencer

| Contrôle | Exigence |
|---|---|
| Batterie tablette | **> 50 %** (idéalement 100 %) |
| Câble USB | **câble de données** (pas un câble de charge seul), port USB-A du Mac de préférence |
| Tablette | **ÉTEINTE complètement** (pas en veille) |
| Espace Mac | ~10 Go libres pour la sauvegarde |

> ⚠️ Ne pas brancher par un hub USB-C si possible. Un port USB-A direct est le plus fiable.

---

## 2. Entrer en mode BROM

Le T65 n'a **pas** de bouton dédié. Il faut la combinaison clavier, à essayer **dans cet ordre**
(la documentation officielle de l'exploit précise : *« power + vol up » / « power + vol down » (le plus courant) / « power + vol up + vol down »*) :

1. **Tablette éteinte**, débranchée.
2. Maintenir **Power + Vol+**.
3. **Sans relâcher**, brancher le câble USB au Mac.
4. Maintenir encore **7 à 10 secondes**, puis relâcher.

Si le Mac ne voit rien, recommencer avec :
- **Power + Vol−**
- **Power + Vol+ + Vol−**

**Indice que ça marche** : l'écran reste noir (aucun logo), et le Mac détecte un périphérique USB Unisoc.
On le vérifie par :
```bash
system_profiler SPUSBDataType | grep -iA3 -E "spreadtrum|unisoc|1782"
```
L'identifiant attendu est **`1782:4d00`** (ou `1782:4d01` en FDL1).

> Si aucun des trois ne fonctionne, il faudra passer par un **testpoint sur la carte mère** — on s'arrêtera et on en discutera.

---

## 3. Lancer la sauvegarde

```bash
cd "<LOCAL_PROJECT_DIR> T65/02_unlock_package/UFS_package"
./PHASE_A_sauvegarde.sh
```

Ce que le script fait, **en lecture seule** :

| Étape | Commande | Effet |
|---|---|---|
| **A1** | `exec_addr 0x65015f08` + `fdl` + `exec verbose 2 p` | Se connecte en BROM via l'exploit et **affiche la liste des partitions** |
| **A2** | `r all_lite` | **Lit** toutes les partitions (hors `userdata`, `blackbox`, `cache` et slot inactif) vers `04_backup/brom/` |

- Durée : **10 à 20 min** (≈ 8-10 Go en USB 2.0).
- Fichiers attendus : `splloader.bin`, `uboot_a.bin`, `boot_a.bin`, `vbmeta_a.bin`, `miscdata.bin`, `prodnv.bin`, `super.bin`…

**Aucune commande d'écriture** n'est présente dans le script (vérifié automatiquement : `w`, `write_part`, `erase_all`, `repartition` sont absents).

---

## 4. Fin de phase A

Le script termine par `reset` → la tablette **redémarre normalement**.

Vérifications finales :
- [ ] `04_backup/brom/splloader.bin` présent (256 Ko) → **indispensable** pour `gen_spl-unlock`
- [ ] `04_backup/brom/uboot_a.bin` présent → deviendra `uboot_bak.bin`
- [ ] taille totale de `04_backup/brom/` cohérente (~8-10 Go)

Puis **STOP**. Le déverrouillage (phase B) nécessite une **nouvelle autorisation explicite**.
