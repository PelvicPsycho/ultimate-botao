extends TextureButton

@export var label: Label

@export var label_pos_deactive: Vector2
@export var label_pos_active: Vector2

const TabMenu := preload("res://Componentes/TabButtons/tab_buttons_canvas_layer.tscn")

func _on_pressed() -> void:
	get_tree().change_scene_to_packed(TabMenu)


func _on_mouse_entered() -> void:
	label.position = label_pos_active


func _on_mouse_exited() -> void:
	label.position = label_pos_deactive
