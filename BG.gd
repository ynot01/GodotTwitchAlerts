extends ColorRect

onready var parent = get_parent()

func _on_BG_gui_input(event):
	if event.is_action_pressed("click"):
		parent.get_node("Values/maximum_tts_length").release_focus()
		parent.get_node("Values/minimum_tts_bits").release_focus()
		parent.get_node("Values/minimum_tts_usd").release_focus()
		parent.get_node("UserInfo/oauth_token").release_focus()
		parent.get_node("UserInfo/username").release_focus()
		parent.get_node("UserInfo/userid").release_focus()
