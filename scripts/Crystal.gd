extends StaticBody3D

var hp = 3

func take_damage(amount):
	hp -= 1
	if SoundManager:
		SoundManager.play_mining()
	
	if hp <= 0:
		GameManager.add_log("Wydobycie", "Zniszczono Kryształ Obcego! (+1 Scrap Metalowy)")
		GameManager.inventory.append({
			"id": "c_scrap_" + str(randi()),
			"name": "Scrap Metalowy",
			"type": "scrap",
			"value": 5,
			"color": "#94a3b8",
			"icon": "⚙️",
			"desc": "Wykompany surowiec"
		})
		GameManager.emit_signal("inventory_changed")
		queue_free()
