# 🔊 Przewodnik Dźwięków i Muzyki (Audio Guide)

Ten folder służy do przechowywania własnych efektów dźwiękowych (`.wav`) oraz muzyki w tle (`.ogg` / `.mp3`).

Obecnie gra generuje dźwięki syntetycznie w skrypcie [`scripts/SoundManager.gd`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scripts/SoundManager.gd). Gdy dodasz własny plik `.wav` lub `.mp3` w tym folderze, możesz go łatwo podpiąć w edytorze Godota lub podmienić ścieżkę w `SoundManager.gd`.

---

## 🎧 Lista Konkretnych Dźwięków do Podmiany

| Nazwa Dźwięku | Zalecana Nazwa Pliku | Format | Wywołanie w Kodzie (`SoundManager.gd`) | Opis Działania |
| :--- | :--- | :--- | :--- | :--- |
| **Strzał Laseru** | `laser.wav` | `.wav` | `play_laser()` | Odgłos strzału z Pistoletu Laserowego |
| **Strzał Plazmy** | `plasma.wav` | `.wav` | `play_plasma()` | Odgłos strzału z Karabinu Plazmowego |
| **Strzał Strzelby** | `shotgun.wav` | `.wav` | `play_shotgun()` | Ciężki odrzut i wybuch strzelby |
| **Atak Ostrzem** | `blade.wav` | `.wav` | `play_blade()` | Świst ostrza Sci-Fi w walce wręcz |
| **Krok Gracza** | `walk.wav` | `.wav` | `play_walk()` | Odgłos kroku na podłożu podczas ruchu |
| **Skok Gracza** | `jump.wav` | `.wav` | `play_jump()` | Odgłos odbicia i skoku 3D [Spacja] |
| **Podniesienie / Użycie** | `pick.wav` | `.wav` | `play_pick()` | Kliknięcie w ekwipunku, podniesienie przedmiotu |
| **Aktywacja Portalu** | `teleport.wav` | `.wav` | `play_teleport()` | Dźwięk teleportacji przy przejściu przez portal 3D |
| **Alarm Wipeoutu** | `alarm.wav` | `.wav` | `play_alarm()` | Ostrzeżenie na 30s przed Wipeoutem |
| **Eksplozja Wipeoutu** | `wipeout.wav` | `.wav` | `play_wipeout()` | Potężny wybuch atmosferyczny i reset wyprawy |
| **Trafienie / Obrażenia** | `hit.wav` | `.wav` | `play_hit()` | Trafienie potwora / otrzymanie obrażeń przez gracza |
| **Śmierć Przeciwnika** | `enemy_death.wav` | `.wav` | `play_enemy_death()` | Skowyt / eksplozja pokonanego potwora |
| **Awans Poziomu** | `levelup.wav` | `.wav` | `play_levelup()` | Dźwięk wygranej przy zdobyciu poziomu EXP |
| **Rzemiosło / Piec** | `craft.wav` | `.wav` | `play_craft()` | Dźwięk wytwarzania mebli lub przetapiania w piecu |
| **Wydobycie Kryształu** | `mining.wav` | `.wav` | `play_mining()` | Uderzenie w Kryształ Obcego przy wydobyciu surowca |
| **Muzyka Tła Bazy** | `music_shelter.ogg` | `.ogg` / `.mp3` | `AudioStreamPlayer` | Spokojna muzyka w Schronie Taktycznym |
| **Muzyka Walki / Marsa** | `music_mars.ogg` | `.ogg` / `.mp3` | `AudioStreamPlayer` | Mroczna, dynamiczna muzyka Sci-Fi na Wyprawie |

---

## 🛠️ Jak podmienić dźwięki w Godot Engine?

1. Wklej pliki dźwiękowe `.wav` lub `.ogg` do katalogu `assets/sounds/`.
2. W skrypcie [`scripts/SoundManager.gd`](file:///c:/Users/dude/Desktop/priv/1projekty/1Game/scripts/SoundManager.gd) podmień wywołanie `_generate_tone(...)` na załadowanie pliku:
   ```gdscript
   func play_laser():
	   audio_player.stream = load("res://assets/sounds/laser.wav")
	   audio_player.play()
   ```
