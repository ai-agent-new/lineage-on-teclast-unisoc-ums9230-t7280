# Audit TECLAST T65 (T65_EEA) — lecture seule
Date : 2026-11-07 · Depuis Mac (adb 37.0.2 / Darwin 27.2.0 arm64) · Série `J014AACGDB00108100`
**Aucune modification apportée à la tablette.**

## 1. Identité & posture de sécurité
| Élément | Valeur |
|---|---|
| Modèle | `T65_EEA` (product/device = `T65`) |
| SoC | Unisoc **UMS9230-AC** (T7280/T620), `ro.boot.auto.efuse=UMS9230S` |
| RAM | 6 Go (`ro.boot.ddr_size=6144M`) |
| Android | **16** (`release=16`, `sdk=36`) |
| Build | `Teclast/T65_EEA/T65:16/BP2A.250605.031.A3/20260413` — **2026-04-13** |
| Patch sécurité | **2026-03-05** |
| Premier API level | 35 (livré avec Android 15, monté en 16) |
| Type build | `user` (non-debuggable, `ro.debuggable=0`, `ro.secure=1`) |
| Bootloader | **verrouillé** — AVB v1.3, `verifiedbootstate=green`, `secure_boot.state=1` |
| Root | **absent** — aucun `su`, aucun Magisk |
| SELinux | **Enforcing** |
| Project Treble | activé (`ro.treble.enabled=true`) |
| WebView | `com.google.android.webview` **156.0.8078.47** (à jour) |
| Profil réseau | pas de proxy, private DNS désactivé, **aucun certificat CA utilisateur** |
| VPN | **aucun tunnel actif** |
| Admins d'appareil | aucun |
| Accessibilité | aucun service activé |
| Écouteurs de notifications | launcher3 uniquement (défaut) |
| Comptes | `…@gmail.com` (Google) + `…` (type `app.revanced` = microG) |

**Verdict posture : très correcte pour un OEM chinois.** Pas de root, pas d'adware FOTA (aucun paquet `adups`/`fota` tiers), pas de service d'accessibilité détourné, pas d'admin caché, WebView à jour.

## 2. Préinstallations OEM (identifiées par la partition)
| Paquet | Emplacement | Rôle | Risque |
|---|---|---|---|
| `com.teclast.teclastuserfeedback` | `/system/preloadapp/TeclastUserFeedback` | **télémétrie / « retour utilisateur » Teclast** | ⚠ vie privée |
| `com.teclast.custom` | `/product/app/TeclastCustom` | personnalisation Teclast | ⚠ **droit d'installer des APK** accordé |
| `com.teclast.globalsidebar` | `/system/app/GlobalSidebar` | barre latérale | ⚠ **droit d'installer des APK** accordé |
| `com.teclast.floatball` | `/system/app/floatball` | boule flottante | faible |
| `com.sprd.engineermode` | `/vendor/app/EngineerMode` | **Unisoc Engineering Mode** (test radio/RF) | ⚠ surface usine |
| `com.sprd.logmanager` | `/vendor/app/LogManager` | capture de logs système | ⚠ confidentialité |
| `com.sprd.validationtools` | `/product/app/ValidationTools` | tests d'usine | faible |
| `com.sprd.uasetting`, `com.sprd.linkturbo`, `com.sprd.omacp`, `com.sprd.providers.photos`, `com.spreadtrum.sgps`, `com.spreadtrum.proxy.nfwlocation`, `com.unisoc.tui` (`/product/app/TuiAuxiService`), `com.unisoc.silent.reboot` | système/vendor/product | pile Unisoc/Spreadtrum (radio, GPS, IMS) | faible mais bruit |
| Overlays `android.unisoc.*` (×10) | système | thèmes/ressources Unisoc | aucun |

Aucun composant **exporté** sur les apps Teclast (`custom`, `globalsidebar`, `floatball`) → surface d'attaque externe nulle de ce côté.

## 3. Applications tierces installées (hors ROM)
Installées **via Google Play le 2026-11-05** (cluster 19:27–19:34) sauf les deux ReVanced :

| Paquet | Version | Installateur | Date |
|---|---|---|---|
| `app.revanced.android.youtube` | 20.40.45 | packageinstaller (sideload) | 05/11 19:40 |
| `app.revanced.android.gms` | 0.3.13.2… | packageinstaller (sideload) | 05/11 19:44 |
| `com.brave.browser` | 1.98.63 | Play | 05/11 19:27 |
| `com.nordvpn.android` | 9.16.1 | Play | 05/11 19:32 |
| `com.netflix.mediaclient` | 9.90.1 | Play | 05/11 19:32 |
| `com.amazon.avod.thirdpartyclient` | 3.0.477.1447 | Play | 05/11 19:32 |
| `applock.lockapps.fingerprint.password.lockit` | 1.7.5 | Play | 05/11 19:31 |
| `com.logicappkids` | 3.11.1 | Play | 05/11 19:31 |
| `com.pazugames.avatarworld` | 1.228 | Play | 05/11 19:33 |
| `com.orange.kidspiano.music.songs` | 3.79 | Play | 05/11 19:34 |
| `com.edujoy.dentist` | 17.8 | Play | 05/11 19:34 |
| `com.google.android.{contactkeys,safetycore,verifier}` | — | Play (modules Google normaux A16) | 05/11 19:34 |

> ⚠️ Ambiguïté à clarifier : le lot Netflix + Prime Video + NordVPN + **4 jeux enfants** (logicappkids, avatarworld, kidspiano, edujoy.dentist) + AppLock ressemble à un **bundle de préchargement appliqué au premier démarrage** typique des tablettes Teclast, mais l'horodatage correspond aussi à une installation manuelle. **À confirmer par [REDACTED_USER] : l'a installé lui-même ou apparu tout seul ?**

## 4. Applications déjà désactivées (par l'utilisateur ou l'OEM)
`com.android.chrome`, `com.google.android.youtube`, `com.google.android.gm`, `com.google.android.apps.docs`, `com.google.android.videos`, `com.google.android.googlequicksearchbox`, `com.google.android.apps.tachyon`, `com.google.android.projection.gearhead`, `com.google.android.apps.restore`, `com.google.android.gms.supervision`, `com.android.nfc`, `com.android.devicelockcontroller`, `com.android.virtualization.terminal`, `com.sprd.powersavemodelauncher`.

## 5. Réponse à la question d'origine (remplacement d'OS)
**Non — impossible sur ce modèle.** Bootloader verrouillé (`Flashing Lock Flag is locked`), aucune ROM custom / GSI validée pour `T65_EEA`, firmware officiel Teclast non rooté, outils de flash Unisoc **Windows uniquement**. Le seul levier réaliste sur Mac = **allègement par ADB** (ci-dessous), réversible.

## 6. Fichiers bruts
`raw/getprop.txt`, `raw/pm_thirdparty.txt`, `raw/pm_system.txt`, `raw/pm_disabled.txt`, `raw/dumpsys_packages.txt`.
