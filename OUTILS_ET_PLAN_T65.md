# Outils & plan — T65 : Android plus léger, plus fluide, moins gourmand
Recherche du 2026-11-07. Tous les liens vérifiés.

## A. Outils pour alléger / optimiser (sans root)

| Outil | Type | Rôle | Lien |
|---|---|---|---|
| **UAD-NG** (Universal Android Debloater Next Gen) | GUI Rust, Mac/Win/Linux | Le standard. Supprime/désactive le bloat système **via ADB**, avec une liste communautaire de ~1000 paquets annotés (recommandé / avancé / expert / à ne pas toucher). Dernière version **v1.3.1 (02/11/2026)**. | github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation |
| **Canta** | APK Android | Désinstalle des apps système **sans PC**, via Shizuku. Intègre la même liste UAD pour les recommandations. Restauration intégrée. | github.com/samolego/Canta |
| **Shizuku** | APK Android | Donne à Canta les droits ADB **sur la tablette** (débogage sans fil). **Android 16 → utiliser le fork** `thedjchi/Shizuku`. | github.com/thedjchi/Shizuku |
| **App Manager** (MuntashirAkon) | APK Android | Coude à coude avec Canta : gère permissions, appops, services, trackers, blocage de composants. | github.com/MuntashirAkon/AppManager |
| **Android-battery-optimizer** (Aatricks) | Python CLI + dashboard web | **Le plus sûr pour la batterie** : snapshot avant chaque changement, `--dry-run`, rollback `revert`, whitelist. Agit sur Doze, appops, standby buckets. | github.com/Aatricks/Android-battery-optimizer |
| **Greenify** (oasisfeng) | APK Android | Hibernation d'apps + « Aggressive Doze ». Nécessite 2 grants ADB (`WRITE_SECURE_SETTINGS`, `READ_LOGS`). | Play Store |
| **Island** (oasisfeng) | APK Android | Isolement en profil de travail : les apps gelées ne tournent plus du tout. | Play Store |
| **scrcpy** | CLI Mac | Miroir/contrôle de l'écran depuis le Mac (utile pour tout piloter au clavier). | github.com/Genymobile/scrcpy |
| **SD Maid SE** | APK Android | Nettoyage, purge de caches, gestion du démarrage des apps. | github.com/d4rken-org/sdmaid-se |

### Launchers légers (si tu veux remplacer celui d'origine)
| Launcher | Poids | Note |
|---|---|---|
| **OLauncher** / **eLauncher** | ~700 Ko–1,8 Mo | Ultra-minimal, texte seul, 0 service en fond. Idéal pour une tablette à faible RAM. |
| **Mako** | léger | Kotlin natif, privacy-first, suivi batterie intégré. |
| **Niagara Launcher** | léger | Liste verticale, très économe, très fluide. |
| **Set As Launcher (SAL)** | < 30 Ko | Utilitaire qui transforme n'importe quelle app en launcher. |

> **Note importante pour TON cas** : le T65 tourne déjà sous **AOSP Launcher3** (`com.android.launcher3/SearchLauncher`) — pas une surcouche lourde. Le gain d'un launcher tiers sera **faible**. À ne faire que si tu veux le look.

## B. Mesures réelles sur ta tablette (2026-11-07)

| Métrique | Valeur | Lecture |
|---|---|---|
| Capacité batterie | **8000 mAh** (apprise 7800) | belle réserve |
| **Autonomie écran allumé estimée** | **8 h 36 min** | déjà très correct |
| Décharge en Doze (veille profonde) | **0 mAh** | **Doze fonctionne parfaitement** → pas de fuite en veille |
| Décharge écran éteint | 117 mAh / 41 min | normal |
| Charge CPU mesurée | `system_server` 19 %, **GMS 8,8 %**, SystemUI 4,2 %, Photos 3 %, **NordVPN 1,9 %**, launcher 1,4 % | GMS = plus gros poste logiciel |
| Services actifs | 88 | à réduire |
| Stockage | 13 Go / 110 Go utilisés (13 %) | pas un problème |
| Animation scales | 1.0 / 1.0 | passables à 0.5 pour la fluidité perçue |
| Écran | 1200×1920, densité 280 | — |

**Diagnostic : la tablette n'a pas de gros problème de batterie** (Doze OK, 8h36 d'écran). Les leviers restants sont : le bruit système (88 services, GMS), la surcouche Teclast/Unisoc, et la fluidité perçue.

## C. Plan en 3 niveaux (tout réversible)

**Niveau 1 — Fluide & sobre, sans rien supprimer (gain de perception immédiat)**
- animations 1.0 → 0.5
- désactiver la recherche/NLU prédictive inutile, ad tracking (volet pubs)
- Private DNS AdGuard (`dns.adguard.com`) → coupe le trafic pub, gain réseau + batterie
- « Mise en veille des apps » : activer sur les apps peu utilisées (Android 16 est agressif)
- Photos : désactiver le traitement en fond / ou l'app si non utilisée

**Niveau 2 — Allègement du bruit constructeur (réversible, `pm disable-user`)**
- `com.teclast.teclastuserfeedback` (télémétrie)
- `com.teclast.custom`, `com.teclast.globalsidebar` (⚠ détenaient le droit d'installer des APK), `com.teclast.floatball`
- `com.sprd.engineermode`, `com.sprd.logmanager`, `com.sprd.validationtools`, `com.sprd.uasetting` (outils d'usine Unisoc)

**Niveau 3 — Batterie avancée (outil dédié, snapshot + rollback)**
- lancer `Android-battery-optimizer` en `--dry-run` puis `apply-safe`
- `smart-restrict` sur les apps non essentielles, avec whitelist (Netflix, NordVPN si tu veux les garder réactifs)

## D. Ce qui n'est PAS possible
- Flasher une ROM/GSI custom : **bootloader verrouillé**, pas de firmware déverrouillable, outils Unisoc Windows-only.
- Root : aucun exploit public propre pour UMS9230 + Android 16 sur ce modèle.
