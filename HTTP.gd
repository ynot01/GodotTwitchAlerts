extends HTTPRequest

onready var userpath = get_parent().get_parent().get_parent().get_parent().userpath # Main.userpath
onready var UserInfo = get_parent().get_parent()
onready var GetUserID = get_parent()

func _ready():
	var config = ConfigFile.new()
	config.load(userpath + "alert_settings.cfg")
	UserInfo.get_node("userid").text = config.get_value("User Info", "user_id", "")
	UserInfo.get_node("username").text = config.get_value("User Info", "username", "")


func _on_userid_text_changed(new_text):
	var config = ConfigFile.new()
	config.load(userpath + "alert_settings.cfg")
	config.set_value("User Info", "user_id", new_text)
	config.save(userpath + "alert_settings.cfg")

func _on_HTTP_request_completed(_result, _response_code, _headers, body):
	var parse_attempt = JSON.parse(body.get_string_from_utf8())
	if parse_attempt.error != OK:
		UserInfo.get_node("StatusHTTP").text = "ERROR:\n"+body.get_string_from_utf8()
		GetUserID.disabled = false
		return
	
	var parsed = parse_attempt.result
	if typeof(parsed) == 18 and parsed.has("data") and parsed["data"].size() > 0:
		UserInfo.get_node("userid").text = str(parsed["data"][0]["id"])
		var config = ConfigFile.new()
		config.load(userpath + "alert_settings.cfg")
		config.set_value("User Info", "user_id", str(parsed["data"][0]["id"]))
		config.save(userpath + "alert_settings.cfg")
		UserInfo.get_node("StatusHTTP").text = ""
	else:
		UserInfo.get_node("StatusHTTP").text = "ERROR IN TWITCH RESPONSE:\n"+str(parsed)
	GetUserID.disabled = false


func _on_Get_UserID_pressed():
	GetUserID.disabled = true
	var username = UserInfo.get_node("username").text
	var key = UserInfo.get_node("oauth_token").text
	request("https://api.twitch.tv/helix/users?login="+username, ["Authorization: Bearer "+key, "Client-Id: kukpjyjkfttxf7ru2jjnbext6mm79k"])

