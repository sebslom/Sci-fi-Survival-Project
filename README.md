# 🚀 Sci-Fi Survival Project - 3D Sci-Fi Survival FPS Template for Godot 4.x

[![Godot Engine](https://img.shields.io/badge/Godot-4.6%2B-blue.svg)](https://godotengine.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An open-source, feature-rich **3D Sci-Fi Survival FPS Game Template** built in Godot Engine 4.x. Inspired by hardcore survival mechanics from games like *Misery* and *Icarus*, this project provides a modular foundation for developers looking to build extraction shooters, planetary survival, or sci-fi action games.

---

## 🛠️ About The Project

**Sci-Fi Survival Project** is a 3D first-person planetary survival game template set on a harsh alien world. Players explore hostile surface biomes, scavenge resources, manage survival status effects, craft tactical equipment, and return to their base before atmospheric emission waves hit the surface.

This codebase is released as an open-source starter template and learning resource for the Godot development community.
<img width="80%" alt="Menu" src="https://github.com/user-attachments/assets/9cb8a50f-642f-4730-a887-4854b9cc705e" />
<img width="80%" alt="game3" src="https://github.com/user-attachments/assets/08228c0e-73b1-4183-8e8b-25db1c72474e" />
<img width="80%" alt="game2" src="https://github.com/user-attachments/assets/a4def5e2-c10c-4416-a5b2-877da0de5468" />
<img width="80%" alt="game1" src="https://github.com/user-attachments/assets/08edfa6d-f903-4251-bac3-29b902377021" />

---

## ✅ Working Features (Ready to Use)

The core gameplay frameworks are functional and ready for extension:

- **🎮 First-Person Controller (FPS)**:
  - Smooth 3D FPS movement with crouch, sprint, jump, and procedural head bobbing dynamics.
  - Camera-linked tactical flashlight (`[F]`) with dynamic spotlight casting and battery/durability tracking.
  - Weapon handling with optics zoom (`RMB`), recoil sway, ammo pack usage, and condition degradation.

- **🎒 Paperdoll Grid Inventory System**:
  - Full paperdoll equipment management for helmet, mask, tactical vest, suit, backpack, and 5 artifact slots.
  - `ALT + Double-Click` / quick transfer between player inventory and container storage chests.
  - Item stacking, stack splitting, equipment weight limits, and hotbar binding (`1-5`).

- **📦 Physical World Loot & Dropping**:
  - 3D `RigidBody3D` ground items (`InteractableItem3D`) with dynamic mesh/material assignment based on item rarity (scrap, copper, steel, polymer, batteries, crystals).
  - Physical inventory dropping: items spawn in front of the player with realistic physics impulses.

- **👁️ RayCast3D Contextual Interaction System**:
  - Immersive HUD interaction prompts rendered directly under the central crosshair (no flying 3D UI labels).
  - Contextual interaction for chests, doors, portals, NPCs, loot piles, and base structures.

- **🌅 Day/Night Cycle & Atmosphere**:
  - Dynamic sun position, sky color gradients, ambient lighting transitions, and environmental hazard support.

- **☄️ Wipeout / Emission Timer System**:
  - Global emission countdown timer that alters atmospheric conditions.
  - Safezone airlock shelter protection vs. hostile surface emission damage ticks.

---

## ⚠️ Known Issues / Unfinished Features

Please note that this project is released as an open-source template in an abandoned state. The following modules are incomplete and require further development or refactoring:

- **🏗️ Grid-Based Building System**: The modular structure placement framework (walls, floors, stairs, doors) is partially implemented and requires a structural overlap/snap refactor.
- **🗺️ Procedural 3D Map Generation**: The seed-based procedural map decorator generator (`MapDecoratorGenerator`) and terrain decorator algorithms are incomplete and need redesign.

---

## 🚀 Setup Instructions

1. **Prerequisites**: Download and install [Godot Engine 4.x](https://godotengine.org/download) (Godot 4.6+ recommended).
2. **Import Project**:
   - Open Godot Engine Project Manager.
   - Click **Import** and navigate to the project directory.
   - Select `project.godot` and click **Import & Edit**.
3. **Run the Game**: Press `F5` or click **Play** to launch from `scenes/MainMenuScene.tscn`.

---

## 📜 License

Distributed under the **MIT License**. Free to use, modify, and distribute for personal and commercial projects.
