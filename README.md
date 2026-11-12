# Lineage on TECLAST Unisoc UMS9230/T7280

Documentation de retour d’expérience pour l’installation d’une GSI LineageOS 23.2 (Android 16) sur une Teclast T65_EEA équipée d’un SoC Unisoc UMS9230/T7280 et d’un stockage UFS.

> **Avertissement :** cette procédure est expérimentale et peut rendre l’appareil inutilisable. Elle est fournie à titre documentaire, sans garantie. Vérifiez les fichiers, les partitions et le modèle exact avant toute opération.

## Contenu

- Procédure complète d’installation et reconstruction de `super`
- Déverrouillage Unisoc/BROM et séquence FDL2
- Analyse des risques et contrôles préalables
- Rapport d’audit et rapport ROM/flash
- Scripts de rollback et de debloat à examiner avant utilisation

## Présentation générale

Ce dépôt propose une méthode documentée pour étudier, préparer et installer une image GSI LineageOS sur une tablette TECLAST basée sur la plateforme Unisoc UMS9230/T7280. Il s'agit d'un retour d'expérience technique et non d'une procédure universelle : chaque modèle doit être vérifié séparément avant toute opération.

La méthode couvre les phases suivantes :

1. identifier précisément le modèle, la variante régionale, le SoC, le type de stockage et l'état du bootloader ;
2. sauvegarder les partitions et réunir les fichiers de restauration correspondant exactement à l'appareil ;
3. vérifier la compatibilité de l'image GSI, du noyau, du partitionnement dynamique et des systèmes de fichiers ;
4. préparer l'environnement Unisoc/BROM/FDL2 et contrôler chaque commande avant exécution ;
5. adapter ou reconstruire `super` lorsque cela est nécessaire ;
6. flasher par étapes contrôlées, puis effectuer le premier démarrage et les vérifications fonctionnelles ;
7. conserver une procédure de retour arrière et documenter les résultats, anomalies et limites.

## Risques et précautions

- Une image ou une partition incorrecte peut empêcher le démarrage, provoquer une boucle de démarrage ou nécessiter une restauration complète.
- Une erreur pendant BROM/FDL2, le déverrouillage ou le flash peut entraîner une perte de données ou un appareil non fonctionnel.
- Le déverrouillage du bootloader peut effacer les données et réduire certaines protections de sécurité.
- La compatibilité GSI ne garantit pas le fonctionnement de la caméra, de l'audio, de la téléphonie, du Wi-Fi, du Bluetooth, de la veille ou de l'accélération graphique.
- Les opérations doivent être arrêtées si le modèle, la variante, les partitions ou les fichiers de restauration ne correspondent pas exactement.
- Ne jamais utiliser une sauvegarde, une image ou un script provenant d'un autre appareil sans validation technique explicite.

## Conditions de réussite

L'installation ne doit être considérée comme réussie que si :

- l'appareil démarre plusieurs fois sans boucle de démarrage ;
- la version Android et la GSI attendues sont correctement détectées ;
- le stockage interne et les partitions principales restent accessibles ;
- le réseau, le Wi-Fi, le Bluetooth, l'audio, l'affichage, la caméra et les capteurs essentiels ont été testés ;
- aucune erreur critique de montage, de chiffrement ou de vérification de l'intégrité ne subsiste ;
- la méthode de restauration a été vérifiée ou, au minimum, les fichiers nécessaires sont disponibles ;
- les limites et les fonctions non testées sont explicitement consignées.

## Sources externes

- [TomKing062/CVE-2022-38694_unlock_bootloader](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader)
- [LineageOS GSI](https://lineageos.github.io/lineageos_gsi/)

## État documenté

Installation réalisée sur une Teclast T65_EEA avec LineageOS 23.2 GSI Android 16. Les détails propres à une installation donnée doivent être adaptés après vérification locale.
