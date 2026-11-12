# PHASE A — FEUILLE DE COMMANDES FDL2 (LECTURE SEULE)
## Teclast T65 · UMS9230S / T7280 · `ums9230_6h10` · UFS · A/B

> **Règle absolue : cette phase n'écrit RIEN.** Aucune commande `w`, `write_part`, `wof`, `wov`,
> `e`, `erase_part`, `erase_all` n'apparaît ici. Garde-fou : toute commande de la liste ci-dessous
> commence par `r`, `read_`, `p`, `partition_list`, `path`, `verbose`, `blk_size`, `size_part`,
> `check_part` ou `reset` — à l'exception de la mesure de l'état de verrouillage (`read_part miscdata`),
> qui est également une **lecture**.

---

## 0. Leçon apprise — pourquoi cette version diffère de la précédente

| Problème constaté | Cause racine | Correctif |
|---|---|---|
| `LIBUSB_ERROR_TIMEOUT` sur le one-liner | Le chaînage complet sur la ligne de commande est instable sur macOS | **Mode interactif `FDL2>`** (documenté officiellement) |
| `usb_recv failed` / `CHECK_BAUD` manquant | `spd_dump` sondait l'USB toutes les **2 000 ms** alors que la fenêtre BROM ne dure que **~3 s** | **`REOPEN_FREQ` 2 → 50** : sondage toutes les **~80 ms** (recompilé) |
| Device « disparu » après la manip | La tablette quitte le BROM dès que les boutons sont relâchés | **Garder les boutons enfoncés** jusqu'à confirmation de connexion |

---

## 1. Lancement de la session

```
cd "<LOCAL_PROJECT_DIR> T65/02_unlock_package/UFS_package"
./spd_dump --wait 900 \
    exec_addr 0x65015f08 \
    fdl fdl1-dl.bin 0x65000800 \
    fdl fdl2-dl.bin 0x9efffe00 \
    exec
```

**Attendu** (log sain) :
```
libusb_control_transfer ok
CHECK_BAUD bootrom          <-- si cette ligne apparaît, c'est GAGNÉ
BSL_REP_VER: "SPRD3\0"
CMD_CONNECT bootrom
EXEC FDL1
... EXEC FDL2 ...
FDL2>
```

**Si `CHECK_BAUD FAIL`** → ne pas débrancher, ne pas redémarrer, **relancer immédiatement** (doc officielle Hotwav).

---

## 2. Commandes au prompt `FDL2>` — dans cet ordre

### 2.1 Préparation (aucune écriture)
```
verbose 2
path <LOCAL_PROJECT_DIR> T65/04_backup/brom
blk_size 65535
```

### 2.2 RELEVER LA TABLE DE PARTITIONS — obligatoire avant tout

```
p
partition_list <LOCAL_PROJECT_DIR> T65/04_backup/brom/partition_list.txt
```

> ⚠️ Ne JAMAIS supposer les noms. Sur cette carte mère le `.bat` officiel utilise
> `splloader`, `splloader_bak`, `uboot`, `uboot_bak`, `misc`, `miscdata`, `boot` —
> **mais seule la sortie de `p` fait foi.** Noter aussi les tailles exactes.

### 2.3 Filet de sécurité IMMÉDIAT (rapide, quelques Mo) — les partitions critiques
*(adapter les noms à la sortie de `p`)*

```
r splloader
r splloader_bak
r uboot
r uboot_bak
r misc
r boot
r vbmeta
r init_boot
```

> Ces fichiers sont **la seule chose qui rend un brick réversible**. Le guide Cubot a récupéré
> son appareil exactement comme ça ; l'auteur Hotwav n'avait rien et a tout perdu.

### 2.4 BASELINE de l'état de verrouillage — LECTURE (64 octets)
```
read_part miscdata 8192 64 miscdata_avant.bin
```
> Interprétation officielle (`.bat`) : **64 octets nuls = verrouillé** ;
> **32 caractères + 16 octets de hash + 16 octets de hash = déverrouillé.**
> On enregistre la valeur AVANT, pour comparer APRÈS le déverrouillage.

### 2.5 Sauvegarde COMPLÈTE (long — dizaines de minutes)
```
r all
```
> `r all` = sauvegarde complète **hors** `blackbox`, `cache`, `userdata`.
> On prend `all` et non `all_lite` car `all_lite` **exclut le slot inactif** (`uboot_b`, `boot_b`…),
> or c'est justement ce qu'un script de restauration peut avoir à réécrire.

### 2.6 Bouclage
```
reset
```

---

## 3. Vérifications APRÈS la session (côté Mac, sans toucher la tablette)

```
cd "<LOCAL_PROJECT_DIR> T65/04_backup/brom"
ls -la
shasum -a 256 * > ../SHA256_BACKUP_BROM.txt
```

- [ ] `splloader*` et `uboot*` présents et **non nuls**
- [ ] `partition_list.txt` non vide
- [ ] `miscdata_avant.bin` = **exactement 64 octets**
- [ ] SHA-256 calculés
- [ ] **Copie des fichiers critiques vers un SECOND support** (clé USB / autre disque) ← correctif n°2

---

## 4. Porte GO / NO-GO vers la Phase B

| Critère | Exigence |
|---|---|
| Prompt `FDL2>` atteint | ✅ oui |
| Partitions critiques sauvegardées | ✅ `splloader`, `uboot`, `misc`, `boot`, `vbmeta` |
| `partition_list.txt` obtenu | ✅ |
| État `miscdata` AVANT enregistré | ✅ 64 octets |
| PAC stock officiel téléchargé + vérifié | ✅ 2,75 Go |
| SHA-256 calculés + copie hors Mac | ✅ |

**Si un seul critère manque → PAS de Phase B.**

---

## 5. Rappel — la commande de restauration (déjà écrite, PAS exécutée)

Issue du `.bat` officiel (à adapter aux noms réels et aux fichiers que NOUS aurons dumpés) :

```
w uboot <notre_uboot_original.bin>
w splloader <notre_splloader_original.bin>
w misc misc-wipe.bin
reset
```

> Cette commande est écrite **maintenant**, pour ne pas avoir à l'improviser sous stress le jour où
> elle sera nécessaire. C'est précisément l'erreur qui a coûté son appareil à l'auteur Hotwav.
