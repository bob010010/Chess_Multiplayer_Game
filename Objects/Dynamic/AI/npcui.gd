extends Node2D


@onready var npc: CharacterBody2D = get_parent()
@onready var name_label: Label = $"../Name"

func _ready() -> void:
	name_label.text = npc.name.substr(0, 8)
