# Licensed under the MIT License.
# Copyright (c) 2018-2020 Jaccomo Lorenz (Maujoe)

extends Camera

# User settings:
# General settings
export var enabled = true setget set_enabled

# See https://docs.godotengine.org/en/latest/classes/class_input.html?highlight=Input#enumerations
export(int, "Visible", "Hidden", "Captured, Confined") var mouse_mode = Input.MOUSE_MODE_VISIBLE

enum Freelook_Modes {MOUSE, INPUT_ACTION, MOUSE_AND_INPUT_ACTION}

# Freelook settings
export var freelook = true
export (Freelook_Modes) var freelook_mode = 1
export (float, 0.0, 1.0) var sensitivity = 0.5
export (float, 0.0, 0.999, 0.001) var smoothness = 0.5 setget set_smoothness
export (int, 0, 360) var yaw_limit = 360
export (int, 0, 360) var pitch_limit = 360
export (int, -100, 100) var y_min = 20
export (int, -100, 100) var y_max = 60


# Movement settings
export var movement = true
export (float, 0.0, 1.0) var acceleration = 1.0
export (float, 0.0, 0.0, 1.0) var deceleration = 0.1
export var max_speed = Vector3(1.0, 1.0, 1.0)
export var local = false

# Input Actions
export var rotate_left_action = "ui_rotate_left"
export var rotate_right_action = "ui_rotate_right"
export var rotate_up_action = "ui_pitch_up"
export var rotate_down_action = "ui_pitch_down"
export var forward_action = "ui_up"
export var backward_action = "ui_down"
export var left_action = "ui_left"
export var right_action = "ui_right"
export var up_action = "ui_zoom_in"
export var down_action = "ui_zoom_out"
export var trigger_action = ""


# Gui settings
#export var use_gui = true
#export var gui_action = "ui_cancel"

# Intern variables.
var _mouse_offset = Vector2()
var _rotation_offset = Vector2()
var _yaw = 0.0
var _pitch = 0.0
var _total_yaw = 0.0
var _total_pitch = 0.0

var _direction = Vector3(0.0, 0.0, 0.0)
var _speed = Vector3(0.0, 0.0, 0.0)
#var _gui

var _triggered=false

const ROTATION_MULTIPLIER = 500

func _ready():
	_check_actions([
		forward_action,
		backward_action,
		left_action,
		right_action,
		#gui_action,
		up_action,
		down_action,
		rotate_left_action,
		rotate_right_action,
		rotate_up_action,
		rotate_down_action,
	])

	set_enabled(enabled)

	#if use_gui:
	#	_gui = preload("camera_control_gui.gd")
	#	_gui = _gui.new(self, gui_action)
	#	add_child(_gui)

func _input(event):
	
	if len(trigger_action)!=0:
		if event.is_action_pressed(trigger_action):
			_triggered=true
		elif event.is_action_released(trigger_action):
			_triggered=false
	else:
		_triggered=true
	if freelook and _triggered:
		if event is InputEventMouseMotion and Input.is_mouse_button_pressed(2):
			_mouse_offset = event.relative
			
		_rotation_offset.x = Input.get_action_strength(rotate_right_action) - Input.get_action_strength(rotate_left_action)
		_rotation_offset.y = Input.get_action_strength(rotate_down_action) - Input.get_action_strength(rotate_up_action)

	if movement and _triggered:
		_direction.x += Input.get_action_strength(right_action) - Input.get_action_strength(left_action)
		_direction.z += Input.get_action_strength(backward_action) - Input.get_action_strength(forward_action)
		
		var zoom : int = Input.get_action_strength(up_action) - Input.get_action_strength(down_action)
		if (zoom == 1 and translation.y < y_max) or (zoom == -1 and translation.y > y_min): 
			var a = deg2rad(-45 + _total_pitch)
			var y_amount = cos(a)
			var z_amount = sin(a)
			_direction.y = (zoom * y_amount)
			_direction.z += (zoom * y_amount)
			
		#print(zoom , " " , _direction.z)
		#print("UAS " , Input.get_action_strength(up_action) , " DAS " , Input.get_action_strength(down_action), " Y " , _direction.y)
		
		var q := Quat(Vector3(0.0, deg2rad(rotation_degrees.y), 0.0))
		_direction = q.xform(_direction)
		#print("heading ", rotation_degrees.y, " direction ", _direction)
		

func _process(delta):
	if _triggered:
		_update_views(delta)

func _update_views(delta):
	if !current:
		return
	if freelook:
		_update_rotation(delta)
	if movement:
		_update_movement(delta)


func _update_movement(delta):
	
	if GlobalVars.camera_status != GlobalVars.CameraStatus.OVERHEAD:
		return
	
	var offset = max_speed * acceleration * _direction

	_speed.x = clamp(_speed.x + offset.x, -max_speed.x, max_speed.x)
	_speed.y = clamp(_speed.y + offset.y, -max_speed.y, max_speed.y)
	_speed.z = clamp(_speed.z + offset.z, -max_speed.z, max_speed.z)
	
	#print("SY " , _speed.y ," DY ", _direction.y)

	# Apply deceleration if no input
	if _direction.x == 0:
		_speed.x *= (1.0 - deceleration)
	if _direction.y == 0:
		_speed.y *= (1.0 - deceleration)
	if _direction.z == 0:
		_speed.z *= (1.0 - deceleration)

	if local:
		translate(_speed * delta)
	else:
		global_translate(_speed * delta)
	translation.y = clamp(translation.y, y_min, y_max)
	
	# Zero
	_direction = Vector3()
	
func _update_rotation(delta):
	var offset = Vector2();
	
	if not freelook_mode == Freelook_Modes.INPUT_ACTION:
		offset += _mouse_offset * sensitivity
	if not freelook_mode == Freelook_Modes.MOUSE: 
		offset += _rotation_offset * sensitivity * ROTATION_MULTIPLIER * delta
	
	_mouse_offset = Vector2()

	_yaw = _yaw * smoothness + offset.x * (1.0 - smoothness)
	_pitch = _pitch * smoothness + offset.y * (1.0 - smoothness)

	if yaw_limit < 360:
		_yaw = clamp(_yaw, -yaw_limit - _total_yaw, yaw_limit - _total_yaw)
	if pitch_limit < 360:
		_pitch = clamp(_pitch, -pitch_limit - _total_pitch, pitch_limit - _total_pitch)

	_total_yaw += _yaw
	_total_pitch += _pitch

	rotate_y(deg2rad(-_yaw))
	rotate_object_local(Vector3(1,0,0), deg2rad(-_pitch))


func _update_process_func():
	set_process(true)

func _check_actions(actions=[]):
	if OS.is_debug_build():
		for action in actions:
			if not InputMap.has_action(action):
				print('WARNING: No action "' + action + '"')

func set_enabled(value):
	enabled = value
	if enabled:
		Input.set_mouse_mode(mouse_mode)
		set_process_input(true)
		_update_process_func()
	else:
		set_process(false)
		set_process_input(false)
		set_physics_process(false)

func set_smoothness(value):
	smoothness = clamp(value, 0.001, 0.999)

