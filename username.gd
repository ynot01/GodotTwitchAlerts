extends LineEdit

onready var userpath = get_parent().get_parent().get_parent().userpath # Main.userpath

func _on_username_text_changed(new_text):
	var config = ConfigFile.new()
	config.load(userpath + "alert_settings.cfg")
	config.set_value("User Info", "username", new_text)
	config.save(userpath + "alert_settings.cfg")
