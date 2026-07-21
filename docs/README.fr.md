# Moniteur de prix

> Outil local macOS qui suit les prix et le stock de boutiques sélectionnées, ainsi que le solde et l’usage récent de l’API WOYAO dans la barre des menus.

[简体中文](../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Français**

## Fonctions

- Regroupe les produits comparables et les trie du prix le plus bas au plus élevé.
- Vérifie les boutiques chaque minute et annonce vocalement les nouveaux articles ou réassorts.
- Affiche le solde WOYAO actuel directement dans la barre des menus.
- Actualise l’usage toutes les heures et annonce le solde, le quota consommé et le coût du jour.
- Affiche les dix derniers appels avec modèle, coût, tokens et heure.

## Démarrage rapide

1. Téléchargez `PriceMonitor-v1.4-macOS-arm64.zip` depuis [Releases](../../releases/latest), décompressez-le puis placez l’app dans Applications.
2. Ouvrez l’app une première fois. Pour un lancement à la connexion, installez le modèle utilisateur `LaunchAgent.plist`.
3. Ouvrez **Utilisation WOYAO**, collez votre API Key et choisissez **Enregistrer dans Documents et lire**.

## Confidentialité

Les données des boutiques proviennent d’API publiques. La clé WOYAO est stockée uniquement dans `Documents/价格监控/woyao-api-key.txt`; elle n’est jamais écrite dans Git, les journaux ordinaires ni les données du navigateur. Ne synchronisez pas ce fichier en clair vers un stockage public.

## Compilation et licence

macOS, Xcode Command Line Tools et Swift 6 sont nécessaires. Exécutez `./build_app.sh` pour créer `价格监控.app`.

Ce projet est publié sous [MIT License](../LICENSE).
