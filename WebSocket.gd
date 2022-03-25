extends Node

# https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html

# The URL we will connect to
var websocket_url = "wss://pubsub-edge.twitch.tv/"

# Client ID
var client_id = "kukpjyjkfttxf7ru2jjnbext6mm79k"

var userpath = Globals.userpath

# Our WebSocketClient instance
var _client = WebSocketClient.new()

var oauth = ""
var channelid = ""

var connected = false

func _ready():
	# Connect base signals to get notified of connection open, close, and errors.
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	# This signal is emitted when not using the Multiplayer API every time
	# a full packet is received.
	# Alternatively, you could check get_peer(1).get_available_packets() in a loop.
	_client.connect("data_received", self, "_on_data")
	yield(get_tree().create_timer(0.1), "timeout")
	attempt_connect()

var validating = false
var validated = false

func attempt_connect():
	if connected:
		return
	
	oauth = get_parent().get_node("Options/UserInfo/oauth_token").text
	#channelid = get_parent().get_node("Options/UserInfo/userid").text UserID now fetched from OAuth
	
	if oauth == "":
		yield(get_tree().create_timer(3), "timeout")
		attempt_connect()
		return
	
	if validating == false and validated == false:
		validating = true
		connection_print("Verifying token...")
		$ValidateOAuth.request("https://id.twitch.tv/oauth2/validate", ["Authorization: Bearer " + oauth])
		yield(get_tree().create_timer(3), "timeout")
		attempt_connect()
		return
	
	if validated == false:
		yield(get_tree().create_timer(3), "timeout")
		attempt_connect()
		return
	
	if channelid == "":
		yield(get_tree().create_timer(3), "timeout")
		attempt_connect()
		return
	
	var dir = Directory.new()
	if !dir.dir_exists(userpath + "emotes/"):
		dir.make_dir(userpath + "emotes/")
	
	$FetchChannelEmotes.request("https://api.twitch.tv/helix/chat/emotes?broadcaster_id="+channelid, ["Authorization: Bearer " + oauth, "Client-Id: " + client_id])
	$FetchGlobalEmotes.request("https://api.twitch.tv/helix/chat/emotes/global", ["Authorization: Bearer " + oauth, "Client-Id: " + client_id])
	
	var err = _client.connect_to_url(websocket_url)
	if err != OK:
		connection_print("Unable to connect", FAIL)
		yield(get_tree().create_timer(1), "timeout")
		attempt_connect()

func _closed(was_clean = false):
	connected = false
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	connection_print("Closed, clean: "+str(was_clean))
	yield(get_tree().create_timer(3), "timeout")
	attempt_connect()

func _connected(_proto = ""):
	connected = true
	# This is called on connection, "proto" will be the selected WebSocket
	# sub-protocol (which is optional)
	connection_print("Connected to Twitch", GOOD)
	# You MUST always use get_peer(1).put_packet to send data to server,
	# and not put_packet directly when not using the MultiplayerAPI.
	heartbeat()

var beat_it = 0
func heartbeat():
	beat_it += 1 # New connection will discard old ping timers
	listen()
	while connected:
		var current_iteration = beat_it
		yield(get_tree().create_timer(60), "timeout")
		if connected and current_iteration == beat_it:
			ping()

func listen():
	_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	_client.get_peer(1).put_packet(("""
{
	"type": "LISTEN",
	"nonce": "bit_"""+generate_word(12)+"""",
	"data": {
		"topics": ["channel-bits-events-v2."""+channelid+""""],
		"auth_token": \""""+oauth+"""\"
	}
}""").to_utf8())
	_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	_client.get_peer(1).put_packet(("""
{
	"type": "LISTEN",
	"nonce": "sub_"""+generate_word(12)+"""",
	"data": {
		"topics": ["channel-subscribe-events-v1."""+channelid+""""],
		"auth_token": \""""+oauth+"""\"
	}
}""").to_utf8())#generate_word

var lastdata = 0

func ping():
	_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	_client.get_peer(1).put_packet("""
{
	"type": "PING"
}""".to_utf8())
	yield(get_tree().create_timer(10), "timeout")
	if OS.get_ticks_msec() > lastdata + 15000:
		connection_print("Reconnecting due to ping timeout", FAIL)
		_client.disconnect_from_host(1000, "Reconnecting")

