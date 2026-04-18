extends Node
class_name GameSetupHandler

const PRESETS: Dictionary = {
	"Alone": { "game_type": "FFA", "arena_size": 2500.0, "food_per_player": 1500, "bots_per_player": 0, "bot_classes": ["Pawn"], "npc_points": false, "start_lvls": 200, "player_class": "Holy_Queen", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 2}, # Alone for testing
	
	"1-Bot": { "game_type": "FFA", "arena_size": 1500.0, "food_per_player": 50, "bots_per_player": 1, "bot_classes": ["Rook"], "npc_points": true, "start_lvls": 200, "player_class": "Holy_Queen", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 2}, # 1 Bot for testing
	
	"1-Bot-L": { "game_type": "FFA", "arena_size": 2500.0, "food_per_player": 1500, "bots_per_player": 1, "bot_classes": ["Pawn"], "npc_points": false, "start_lvls": 200, "player_class": "Super_Queen", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 2}, # 1 Bot for testing
	
	"2-Bot": { "game_type": "FFA", "arena_size": 2500.0, "food_per_player": 1500, "bots_per_player": 2, "bot_classes": ["Pawn"], "npc_points": false, "start_lvls": 200, "player_class": "Pawn_II", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 2}, # 2 Bots for testing
	
	"Zombies": { "game_type": "Zombies", "arena_size": 4000.0, "food_per_player": 7500, "bots_per_player": 30, "bot_classes": ["Pawn", "Pawn_I", "Pawn_II"], "npc_points": true, "start_lvls": 0, "player_class": "Pawn", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 3}, # Zombies
	
	"FFA": { "game_type": "FFA", "arena_size": 6000.0, "food_per_player": 7500, "bots_per_player": 20, "bot_classes": ["Pawn", "Pawn_I"], "npc_points": true, "start_lvls": 0, "player_class": "Pawn", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 3}, # FFA
	
	"2T": { "game_type": "2T", "arena_size": 6000.0, "food_per_player": 7500, "bots_per_player": 20, "bot_classes": ["Pawn", "Pawn_I"], "npc_points": true, "start_lvls": 0, "player_class": "Pawn", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 3}, # 2 teams
	
	"4T": { "game_type": "4T", "arena_size": 6000.0, "food_per_player": 7500, "bots_per_player": 20, "bot_classes": ["Pawn", "Pawn_I"], "npc_points": true, "start_lvls": 0, "player_class": "Pawn", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 3}, # 4 teams
	
	"FFA-L": { "game_type": "FFA", "arena_size": 12000.0, "food_per_player": 25000, "bots_per_player": 60, "bot_classes": ["Pawn", "Pawn_I", "Pawn_II"], "npc_points": true, "start_lvls": 0, "player_class": "Pawn", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 3}, # Large game FFA
	"2T-L": { "game_type": "2T", "arena_size": 12000.0, "food_per_player": 25000, "bots_per_player": 60, "bot_classes": ["Pawn", "Pawn_I", "Pawn_II"], "npc_points": true, "start_lvls": 0, "player_class": "Pawn", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 3} # Large game 2 teams
}

var arena_size: float = 2500.0
var top_left_x: float = -arena_size/2
var top_left_y: float = -arena_size/2
var bottom_left_x: float = arena_size/2

var food_per_player: int = 1500
var max_food: int = 0

var spawn_immunity_time: float = 10.0

var bots_per_player: int = 0
var max_bots: int = 0
var npc_gains_points: bool = true
var bot_spawn_classes: Array = ["Pawn"]

var npc_levels_for_promotion: int = 3
var npc_levels_for_upgrade: int = 1

var player_levels_at_start: int = 0
var player_starts_as: String = "Pawn"
var player_levels_for_upgrade: int = 1
var player_levels_for_promotion: int = 2

var game_type: String = "Alone"

@onready var main: Node = get_parent().get_parent()


# Parses the preset input field and applies matching or custom settings.
func apply_preset_or_custom(input: String) -> void:
	if input == "":
		input = "FFA"
		printerr("Invalid game preset, defaulting")
		
	var parts: Array = input.split(",")
	print("GAME PRESETS: " + str(parts))
	# If a single token matches a preset key, apply it directly
	if parts.size() == 1 and PRESETS.has(parts[0].strip_edges()):
		matches_preset(PRESETS[parts[0].strip_edges()])
	else:
		custom_preset(parts)

	create_boundaries()
	
	main.get_node("Tiles").size = Vector2(arena_size, arena_size)
	main.get_node("Tiles").position = Vector2(-arena_size/2, -arena_size/2)

# Using a set preset for the game type
func matches_preset(preset: Dictionary) -> void:
	print(str(preset))
	game_type        = preset["game_type"]
	arena_size       = preset["arena_size"]
	food_per_player  = preset["food_per_player"]
	bots_per_player  = preset["bots_per_player"]
	bot_spawn_classes = preset["bot_classes"]
	npc_gains_points = preset["npc_points"]
	player_levels_at_start = preset["start_lvls"]
	player_starts_as = preset["player_class"]
	player_levels_for_upgrade = preset["player_levels_for_upgrade"]
	player_levels_for_promotion = preset["player_levels_for_promotion"]



# Creates the boundry walls of the arena
func create_boundaries() -> void:
	print("Creating")
	top_left_x = -arena_size/2
	top_left_y = -arena_size/2
	bottom_left_x = arena_size/2
	
	var rects: Array = [
		Rect2(top_left_x - 50, top_left_y - 50, arena_size + 100, 50),  # Top wall
		Rect2(top_left_x - 50, bottom_left_x, arena_size + 100, 50),    # Bottom wall
		Rect2(top_left_x - 50, top_left_y, 50, arena_size),             # Left wall
		Rect2(top_left_x + arena_size, top_left_y, 50, arena_size)      # Right wall
	]
	
	for rect: Rect2 in rects:
		print("Try")
		main.get_node("SpawnedTraps").spawn_wall(rect)

# Passsing in custom values for each of the presets
func custom_preset(parts: Array) -> void:
	# Otherwise expect: game_type, arena_size, food_per_player, bots_per_player
	if parts.size() != 5:
		printerr("Preset input must be a preset number or 5 comma-separated values.")
		return

	game_type       = parts[0].strip_edges()
	arena_size      = float(parts[1].strip_edges())
	food_per_player = int(parts[2].strip_edges())
	bots_per_player = int(parts[3].strip_edges())
	bot_spawn_classes = Array(parts[4].strip_edges())
	npc_gains_points = bool(parts[5].strip_edges())
	player_levels_at_start = int(parts[6].strip_edges())
	player_starts_as = String(parts[7].strip_edges())
	player_levels_for_upgrade = int(parts[8].strip_edges())
	player_levels_for_promotion = int(parts[9].strip_edges())
