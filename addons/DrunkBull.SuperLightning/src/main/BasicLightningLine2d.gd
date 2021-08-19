extends Line2D

class_name BasicLightningLine2d

var lightning_points := PoolVector2Array()

var points_size := -1

var show_idx := -1
var is_displaying := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

func clear_lightning_points():
	lightning_points = PoolVector2Array()

func add_lightning_point(_point := Vector2()):
	lightning_points.append(_point)

func spawn(_lightning_points := lightning_points) -> int:
	if _lightning_points.size() <=1:
		printerr("points size should > 1")
		return FAILED
	lightning_points = _lightning_points
	points_size = lightning_points.size()
	points = PoolVector2Array()
	show_idx = -1
	return OK



func show_next() -> void:
	if lightning_points.size() == 0:
		return
	if show_idx == points_size - 1:
		return
	show_idx += 1
	add_point(lightning_points[show_idx])
	pass

func hide_first():
	if lightning_points.size() == 0:
		return
	if points.size() == 0:
		return
	#print(hide_idx)
	remove_point(0)
	pass