func _on_data():
	# print the received packet, you MUST always use get_peer(1).get_packet
	# to receive data from server, and not get_packet directly when not
	# using the MultiplayerAPI.
	lastdata = OS.get_ticks_msec()
	var data = _client.get_peer(1).get_packet().get_string_from_utf8()
	var parsed = JSON.parse(data).result
	if parsed.has("type"):
		if parsed["type"] == "RECONNECT":
			_client.disconnect_from_host(1000, "Reconnecting")
		elif parsed["type"] == "PONG":
			pass
		elif parsed["type"] == "MESSAGE":
			if parsed["data"]["topic"] == "channel-bits-events-v2."+channelid:
				var cheerparse = JSON.parse(parsed["data"]["message"]).result
				var author = ""
				var chat_message = cheerparse["data"]["chat_message"]
				var bits = cheerparse["data"]["bits_used"]
				if cheerparse["is_anonymous"]:
					author = "Anonymous"
				else:
					author = cheerparse["data"]["user_name"]
				get_parent().pending_alerts.insert(get_parent().pending_alerts.size(), [author, chat_message, get_parent().BITS, bits])
			elif parsed["data"]["topic"] == "channel-subscribe-events-v1."+channelid:
				var subparse = JSON.parse(parsed["data"]["message"]).result
				var author = subparse["data"]["user_name"]
				var chat_message = subparse["sub_message"]["message"]
				var months = subparse["cumulative_months"]
				var plan = subparse["sub_plan"]
				var emote_data = []
				for n in subparse["sub_message"]["emotes"]:
					emote_data.insert(emote_data.size(), n)
				if plan == "Prime":
					plan = 0
				else:
					plan = int(plan)
				get_parent().pending_alerts.insert(get_parent().pending_alerts.size(), [author, chat_message, get_parent().SUBSCRIPTION, plan, emote_data, months])
			else:
				connection_print("UNEXPECTED:", FAIL)
		elif parsed["type"] == "RESPONSE":
			if parsed["nonce"].begins_with("sub_"):
				connection_print("Subs hook:")
			elif parsed["nonce"].begins_with("bit_"):
				connection_print("Bits hook:")
			else:
				connection_print("UNEXPECTED:", FAIL)
			if parsed["error"] == "ERR_BADAUTH":
				connection_print("Bad OAuth token! Retrying...", FAIL)
				_client.disconnect_from_host(1000, "Reconnecting")
			elif parsed["error"] == "":
				connection_print("Successfully connected!", GOOD)
			else:
				connection_print("Error!", FAIL)
		else:
			connection_print("UNEXPECTED:", FAIL)
	connection_print("RECIEVED: "+str(data), DATA)



func _process(_delta):
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	_client.poll()
	
	if get_parent().get_node("Options").visible:
		$Label.show()
	else:
		$Label.hide()
	
	if connected:
		$Label.text = "CONNECTED TO TWITCH"
	else:
		$Label.text = "NOT CONNECTED TO TWITCH"
		

enum {NEUTRAL, GOOD, FAIL, DATA}

func connection_print(message, mood = NEUTRAL):
	var msg = str(message).strip_escapes()
	var lbl = Label.new()
	match mood:
		GOOD:
			lbl.add_color_override("font_color", Color("00ff00"))
		FAIL:
			lbl.add_color_override("font_color", Color("ff0000"))
		DATA:
			lbl.add_color_override("font_color", Color("BEFAE1"))
	lbl.autowrap = true
	lbl.text = "["+format_time(OS.get_ticks_msec()/1000.0)+"] "+msg
	print(lbl.text)
	get_parent().get_node("Options/Console1/ScrollContainer/VBoxContainer").add_child(lbl)



func format_time(time):
	var digits = ""
	
	var hours = "%02d:" % [time / 3600]
	digits += hours
	
	var minutes = "%02d:" % [time / 60]
	digits += minutes
	
	var seconds = "%02d" % [int(ceil(time)) % 60]
	digits += seconds
	
	return digits

# {"status":401,"message":"invalid access token"}
# {"client_id":"kukpjyjkfttxf7ru2jjnbext6mm79k","login":"ynot01","scopes":["bits:read","channel:read:subscriptions"],"user_id":"35903581","expires_in":5591253}

var characters = 'abcdefghijklmnopqrstuvwxyz123456789'
func generate_word(length):
	var word: String = ""
	var n_char = len(characters)
	for i in range(length):
		word += characters[randi()% n_char]
	return word

