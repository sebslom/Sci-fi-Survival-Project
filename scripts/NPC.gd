extends StaticBody3D

@export var npc_name: String = "Quest Giver"
@export var npc_type: String = "quest" # "quest", "scrap_merchant", "weapon_merchant"

func get_interaction_prompt() -> String:
	return "[E] Porozmawiaj: " + npc_name

func interact():
	if SoundManager:
		SoundManager.play_pick()
	
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		# Fallback find HUD in root
		hud = get_tree().root.find_child("HUD", true, false)
		
	if hud and hud.has_method("open_npc_dialog"):
		hud.open_npc_dialog(npc_type, npc_name)
	else:
		GameManager.add_log("NPC", "Rozmawiasz z: " + npc_name)
