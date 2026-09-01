extends Node3D

@export var expedition_seed: int = 0

@onready var colony_generator = get_node_or_null("ColonyGenerator")

func _ready():
	# Read seed from GameManager if available
	if GameManager and GameManager.current_expedition_seed != 0:
		expedition_seed = GameManager.current_expedition_seed

	# Initialize random seed in _ready()
	seed(expedition_seed)

	GameManager.add_log("Expedition", "🚀 INITIALIZED EXPEDITION MARS SCENE (SEED #%d)!" % expedition_seed)
