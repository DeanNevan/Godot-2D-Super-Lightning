extends Node2D

#闪电颜色
export(Color) var LINE_BASIC_COLOR := Color.lightskyblue
#闪电条数数量随机范围
export(Vector2) var LINES_RANGE := Vector2(5, 7)
#闪电每根线宽度曲线
export(Curve) var LINE_BASIC_WIDTH_CURVE := preload("res://addons/DrunkBull.SuperLightning/assets/resource/line_basic_curve.tres")
#闪电每根线宽度随机范围
export(Vector2) var LINE_WIDTH_RANGE := Vector2(100, 200)
#闪电每根线颜色梯度
export(Gradient) var LINE_BASIC_GRADIENT := preload("res://addons/DrunkBull.SuperLightning/assets/resource/line_basic_gradient.tres")
#闪电每根线一个点多少像素（数值越小，线points越多）
export(int) var LINE_PIXELS_PER_POINT := 30
#闪电每根线每个点随机位置范围（数值越大，线points偏离方向越厉害）
export(Vector2) var MIDDLE_LINE_POINTS_FLOAT_RANGE := Vector2(-100, 100)
#闪电每根线的每个点绕随机好的点再随机一次的乘积范围（数值越大，每根线的同一个地方的点越互相偏离）
export(Vector2) var LINE_POINTS_FLOAT_SCALE_RANGE_MIDDLE_LINE := Vector2(-0.2, 0.2)
#是否随机首点的位置
export(bool) var RANDOM_FIRST_POINT_POSITION := false
#是否随机末点的位置
export(bool) var RANDOM_LAST_POINT_POSITION := false
#点全部显示出来占总时间比值
export(float) var LINE_POINTS_FULL_DISPLAY_TIME_PROPORTION := 0.97
#已经显示多少比例的点后，点开始逐渐消失
export(float) var LINE_START_TO_HIDE_POINT_WHEN_SHOWED_POINTS_PERCENT_REACH := 1.0
#闪电动画
export(Animation) var LIGHTNING_ANIMATION := preload("res://addons/DrunkBull.SuperLightning/assets/resource/lightning_animation.tres")

var start_point := Vector2()
var end_point := Vector2()
var last_time := 1.5
var is_lightning := false
var pass_points := PoolVector2Array()

var _direction := Vector2()
var _normal_direction := Vector2()
var _length := 0.0
var _points_count := -1
var _total_points_count := -1
var _lines_count := -1
var _showed_points_count := -1
var _hiding_point := false
var _points_full_display_time := 0.0
var _points_gradually_show_period := 0.0
var _had_points_full_display_wait := false

var Scene_BasicLightningLine2d = preload("res://addons/DrunkBull.SuperLightning/src/main/BasicLightningLine2d.tscn")

var lightning_textures := [
	preload("res://addons/DrunkBull.SuperLightning/assets/art/spark_05_rotated.png"),
	preload("res://addons/DrunkBull.SuperLightning/assets/art/spark_06_rotated.png"),
	preload("res://addons/DrunkBull.SuperLightning/assets/art/spark_07_rotated.png"),
	preload("res://addons/DrunkBull.SuperLightning/assets/art/trace_01_rotated.png"),
	preload("res://addons/DrunkBull.SuperLightning/assets/art/trace_02_rotated.png"),
	preload("res://addons/DrunkBull.SuperLightning/assets/art/trace_03_rotated.png"),
	preload("res://addons/DrunkBull.SuperLightning/assets/art/trace_04_rotated.png"),
	preload("res://addons/DrunkBull.SuperLightning/assets/art/trace_05_rotated.png")
]

var lines := []

onready var _TimerGraduallyShowHide = Timer.new()
onready var _TimerLightning = Timer.new()
onready var _Lines = Node2D.new()
onready var _AnimationPlayer = AnimationPlayer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(_TimerGraduallyShowHide)
	_TimerGraduallyShowHide.connect("timeout", self, "_on_TimerGraduallyShowHide_timeout")
	_TimerGraduallyShowHide.one_shot = true
	add_child(_TimerLightning)
	_TimerLightning.connect("timeout", self, "_on_TimerLightning_timeout")
	_TimerLightning.one_shot = true
	add_child(_Lines)
	_Lines.use_parent_material = true
	
	add_child(_AnimationPlayer)
	_AnimationPlayer.root_node = ".."
	
	for i in LINES_RANGE.y:
		var new_line = Scene_BasicLightningLine2d.instance()
		_Lines.add_child(new_line)
		lines.append(new_line)
	pass # Replace with function body.

func random_int_range(from : int, to : int, contain_to := true) -> int:
	if contain_to:
		return randi() % (1 + to - from) + from
	else:
		return randi() % (to - from) + from

func add_pass_point(point : Vector2):
	pass_points.append(point)

func clear_pass_points():
	pass_points = PoolVector2Array()

