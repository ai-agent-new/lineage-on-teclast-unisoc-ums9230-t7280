#!/bin/bash
# ROLLBACK Niveau 2 — TECLAST T65 — exécuté le 2026-11-07
# Réactive les 8 paquets OEM/Unisoc désactivés. Rien n'est perdu.
export PATH="/opt/homebrew/bin:$PATH"

for p in \
  com.teclast.teclastuserfeedback \
  com.teclast.custom \
  com.teclast.globalsidebar \
  com.teclast.floatball \
  com.sprd.engineermode \
  com.sprd.logmanager \
  com.sprd.validationtools \
  com.sprd.uasetting ; do
  echo -n "$p -> "
  adb shell pm enable "$p" 2>&1 | tr -d '\r'
done

echo
echo "=== vérif : ne doivent plus apparaître dans 'pm list packages -d' ==="
adb shell "pm list packages -d" | grep -E "teclast|sprd" | sort
