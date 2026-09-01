extends Node3D

func _ready():
	_enforce_safe_zone_rules()

func _enforce_safe_zone_rules():
	# 1. Disable weapons while inside Safe Zone
	if WeaponManager:
		WeaponManager.holster_weapon()

	# 2. Add log entry
	if GameManager:
		GameManager.add_log("Bezpieczna Strefa", "🛡️ WEJŚCIE DO BAZARU: Bezpieczna Strefa Handlowa. Broń palna uległa wyłączeniu.")