func _on_ValidateOAuth_request_completed(_result, response_code, _headers, body):
	if response_code >= 400:
		validated = false
		connection_print("HTTP Error: "+str(response_code), FAIL)
		connection_print(body.get_string_from_utf8())
		validating = false
		return
	
	var parse = JSON.parse(body.get_string_from_utf8()).result
	connection_print("RECIEVED: "+str(body.get_string_from_utf8()), DATA)
	if parse.has("status"):
		validated = false
		connection_print("Token invalid", FAIL)
		validating = false
		return
	
	if parse.has("scopes") and parse["scopes"][0] == "bits:read" and parse["scopes"][1] == "channel:read:subscriptions":
		validated = true
		connection_print("Token validated, expires in " + str(parse["expires_in"]/60.0/60.0/24.0) + " days", GOOD)
		channelid = parse["user_id"]
		validating = false
		return
	
	validating = false

var chnl_emoteid : String

func _on_FetchChannelEmotes_request_completed(_result, response_code, _headers, body):
	if response_code >= 400:
		connection_print("Channel Emotes HTTP Error: "+str(response_code), FAIL)
		connection_print(body.get_string_from_utf8())
		return
	
	connection_print("Fetching channel emotes")
	
	var dir = Directory.new()
	dir.open(userpath + "emotes/")
	
	var emotes_dl = 0
	var parse = JSON.parse(body.get_string_from_utf8()).result
	for n in parse["data"]:
		chnl_emoteid = n["id"]
		if !dir.file_exists(userpath + "emotes/" + chnl_emoteid + ".png"):
			emotes_dl += 1
			connection_print("Downloading channel emote: " + chnl_emoteid)
			$DLChannelEmote.request(n["images"]["url_1x"])
			yield(get_node("DLChannelEmote"), "request_completed")
			yield(get_tree().create_timer(0.05), "timeout")
	Globals.chnl_emotes_loaded = true
	connection_print("Finished downloading "+str(emotes_dl)+" channel emotes")

func _on_DLChannelEmote_request_completed(_result, response_code, _headers, body):
	if response_code >= 400:
		connection_print("Emote channel DL: "+chnl_emoteid+"\n HTTP Error: "+str(response_code), FAIL)
		connection_print(body.get_string_from_utf8())
		return
	var file = File.new()
	var err = file.open(userpath + "emotes/" + chnl_emoteid + ".png", File.WRITE)
	if err == OK:
		file.store_buffer(body)
		file.close()
		connection_print("Emote channel downloaded: " + chnl_emoteid, GOOD)
	else:
		connection_print("Emote channel file error! Code: "+str(err), FAIL)

var global_emoteid : String

func _on_FetchGlobalEmotes_request_completed(_result, response_code, _headers, body):
	if response_code >= 400:
		connection_print("Channel Emotes HTTP Error: "+str(response_code), FAIL)
		connection_print(body.get_string_from_utf8())
		return
	
	connection_print("Fetching global emotes")
	
	var dir = Directory.new()
	dir.open(userpath + "emotes/")
	
	var emotes_dl = 0
	var parse = JSON.parse(body.get_string_from_utf8()).result
	for n in parse["data"]:
		global_emoteid = n["id"]
		if !dir.file_exists(userpath + "emotes/" + global_emoteid + ".png"):
			emotes_dl += 1
			connection_print("Downloading global emote: " + global_emoteid)
			$DLGlobalEmote.request(n["images"]["url_1x"])
			yield(get_node("DLGlobalEmote"), "request_completed")
			yield(get_tree().create_timer(0.05), "timeout")
	Globals.global_emotes_loaded = true
	connection_print("Finished downloading "+str(emotes_dl)+" global emotes")


func _on_DLGlobalEmote_request_completed(_result, response_code, _headers, body):
	if response_code >= 400:
		connection_print("Emote global DL: "+global_emoteid+"\n HTTP Error: "+str(response_code), FAIL)
		connection_print(body.get_string_from_utf8())
		return
	var file = File.new()
	var err = file.open(userpath + "emotes/" + global_emoteid + ".png", File.WRITE)
	if err == OK:
		file.store_buffer(body)
		file.close()
		connection_print("Emote global downloaded: " + global_emoteid, GOOD)
	else:
		connection_print("Emote global file error! Code: "+str(err), FAIL)
