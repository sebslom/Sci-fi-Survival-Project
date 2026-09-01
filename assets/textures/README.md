# 🖼️ Przewodnik Teksturami i Materiałami (Textures Guide)

Ten folder służy do przechowywania tekstur podłoża, ścian, nieba oraz materiałów PBR (`.png`, `.jpg`).

Obecnie obiekty używają jednokolorowych materiałów Godota (`StandardMaterial3D`). Nałożenie tekstur `.png` nada grze unikalny wygląd Sci-Fi.

---

## 🎨 Lista Konkretnych Tekstur do Podmiany

| Nazwa Tekstury | Zalecana Nazwa Pliku | Zastosowanie | Miejsce w Projektu |
| :--- | :--- | :--- | :--- |
| **Podłoga Schronu** | `shelter_floor_albedo.png` | Metalowa kratka / płytki bazy | `Floor` w scenie [`scenes/locations/Shelter.tscn`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scenes/locations/Shelter.tscn) |
| **Ściana Schronu** | `shelter_wall_albedo.png` | Płyty pancerne Schronu | `NorthWall` / `SouthWall` / `EastWall` / `WestWall` |
| **Powierzchnia Marsa** | `mars_soil_albedo.png` | Czerwony piach i skały Marsa | `Terrain` w scenie [`scenes/locations/ExpeditionMars.tscn`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scenes/locations/ExpeditionMars.tscn) |
| **Skały Wąwozu** | `canyon_rock_albedo.png` | Ciemny piaskowiec i wąwozy | `Terrain` w scenie [`scenes/locations/ExpeditionCanyon.tscn`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scenes/locations/ExpeditionCanyon.tscn) |
| **Kamień Ruin** | `ruins_stone_albedo.png` | Starożytny kamień rzeźbiony Obcych | `Terrain` / `AncientPillar` w [`ExpeditionRuins.tscn`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scenes/locations/ExpeditionRuins.tscn) |
| **Lodowa Pustka** | `ice_surface_albedo.png` | Błękitny lód i zmarzlina | `Terrain` w scenie [`scenes/locations/ExpeditionIce.tscn`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scenes/locations/ExpeditionIce.tscn) |
| **Podłoga Stacji** | `city_floor_albedo.png` | Asfalt / metal Stacji Handlowej | `Floor` w scenie [`scenes/locations/City.tscn`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scenes/locations/City.tscn) |
| **Skybox Kosmiczny** | `space_skybox.png` | Gwiazdy, planeta i mgławica | Plik [`default_env.tres`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/default_env.tres) (`PanoramaSkyMaterial`) |

---

## 🛠️ Jak nałożyć teksturę w edytorze Godot Engine?

1. Skopiuj teksturę `.png` do katalogu `assets/textures/`.
2. Otwórz scenę (np. [`scenes/locations/Shelter.tscn`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scenes/locations/Shelter.tscn)) i zaznacz węzeł podłogi (`Floor`).
3. W panelu **Inspektor** po prawej stronie kliknij właściwość `Material Override` lub `Surface Material Override`.
4. Rozwiń sekcję **Albedo** -> **Texture** i przeciągnij swój plik `.png` z drzewka plików.
5. Możesz włączyć **UV1 -> Use Triplanar**, aby tekstura automatycznie powtarzała się bez rozciągania!
