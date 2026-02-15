@tool
@icon("res://addons/godot-virtual-joystick/VirtualJoystick.svg")
extends Control
#class_name GodotVirtualJoystick

# Made by Kazox61

#/*                         This file is part of:                          */
#/*                             GODOT ENGINE                               */
#/*                        https://godotengine.org                         */
#/**************************************************************************/
#/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
#/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
#/*                                                                        */
#/* Permission is hereby granted, free of charge, to any person obtaining  */
#/* a copy of this software and associated documentation files (the        */
#/* "Software"), to deal in the Software without restriction, including    */
#/* without limitation the rights to use, copy, modify, merge, publish,    */
#/* distribute, sublicense, and/or sell copies of the Software, and to     */
#/* permit persons to whom the Software is furnished to do so, subject to  */
#/* the following conditions:                                              */
#/*                                                                        */
#/* The above copyright notice and this permission notice shall be         */
#/* included in all copies or substantial portions of the Software.        */
#/*                                                                        */
#/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
#/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
#/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
#/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
#/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
#/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
#/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */



enum JoystickMode {
	## The joystick doesn't move.
	FIXED,
	## The joystick is moved to the initial touch position as long as it's within the joystick's bounds. It moves back to its original position when released.
	DYNAMIC,
	## The joystick is moved to the initial touch position as long as it's within the joystick's bounds. It will follow the touch input if it goes outside the joystick's range. It moves back to its original position when released.
	FOLLOWING
}

enum VisibilityMode {
	## The joystick is always visible.
	ALWAYS,
	## The joystick is only visible when being touched.
	WHEN_TOUCHED
}

## The joystick mode to use.
@export var joystick_mode: JoystickMode = JoystickMode.FIXED
## The size of the joystick in pixels.
@export var joystick_size: float= 100.0
## The size of the joystick tip in pixels.
@export var tip_size: float = 50.0
## The ratio of the joystick size that defines the joystick deadzone. The joystick tip must move beyond this ratio before being considered active.
## This deadzone is applied before triggering input actions and affects the joystick's input vector and all related signals.
## Note that input actions may also define their own deadzones in the InputMap. If both are set, the joystick deadzone is applied first, followed by the action's deadzone.
## By default, this value is [code]0.0[/code], meaning the joystick does not apply its own deadzone and relies entirely on the InputMap action deadzones.
@export var deadzone_ratio: float = 0.0
## The multiplier applied to the joystick's radius that defines the clamp zone.
## This zone limits how far the joystick tip can move from its center before being clamped.
## A value of [code]1.0[/code] means the tip can move up to the edge of the joystick's visual size.
## In Joystick Following mode, this radius also determines how far the finger can move before the joystick base starts following the touch input.
@export var clampzone_ratio: float = 1.0
## The initial position of the joystick as a ratio of the control's size. [code](0, 0)[/code] is top-left and [code](1, 1)[/code] is bottom-right.
@export var initial_offset_ratio: Vector2 = Vector2(0.5, 0.5)
## The action to trigger when the joystick is moved left.
@export var action_left: StringName = "ui_left"
## The action to trigger when the joystick is moved right.
@export var action_right: StringName = "ui_right"
## The action to trigger when the joystick is moved up.
@export var action_up: StringName = "ui_up"
## The action to trigger when the joystick is moved down.
@export var action_down: StringName = "ui_down"
## The visibility mode to use.
@export var visibility: VisibilityMode = VisibilityMode.ALWAYS
## Default ring joystick color.
@export var ring_normal_color: Color = Color.WHITE
## Default Tip joystick color.
@export var tip_normal_color: Color = Color.WHITE
## Ring joystick color when pressed.
@export var ring_pressed_color: Color = Color.GRAY
## Tip joystick color when pressed.
@export var tip_pressed_color: Color = Color.GRAY
## The texture to use for the joystick base. When [code]null[/code], a ring is drawn using the ring_normal_color and ring_pressed_color.
@export var joystick_texture: Texture2D
## The texture to use for the joystick tip. When [code]null[/code], a circle is drawn using the tip_normal_color and tip_pressed_color.
@export var tip_texture: Texture2D

var is_pressed: bool = false
var has_input: bool = false
var has_moved: bool = false
var raw_input_vector: Vector2
var input_vector: Vector2
#var is_flick_canceled: bool = false
var touch_index: int = -1

