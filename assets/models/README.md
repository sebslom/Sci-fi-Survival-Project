# 🧊 Przewodnik Modelami 3D (Models Guide)

Ten folder służy do przechowywania własnych modeli trójwymiarowych (`.glb`, `.gltf`, `.obj`).

Obecnie obiekty w grze wykorzystują podstawowe bryły proceduralne Godota (`BoxMesh`, `PrismMesh`, `TorusMesh`, `CylinderMesh`). Możesz je bezpośrednio podmienić na własne dopracowane modele 3D w edytorze Godota.

---

## 📂 Zalecana Struktura Katalogów i Konkretne Modele do Podmiany

### 1. 🔫 Bronie w dłoni gracza (`assets/models/weapons/`)
- `weapon_laser.glb` – Model Pistoletu Laserowego (w podwęźle `Head/Camera/FPSWeapon/WeaponMesh` w scenie [`scenes/Player.tscn`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scenes/Player.tscn)).
- `weapon_plasma.glb` – Model Karabinu Plazmowego.
- `weapon_shotgun.glb` – Model Ciężkiej Strzelby.
- `weapon_blade.glb` – Model Ostrza Sci-Fi.

### 2. 👾 Przeciwnicy (`assets/models/enemies/`)
- `enemy_slime.glb` – Kwasowy Slime (podmienia bryłę w scenach wypraw [`scenes/locations/ExpeditionMars.tscn`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scenes/locations/ExpeditionMars.tscn)).
- `enemy_stalker.glb` – Xenomorf Stalker.
- `enemy_drone.glb` – Cyber-Dron Latający.

### 3. 🏭 Meble i Budowle Bazy (`assets/models/structures/`)
- `adv_workbench.glb` – Zaawansowany Stół Rzemieślniczy.
- `workbench.glb` – Podstawowy Stół Rzemieślniczy.
- `smelter.glb` – Piec / Przetapiarka Surowców.
- `chest.glb` – Skrzynia Magazynowa na Przedmioty.
- `pot.glb` – Doniczka Organiczna.

### 4. 🌍 Otoczenie i Świat (`assets/models/world/`)
- `portal_torus.glb` – Animowany Portal 3D (węzeł `Portal/MeshInstance3D` w scenach lokacji).
- `alien_crystal.glb` – Kryształ Obcego do wydobywania surowców (`Crystal1`, `Crystal2`).
- `ancient_pillar.glb` – Starożytna Kolumna Obcych (w scenie [`scenes/locations/ExpeditionRuins.tscn`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scenes/locations/ExpeditionRuins.tscn)).
- `space_trash.glb` – Śmieci Kosmiczne i wraki.

---

## 🛠️ Jak podmienić model 3D w edytorze Godot Engine?

1. Skopiuj plik `.glb` lub `.gltf` do odpowiedniego podfolderu w `assets/models/`.
2. Otwórz docelową scenę w Godocie (np. [`scenes/Player.tscn`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scenes/Player.tscn) lub scenę wyprawy).
3. Rozwiń drzewo węzłów po lewej stronie, przeciągnij swój plik `.glb` z panelu **FileSystem** bezpośrednio na scenę 3D lub podmień właściwość `mesh` w węźle `MeshInstance3D`.
4. Dostosuj skalę (`Scale`) oraz pozycję w inspektorze po prawej stronie.
