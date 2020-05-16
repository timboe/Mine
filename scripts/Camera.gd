# Licensed under the MIT License.
# Copyright (c) 2018-2020 Jaccomo Lorenz (Maujoe)
extends Camera

onready var camera_manager : Node =  $"../CameraManager"

# Intern variables.
var _mouse_offset = Vector2()
var _direction = Vector3(0.0, 0.0, 0.0)
var _rotation_offset = Vector2()
var _yaw = 0.0
var _pitch = 0.0
var _wheel_cache : int
var _v : float

const WHEEL_MOD : float = 20.0
const PITCH_LIMIT := Vector2(deg2rad(-80), deg2rad(5))
const Y_LIMIT := Vector2(GlobalVars.FLOOR_HEIGHT + 10.0, GlobalVars.FLOOR_HEIGHT + 60.0)
const ACCLERATION = 5.0
const MAX_SPEED = 2.0
# Freelook settings
var SENSITIVITY = 0.5
var SMOOTHNESS = 0.5

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(2):
		_mouse_offset = event.relative
	if (event is InputEventMouseButton):
		var wheel : float = WHEEL_MOD * (Input.get_action_strength("ui_zoom_out") - Input.get_action_strength("ui_zoom_in"))
		if wheel != 0.0:
			_wheel_cache = round(wheel)

func _poll():
	_direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	_direction.z = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	var zoom : float = Input.get_action_strength("ui_zoom_in") - Input.get_action_strength("ui_zoom_out")
	if _wheel_cache != 0:
		zoom += 1 * sign(_wheel_cache)
# warning-ignore:narrowing_conversion
		_wheel_cache -= 1 * sign(_wheel_cache)
	zoom = clamp(zoom, -1, 1)
	#print("zoom " , zoom , " translation.y " , translation.y)
	if zoom != 0:
		if zoom == -1 and translation.y == Y_LIMIT.y:
			pass
		elif zoom == 1 and translation.y == Y_LIMIT.x:
			pass
		else:
			#if -1 and translation.y < Y_LIMIT.y) or (zoom == 1 and translation.y > Y_LIMIT.x):
			var a = deg2rad(10 +  rotation_degrees.x) # +5 as the max angle is actually 80 deg
			var y_amount = sin(a)
			var z_amount = cos(a)
			_direction.y = (zoom * y_amount)
			_direction.z -= (zoom * z_amount)
	_direction = _direction.rotated(Vector3.UP, rotation.y)
	
func _process(delta):
	if camera_manager.camera_status != camera_manager.CameraStatus.OVERHEAD:
		return
	_poll()
	_update_rotation(delta)
	_update_movement(delta)

func _update_movement(delta):

		
	if _direction == Vector3.ZERO:
		_v = 0
	else:
		_v = min(MAX_SPEED, _v + (ACCLERATION * delta))
		
	global_translate(_direction * _v)
	translation.y = clamp(translation.y, Y_LIMIT.x, Y_LIMIT.y)
	_direction = Vector3()


func _update_rotation(_delta):
	var offset : Vector2 = _mouse_offset * SENSITIVITY
	_mouse_offset = Vector2()

	_yaw = _yaw * SMOOTHNESS + offset.x * (1.0 - SMOOTHNESS)
	_pitch = _pitch * SMOOTHNESS + offset.y * (1.0 - SMOOTHNESS)
	_pitch = min(_pitch, 5.0) # Otherwise we can break through the clamp below

	rotate_y(deg2rad(-_yaw))
	rotate_object_local(Vector3(1,0,0), deg2rad(-_pitch))
	rotation.x = clamp(rotation.x, PITCH_LIMIT.x, PITCH_LIMIT.y)
	#print(rotation_degrees.x)