#last_time,闪电持续时间
func spawn(_start_point := start_point, _end_point := end_point, _last_time : float = last_time) -> void:
	hide()
	start_point = _start_point
	end_point = _end_point
	last_time = _last_time
	
	_lines_count = random_int_range(LINES_RANGE.x, LINES_RANGE.y)
	
	for i in lines.size():
		var lightning_line : BasicLightningLine2d = lines[i]
		lightning_line.clear_lightning_points()
		lightning_line.hide()
		
		lightning_line.texture = lightning_textures[randi() % lightning_textures.size()]
		lightning_line.width = rand_range(LINE_WIDTH_RANGE.x, LINE_WIDTH_RANGE.y)
		lightning_line.gradient = LINE_BASIC_GRADIENT
		lightning_line.modulate = LINE_BASIC_COLOR
		lightning_line.width_curve = LINE_BASIC_WIDTH_CURVE
	
	if pass_points.size() == 0:
		_direction = (end_point - start_point).normalized()
		_normal_direction = _direction.rotated(PI / 2)
		_length = (end_point - start_point).length()
		_points_count = _length / LINE_PIXELS_PER_POINT
		_total_points_count = _points_count
		assert(_points_count > 1)
		for i in _points_count:
			if i == 0:
				if !RANDOM_FIRST_POINT_POSITION:
					for j in _lines_count:
						lines[j].add_lightning_point(start_point)
					continue
			if i == _points_count - 1:
				if !RANDOM_LAST_POINT_POSITION:
					for j in _lines_count:
						lines[j].add_lightning_point(end_point)
					continue
			var basic_point : Vector2 = start_point + i * LINE_PIXELS_PER_POINT *  _direction
			var random_vector : Vector2 = rand_range(MIDDLE_LINE_POINTS_FLOAT_RANGE.x, MIDDLE_LINE_POINTS_FLOAT_RANGE.y) * _normal_direction
			for j in _lines_count:
				var vector = random_vector * rand_range(LINE_POINTS_FLOAT_SCALE_RANGE_MIDDLE_LINE.x, LINE_POINTS_FLOAT_SCALE_RANGE_MIDDLE_LINE.y)
				var pos = basic_point + vector
				lines[j].add_lightning_point(pos)
	else:
		for i in pass_points.size():
			var _from_point := Vector2()
			if i == 0:
				_direction = (pass_points[0] - start_point).normalized()
				_normal_direction = _direction.rotated(PI / 2)
				_length = (pass_points[0] - start_point).length()
				_points_count = _length / LINE_PIXELS_PER_POINT
				_from_point = start_point
			elif i == pass_points.size() - 1:
				_direction = (end_point - pass_points[i]).normalized()
				_normal_direction = _direction.rotated(PI / 2)
				_length = (end_point - pass_points[i]).length()
				_points_count = _length / LINE_PIXELS_PER_POINT
				_from_point = pass_points[i]
			else:
				_direction = (pass_points[i] - pass_points[i - 1]).normalized()
				_normal_direction = _direction.rotated(PI / 2)
				_length = (pass_points[i] - pass_points[i - 1]).length()
				_points_count = _length / LINE_PIXELS_PER_POINT
				_from_point = pass_points[i - 1]
			if _points_count < 1:
				_points_count = 1
			_total_points_count += _points_count
			for j in _points_count:
				var basic_point : Vector2 = _from_point + j * LINE_PIXELS_PER_POINT * _direction
				var random_vector : Vector2 = rand_range(MIDDLE_LINE_POINTS_FLOAT_RANGE.x, MIDDLE_LINE_POINTS_FLOAT_RANGE.y) * _normal_direction
				for k in _lines_count:
					var vector = random_vector * rand_range(LINE_POINTS_FLOAT_SCALE_RANGE_MIDDLE_LINE.x, LINE_POINTS_FLOAT_SCALE_RANGE_MIDDLE_LINE.y)
					var pos = basic_point + vector
					lines[k].add_lightning_point(pos)
	pass

func lightning():
	_showed_points_count = 0
	_had_points_full_display_wait = false
	_hiding_point = false
	_points_full_display_time = last_time * LINE_POINTS_FULL_DISPLAY_TIME_PROPORTION
	_points_gradually_show_period = (last_time - _points_full_display_time) / _total_points_count
	for i in _lines_count:
		var lightning_line : BasicLightningLine2d = lines[i]
		lightning_line.spawn()
		lightning_line.show()
	show()
	#_TweenFade.interpolate_property(self, "modulate", modulate, Color(modulate.r, modulate.g, modulate.b, ))
	var ani_speed = 1.0 / last_time
	if !_AnimationPlayer.has_animation(LIGHTNING_ANIMATION.resource_name):
		_AnimationPlayer.add_animation(LIGHTNING_ANIMATION.resource_name, LIGHTNING_ANIMATION)
	_AnimationPlayer.playback_speed = ani_speed
	_AnimationPlayer.play(LIGHTNING_ANIMATION.resource_name)
	
	_TimerLightning.start(last_time)
	_TimerGraduallyShowHide.start(_points_gradually_show_period)
	_TimerGraduallyShowHide.paused = false
	
	is_lightning = true
	
	pass


func _on_TimerLightning_timeout() -> void:
	hide()
	is_lightning = false
	_TimerGraduallyShowHide.paused = true
	pass # Replace with function body.


func _on_TimerGraduallyShowHide_timeout() -> void:
	if is_lightning:
		if !_had_points_full_display_wait:
			if _showed_points_count == _total_points_count:
				yield(get_tree().create_timer(_points_full_display_time * 0.8), "timeout")
				_had_points_full_display_wait = true
		var showed_percent : float = float(_showed_points_count) / _total_points_count
		if !_hiding_point:
			if showed_percent >= LINE_START_TO_HIDE_POINT_WHEN_SHOWED_POINTS_PERCENT_REACH:
				_hiding_point = true
		for i in _lines_count:
			var lightning_line : BasicLightningLine2d = lines[i]
			if _hiding_point:
				lightning_line.hide_first()
			lightning_line.show_next()
		_showed_points_count += 1
		_TimerGraduallyShowHide.start(_points_gradually_show_period)
	pass # Replace with function body.
