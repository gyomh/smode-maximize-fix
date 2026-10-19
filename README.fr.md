# Smode MaximizeFix

*[English version](README.md)*

Un petit outil Windows pour les utilisateurs de **Smode Compose** qui gardent la **barre des tâches de Windows en
haut de l'écran** (StartAllBack, ExplorerPatcher, Windows 10...) : quand Smode est agrandi, chaque clic tombe à
côté de ce qui est affiché (d'environ la hauteur de la barre des tâches). Avec cet outil lancé, le bouton
d'agrandissement fonctionne normalement.

**Ce n'est pas un outil officiel de Smode Tech.** Il ne modifie pas Smode : il déplace seulement la fenêtre de
Smode, comme vous le feriez à la main.

## Le problème

Avec la barre des tâches en haut, Smode agrandi réagit à environ une hauteur de barre de l'endroit où vous
cliquez. Une fenêtre normale (non agrandie), réglée à la main pour remplir l'écran sous la barre des tâches,
fonctionne bien.

Ce qui se passe (mesuré sur un écran 3200x2000 à 200 %, barre des tâches de 80 px en haut) : Windows place la
fenêtre agrandie sous la barre des tâches, mais Smode dessine comme si la barre n'existait pas : sa zone de dessin
commence au coin de l'écran, `(0, 0)`, et mesure `3200 x 2080` px, au lieu de commencer à `y = 80`
(`3200 x 1920`). Les positions que Smode annonce à l'accessibilité de Windows sont décalées de la même façon.

## Ce que fait l'outil

Quand une fenêtre de Smode est agrandie sur un écran dont la barre des tâches est en haut ou à gauche, l'outil la
remet en fenêtre normale qui couvre toute la zone utile de cet écran (tout sauf la barre des tâches). Vous voyez
Smode en plein écran, et les clics tombent au bon endroit.

- **Rien ne tourne dans Smode** : aucun Script, aucun coût sur les images par seconde.
- **Aucune surveillance en boucle** : Windows prévient l'outil quand une fenêtre apparaît ou bouge ; il ne regarde
  que les fenêtres agrandies de `Smode.exe`, et ne fait rien sur un écran dont la barre des tâches est en bas ou à
  droite.
- Une **icône dans la zone de notification** (carré bleu avec un **S**, gris en pause) montre qu'il tourne. Son
  menu : état (nombre de corrections), Mettre en pause / Reprendre, Recaler Smode maintenant, Lancer au démarrage
  de Windows, Quitter. Le menu est en français quand Windows est en français, en anglais sinon.

## Testé avec

- Smode Compose 15 (R15)
- Windows 11 (build 26200) avec **StartAllBack**, barre des tâches en haut
- Un écran, 3200 x 2000 à 200 % de mise à l'échelle

Il devrait aussi fonctionner avec d'autres façons de mettre la barre des tâches en haut ou à gauche
(ExplorerPatcher, Windows 10...) et avec plusieurs écrans (chaque fenêtre de Smode est calée sur la zone utile de
son propre écran), mais ces cas n'ont pas été testés. Vos retours sont les bienvenus.

## Installation

1. Copiez `Smode_MaximizeFix.ps1` et `Smode_MaximizeFix.vbs` dans un dossier sur un disque **local**, par exemple
   `%LOCALAPPDATA%\Smode MaximizeFix` (pas sur un disque amovible si vous voulez le lancer avec Windows).
2. Double-cliquez sur `Smode_MaximizeFix.vbs`. L'icône apparaît dans la zone de notification (peut-être parmi les
   icônes cachées, sous la flèche `^`).
3. Clic droit sur l'icône, puis cochez **Lancer au démarrage de Windows** pour qu'il démarre avec votre session
   (cela ajoute un raccourci « Smode MaximizeFix » dans votre dossier Démarrage).

Un seul exemplaire tourne à la fois. Il utilise Windows PowerShell 5.1, déjà présent dans Windows ; le `.vbs` le
lance sans aucune fenêtre, avec `-ExecutionPolicy Bypass` pour ce script seulement.

## Désinstallation

Clic droit sur l'icône, décochez **Lancer au démarrage de Windows**, puis **Quitter**, et supprimez le dossier.

## Fichiers

- `Smode_MaximizeFix.ps1` — l'outil (PowerShell avec une petite partie en C# compilée au démarrage). Enregistré en
  UTF-8 **avec BOM** : gardez le BOM si vous le modifiez, Windows PowerShell 5.1 lit mal un fichier sans BOM.
- `Smode_MaximizeFix.vbs` — lance le `.ps1` du même dossier sans fenêtre de console.
- `maximizefix.log` — écrit à côté du script : démarrage, arrêt et chaque correction.

## Licence

MIT — voir [LICENSE](LICENSE).
