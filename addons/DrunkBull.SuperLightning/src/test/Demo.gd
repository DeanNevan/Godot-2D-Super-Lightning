extends Node2D

onready var _SuperLightning = $SuperLightning
onready var _PassPointsFlags = $PassPointsFlags

var pass_point_flag_texture = preload("res://addons/DrunkBull.SuperLightning/addon_icon.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == 1:
				if !_SuperLightning.is_lightning:
					_SuperLightning.spawn(Vector2(), event.position, 1.5)
					_SuperLightning.lightning()
			elif event.button_index == 2:
				_SuperLightning.add_pass_point(event.position)
				update_pass_points_flags()
				pass

func update_pass_points_flags():
	for i in _PassPointsFlags.get_children():
		i.queue_free()
	for i in _SuperLightning.pass_points:
		var sprite = Sprite.new()
		sprite.texture = pass_point_flag_texture
		sprite.position = i
		_PassPointsFlags.add_child(sprite)
	pass

func _on_ButtonClearPassPoints_pressed() -> void:
	_SuperLightning.clear_pass_points()
	update_pass_points_flags()
	pass # Replace with function body.
