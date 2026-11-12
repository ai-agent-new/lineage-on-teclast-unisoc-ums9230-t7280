#!/bin/bash
# ============================================================
#  T65 — ALLÈGEMENT PAR ADB  (NON EXÉCUTÉ — à valider par [REDACTED_USER])
#  Méthode : pm disable-user --user 0  => RÉVERSIBLE (pm enable)
#  Rien n'est supprimé définitivement. Réinitialisation usine
#  restaure tout de toute façon.
# ============================================================
export PATH="/opt/homebrew/bin:$PATH"

# --- BLOC A : télémétrie / surcouche Teclast (SANS RISQUE) ---
adb shell pm disable-user --user 0 com.teclast.teclastuserfeedback   # télémétrie
adb shell pm disable-user --user 0 com.teclast.custom                # ⚠ détenait droit d'installer des APK
adb shell pm disable-user --user 0 com.teclast.floatball
# adb shell pm disable-user --user 0 com.teclast.globalsidebar       # barre latérale — DÉCOMMENTER si non utilisée

# --- BLOC B : outils d'usine Unisoc (SANS RISQUE) ---
adb shell pm disable-user --user 0 com.sprd.engineermode
adb shell pm disable-user --user 0 com.sprd.logmanager
adb shell pm disable-user --user 0 com.sprd.validationtools
adb shell pm disable-user --user 0 com.sprd.uasetting

# --- BLOC C : apps tierces à confirmer (une par une) ---
# adb shell pm uninstall -k --user 0 com.logicappkids                     # jeu enfant
# adb shell pm uninstall -k --user 0 com.pazugames.avatarworld            # jeu enfant
# adb shell pm uninstall -k --user 0 com.orange.kidspiano.music.songs     # jeu enfant
# adb shell pm uninstall -k --user 0 com.edujoy.dentist                   # jeu enfant
# adb shell pm uninstall -k --user 0 com.amazon.avod.thirdpartyclient     # Prime Video
# adb shell pm uninstall -k --user 0 com.netflix.mediaclient              # Netflix
# adb shell pm uninstall -k --user 0 com.nordvpn.android                  # NordVPN
# adb shell pm uninstall -k --user 0 applock.lockapps.fingerprint.password.lockit

# --- BLOC D : apps Google désactivables (optionnel, gain RAM) ---
# adb shell pm disable-user --user 0 com.google.android.apps.maps
# adb shell pm disable-user --user 0 com.google.android.apps.photos

# ============================================================
#  ANNULATION TOTALE (rollback)
#  adb shell pm enable <paquet>            # pour les "disable-user"
#  adb shell cmd package install-existing <paquet>   # pour les "uninstall -k"
# ============================================================
