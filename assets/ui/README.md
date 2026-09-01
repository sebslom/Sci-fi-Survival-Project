# 🎨 Przewodnik Grafikami UI (User Interface Guide)

Ten folder służy do przechowywania ikon przedmiotów, broni, celownika oraz ramek interfejsu (`.png`).

Obecnie interfejs używa emoji oraz tekstu w skrypcie [`scripts/HUD.gd`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scripts/HUD.gd). Każdy przedmiot i element UI można podmienić na profesjonalną grafikę `.png`.

---

## 🖼️ Lista Konkretnych Grafiki i Ikon do Podmiany

### 1. 🎯 Celownik i Ramki (`assets/ui/`)
- `crosshair.png` – Grafikę celownika na środku ekranu (podmienia tekst `+` w węźle `Control/Crosshair` w scenie [`scenes/HUD.tscn`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scenes/HUD.tscn)).
- `damage_vignette.png` – Czerwony rozbłysk ekranu przy otrzymaniu obrażeń.
- `hitmarker.png` – Znak `X` przy trafieniu przeciwnika.

### 2. 🔫 Ikony Broni i Narzędzi (`assets/ui/icons/`)
- `icon_laser.png` – Ikona Pistoletu Laserowego (dla slotu hotbaru i ekwipunku).
- `icon_plasma.png` – Ikona Karabinu Plazmowego.
- `icon_shotgun.png` – Ikona Ciężkiej Strzelby.
- `icon_blade.png` – Ikona Ostrza Sci-Fi.

### 3. ⚙️ Ikony Surowców i Ekwipunku (`assets/ui/icons/`)
- `icon_scrap.png` – Ikona Złomu Metalowego (`scrap`).
- `icon_wood.png` – Ikona Drewna Obcego (`wood`).
- `icon_fertilizer.png` – Ikona Nawozu Organicznego (`fertilizer`).
- `icon_trash.png` – Ikona Śmieci Kosmicznych (`trash`).
- `icon_food.png` – Ikona Racji Żywnościowych (`food`).
- `icon_watch.png` – Ikona Zegarka Taktycznego (`watch`).
- `icon_gps.png` – Ikona Modułu GPS / Mapy (`gps`).

### 4. 🏭 Ikony Meble i Budynków (`assets/ui/icons/`)
- `icon_adv_workbench.png` – Ikona Zaawansowanego Stołu Rzemieślniczego.
- `icon_workbench.png` – Ikona Stołu Rzemieślniczego.
- `icon_smelter.png` – Ikona Pieca / Przetapiarki.
- `icon_chest.png` – Ikona Skrzyni Magazynowej.

---

## 🛠️ Jak podmienić grafikę ikony w kodzie i UI?

1. Skopiuj plik `.png` do folderu `assets/ui/icons/`.
2. W skrypcie [`scripts/GameManager.gd`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scripts/GameManager.gd) przypisz ścieżkę do ikony przedmiotu:
   ```gdscript
   { "id": "w_laser", "name": "Pistolet Laserowy", "icon_path": "res://assets/ui/icons/icon_laser.png" }
   ```
3. W skrypcie [`scripts/HUD.gd`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scripts/HUD.gd) ustaw teksturę przycisku `Button`:
   ```gdscript
   btn.icon = load(item.get("icon_path"))
   ```
