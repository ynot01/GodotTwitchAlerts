extends LineEdit

onready var userpath = get_parent().get_parent().get_parent().userpath # Main.userpath
onready var UserInfo = get_parent()

func _ready():
	var file = File.new()
	if file.open_encrypted_with_pass(userpath + "oauth.key", File.READ, Globals.enc_key) == OK:
		text = file.get_as_text()
		UserInfo.get_node("UsernameLabel").show()
		UserInfo.get_node("username").show()
		UserInfo.get_node("UserIDLabel").show()
		UserInfo.get_node("userid").show()
		UserInfo.get_node("Get UserID").show()
	file.close()


func _on_oauth_token_text_changed(new_text):
	if new_text.length() == 30:
		var file = File.new()
		file.open_encrypted_with_pass(userpath + "oauth.key", File.WRITE, Globals.enc_key)
		file.store_string(new_text)
		file.close()
		UserInfo.get_node("UsernameLabel").show()
		UserInfo.get_node("username").show()
		UserInfo.get_node("UserIDLabel").show()
		UserInfo.get_node("userid").show()
		UserInfo.get_node("Get UserID").show()
