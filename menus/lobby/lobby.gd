extends Control

@onready var name_text_box: LineEdit = $VBoxContainer/GridContainer/NameTextBox
@onready var waiting_room: PackedScene = preload("res://menus/waiting_room/waiting_room.tscn")

func _ready() -> void:
	name_text_box.text = Save.get_value(Save.SaveKey.PlayerName)

func _create_waiting_room() -> void:
	add_child(waiting_room.instantiate())

func _on_host_button_pressed() -> void:
	Network.start_network(true)
	_create_waiting_room()

func _on_join_button_pressed() -> void:
	Network.start_network(false)
	_create_waiting_room()

func _on_name_text_box_text_changed(new_text: String) -> void:
	Save.save_value(new_text, Save.SaveKey.PlayerName)
