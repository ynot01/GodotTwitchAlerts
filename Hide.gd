extends Button


func _toggled(bol):
	if bol:
		text = "Hide"
		get_parent().get_node("oauth_token").secret = false
	else:
		text = "Unhide"
		get_parent().get_node("oauth_token").secret = true