var joystick_pos: Vector2
var tip_pos: Vector2

func _enter_tree() -> void:
	joystick_pos = get_size() * initial_offset_ratio
	tip_pos = joystick_pos

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_pressed():
			var rect: Rect2 = Rect2(Vector2.ZERO, size)
			if touch_index == -1 && rect.has_point(event.position):
				var base_rect: Rect2 = Rect2(joystick_pos - Vector2(0.5, 0.5) * joystick_size, Vector2(joystick_size, joystick_size))
				if joystick_mode == JoystickMode.FOLLOWING || joystick_mode == JoystickMode.DYNAMIC || \
				 (base_rect.has_point(event.position) && joystick_mode == JoystickMode.FIXED):
					if joystick_mode == JoystickMode.FOLLOWING || joystick_mode == JoystickMode.DYNAMIC:
						joystick_pos = event.position
					
					is_pressed = true
					touch_index = event.index
					_update_joystick(event.position)
			elif touch_index == event.index:
				is_pressed = false
				
				_reset()
	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			has_moved = true
			_update_joystick(event.position)

func _draw() -> void:
	if !Engine.is_editor_hint() && visibility == VisibilityMode.WHEN_TOUCHED && !is_pressed:
		return
	
	if joystick_texture != null:
		var rect: Rect2 = Rect2(joystick_pos - Vector2(0.5, 0.5) * joystick_size, Vector2(joystick_size, joystick_size))
		draw_texture_rect(joystick_texture, rect, false)
	else:
		draw_circle(joystick_pos, joystick_size * 0.5, ring_pressed_color if is_pressed else ring_normal_color, false, joystick_size * 0.05, true)
	
	if tip_texture != null:
		var rect: Rect2 = Rect2(tip_pos - Vector2(0.5, 0.5) * tip_size, Vector2(tip_size, tip_size))
		draw_texture_rect(tip_texture, rect, false)
	else:
		draw_circle(tip_pos, tip_size * 0.5, tip_pressed_color if is_pressed else tip_normal_color, true, -1, true)

					
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_reset()

func _update_joystick(pos: Vector2):
	var offset: Vector2 = pos - joystick_pos
	var length: float = offset.length()
	var direction: Vector2 = offset.normalized()
	
	var clampzone_radius: float = joystick_size * 0.5 * clampzone_ratio
	
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	if joystick_mode == JoystickMode.FOLLOWING && length > clampzone_radius && rect.has_point(pos):
		joystick_pos = pos - direction * clampzone_radius
	
	if length > clampzone_radius:
		length = clampzone_radius
		offset = direction * length
	
	tip_pos = joystick_pos + offset
	
	#var was_pressed: bool = has_input
	
	raw_input_vector = offset / clampzone_radius
	
	if length > deadzone_ratio * clampzone_radius:
		has_input = true
		var scaled: float = inverse_lerp(deadzone_ratio * clampzone_radius, clampzone_radius, length)
		input_vector = direction * scaled
	else:
		has_input = false
		input_vector = Vector2()
	
	_handle_input_actions()
	queue_redraw()

func _handle_input_actions():
	if input_vector.x >= 0.0 && Input.is_action_pressed(action_left):
		Input.action_release(action_left)
	if input_vector.x <= 0.0 && Input.is_action_pressed(action_right):
		Input.action_release(action_right)
	if input_vector.y >= 0.0 && Input.is_action_pressed(action_up):
		Input.action_release(action_up)
	if input_vector.y <= 0.0 && Input.is_action_pressed(action_down):
		Input.action_release(action_down)
	
	if input_vector.x < 0.0:
		Input.action_press(action_left, -input_vector.x);
	elif input_vector.x > 0.0:
		Input.action_press(action_right, input_vector.x);
	if input_vector.y < 0.0:
		Input.action_press(action_up, -input_vector.y);
	elif input_vector.y > 0.0:
		Input.action_press(action_down, input_vector.y);

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func _reset():
	is_pressed = false
	has_input = false
	has_moved = false
	raw_input_vector = Vector2()
	input_vector = Vector2()
	#is_flick_canceled = false
	touch_index = -1
	joystick_pos = get_size() * initial_offset_ratio
	tip_pos = joystick_pos

	for action in [action_left, action_right, action_down, action_up]:
		if Input.is_action_pressed(action):
			Input.action_release(action)

	queue_redraw()
