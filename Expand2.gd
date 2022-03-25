extends Button

var orig_pos = Vector2(104,336)
var new_pos = Vector2(936,0)

var orig_size = Vector2(192,232)
var orig_width = 180
var screen_size = Vector2(1024,600)
var screen_width = 1012

var console_pos = Vector2(0,368)
var vec_zero = Vector2(0,0)

onready var parent = get_parent()
onready var options = get_parent().get_parent()

func _toggled(toggle):
	if toggle:
		modulate.a = 0.5
		text = "Shrink"
		rect_position = new_pos
		parent.get_node("ConsoleBG").rect_position = vec_zero
		parent.get_node("ConsoleBG").rect_size = screen_size
		parent.get_node("ScrollContainer").rect_position = vec_zero
		parent.get_node("ScrollContainer").rect_size = screen_size
		parent.get_node("ScrollContainer/VBoxContainer").rect_min_size.x = screen_width
		options.get_node("Console1").hide()
		options.get_node("Time").hide()
	else:
		modulate.a = 1
		text = "Expand"
		rect_position = orig_pos
		parent.get_node("ConsoleBG").rect_position = console_pos
		parent.get_node("ConsoleBG").rect_size = orig_size
		parent.get_node("ScrollContainer").rect_position = console_pos
		parent.get_node("ScrollContainer").rect_size = orig_size
		parent.get_node("ScrollContainer/VBoxContainer").rect_min_size.x = orig_width
		options.get_node("Console1").show()
		options.get_node("Time").show()
