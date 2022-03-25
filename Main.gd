extends Control

var version = 1

var filepath = Globals.filepath
var userpath = Globals.userpath

# Any donation below this amount will not trigger TTS
var minimum_tts_usd : float = 5.00 # dollars $
var minimum_tts_bits : int = 100
# Any characters past this limit will get cut off on TTS
var maximum_tts_length : int = 175 # characters

# List of paths to sounds used at the start of alerts
var sound_alert_list : Array = []
# List of paths to images/gifs displayed at the top of alerts
var image_list : Array = []

# List of pending alerts. Structure is ["author", "message", usd]
var pending_alerts : Array = []

# Is an alert currently playing? If this is false, a new alert can safely start
var alert_playing : bool = false

var WelcomeHiding : bool = false

func _input(event):
	if !$Options.visible:
		if event.is_action_pressed("debug_tts"):
			
			# Tier 3 Sub
			pending_alerts.insert(pending_alerts.size(), ["ynot01", "A Twitch baby is born! :)", SUBSCRIPTION, 3000, [{"start": 23,"end": 2,"id": 1}], 4])
			
			# $5.50 donation
			#pending_alerts.insert(pending_alerts.size(), ["ynot01", "A Twitch baby is born! :)", DONATION, 5.5])
			
			# 100 bits
			#pending_alerts.insert(pending_alerts.size(), ["ynot01", "A Twitch baby is born! :)", BITS, 100])
		
		if event.is_action_pressed("options"):
			$Options/Values/minimum_tts_usd.text = "%.2f" % minimum_tts_usd
			$Options/Values/maximum_tts_length.text = str(maximum_tts_length)
			$Options.show()
		
		if event.is_action_pressed("stop_tts"):
			$TTS.stop()
			if $Welcome.visible and !WelcomeHiding:
				WelcomeHiding = true
				$Tween.interpolate_property($Welcome, "modulate:a",
					$Welcome.modulate.a, 0, 3,
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
				$Tween.interpolate_property($Welcome/BG, "modulate:a",
					$Welcome/BG.modulate.a, 0, 1.5,
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
				$Tween.start()
				yield(get_tree().create_timer(3), "timeout")
				$Welcome.hide()

func _ready():
	get_tree().get_root().set_transparent_background(true)
	var dir = Directory.new()
	if !dir.dir_exists(filepath+"sounds"):
		dir.make_dir(filepath+"sounds")
	if !dir.dir_exists(filepath+"images"):
		dir.make_dir(filepath+"images")
	
	$FetchUpdate.request("https://raw.githubusercontent.com/ynot01/GodotTwitchAlerts/main/version.txt")
	
	dir.open(filepath+"sounds")
	dir.list_dir_begin(true)
	var filename = dir.get_next()
	while filename != "":
		if filename.get_extension() != "import":
			sound_alert_list.insert(sound_alert_list.size(), filepath+"sounds/"+filename)
		filename = dir.get_next()
	
	dir.open(filepath+"images")
	dir.list_dir_begin(true)
	filename = dir.get_next()
	while filename != "":
		if filename.get_extension() != "import":
			image_list.insert(image_list.size(), filepath+"images/"+filename)
		filename = dir.get_next()
	
	var config = ConfigFile.new()
	config.load(userpath + "alert_settings.cfg")
	
	var typetest
	
	# Purifying typecast to prevent errors and crashes from erroneous .cfg use
	typetest = config.get_value("TTS", "TTS USD Requirement", minimum_tts_usd)
	if typeof(typetest) == 3: # TYPE_REAL (float)
		minimum_tts_usd = typetest
	else:
		config.set_value("TTS", "TTS USD Requirement", minimum_tts_usd)
	
	typetest = config.get_value("TTS", "TTS Bits Requirement", minimum_tts_bits)
	if typeof(typetest) == 2: # TYPE_INT
		minimum_tts_bits = typetest
	else:
		config.set_value("TTS", "TTS Bits Requirement", minimum_tts_bits)
	
	typetest = config.get_value("TTS", "TTS Character Limit", maximum_tts_length)
	if typeof(typetest) == 2: # TYPE_INT
		maximum_tts_length = typetest
	else:
		config.set_value("TTS", "TTS Character Limit", maximum_tts_length)
	
	typetest = config.get_value("Binds", "options", KEY_O)
	if typeof(typetest) == 2:
		var new_input = InputEventKey.new()
		new_input.set_scancode(typetest)
		InputMap.action_erase_events("options")
		InputMap.action_add_event("options", new_input)
	else:
		config.set_value("Binds", "options", KEY_O)
	
	typetest = config.get_value("Binds", "stop_tts", KEY_SPACE)
	if typeof(typetest) == 2:
		var new_input = InputEventKey.new()
		new_input.set_scancode(typetest)
		InputMap.action_erase_events("stop_tts")
		InputMap.action_add_event("stop_tts", new_input)
	else:
		config.set_value("Binds", "stop_tts", KEY_SPACE)
	
	typetest = config.get_value("Binds", "debug_tts", KEY_J)
	if typeof(typetest) == 2:
		var new_input = InputEventKey.new()
		new_input.set_scancode(typetest)
		InputMap.action_erase_events("debug_tts")
		InputMap.action_add_event("debug_tts", new_input)
	else:
		config.set_value("Binds", "debug_tts", KEY_J)
	
	config.save(userpath + "alert_settings.cfg")
	
	$Welcome/Label.text = "Welcome to Godot Twitch Alerts\nPress "
	$Welcome/Label.text += InputMap.get_action_list("options")[0].as_text()
	$Welcome/Label.text += " to configure options\nPress "
	$Welcome/Label.text += InputMap.get_action_list("stop_tts")[0].as_text()
	$Welcome/Label.text += " to dismiss"
	
	for txt in $Options/Rebinds.get_children():
		if txt is Button:
			txt.display_current_key()

func _process(_delta):
	$Debug.text = "Pending:\n"
	for n in pending_alerts:
		$Debug.text += str(n)+"\n"
	
	if !alert_playing and pending_alerts.size() > 0:
		alert_playing = true
		if pending_alerts[0].size() > 5:
			alert(pending_alerts[0][0], pending_alerts[0][1], pending_alerts[0][2], pending_alerts[0][3], pending_alerts[0][4], pending_alerts[0][5])
		elif pending_alerts[0].size() > 4:
			alert(pending_alerts[0][0], pending_alerts[0][1], pending_alerts[0][2], pending_alerts[0][3], pending_alerts[0][4])
		elif pending_alerts[0].size() > 3:
			alert(pending_alerts[0][0], pending_alerts[0][1], pending_alerts[0][2], pending_alerts[0][3])
		elif pending_alerts[0].size() > 2:
			alert(pending_alerts[0][0], pending_alerts[0][1], pending_alerts[0][2])
		else:
			alert(pending_alerts[0][0], pending_alerts[0][1])
		pending_alerts.remove(0)



var rng = RandomNumberGenerator.new()

enum {DONATION, BITS, SUBSCRIPTION}

func alert(author, message_raw, type = DONATION, amount = 0, emote_data = [], consecutive_months = 0):
	alert_playing = true
	
	var message = message_raw.substr(0,175)
	
	var authcolor = Color(randf(), randf(), randf()).to_html(false)
	
	rng.randomize()
	
	if image_list.size() > 0:
		var to_load = image_list[rng.randi_range(0, image_list.size()-1)]
		if to_load.get_extension() == "gif":
			var img = ImageFrames.new()
			img.load(to_load)
			var txtr = AnimatedTexture.new()
			txtr.frames = img.get_frame_count()
			for i in img.get_frame_count():
				var frame = img.get_frame_image(i)
				var tex = ImageTexture.new()
				tex.create_from_image(frame, 1)
				txtr.set_frame_texture(i, tex)
				txtr.set_frame_delay(i, img.get_frame_delay(i))
			$Alert/Sprite.texture = txtr
			$Alert/Sprite.texture.fps = 30
		else:
			var img = Image.new()
			img.load(to_load)
			var txtr = ImageTexture.new()
			txtr.create_from_image(img)
			$Alert/Sprite.texture = txtr
		
		var scale = 240.0 / $Alert/Sprite.texture.get_frame_texture(0).get_height()
		$Alert/Sprite.scale = Vector2(scale,scale)
	
	match(type):
		DONATION:
			$Alert/Author.bbcode_text = "[center][color=#"+authcolor+"]" + str(author) + "[/color] donated [color=#00FF00]$" + get_currency(amount) + "[/color][/center]"
		BITS:
			$Alert/Author.bbcode_text = "[center][color=#"+authcolor+"]" + str(author) + "[/color] donated [color=#1E69FF]" + str(amount) + " bits[/color][/center]"
		SUBSCRIPTION:
			if consecutive_months > 1:
				match(amount):
					0:
						$Alert/Author.bbcode_text = "[center][color=#"+authcolor+"]" + str(author) + "[/color] has [color=#8205B4]subscribed[/color] for "+str(consecutive_months)+" months with [color=#FA1ED2]prime[/color]![/center]"
					1000:
						$Alert/Author.bbcode_text = "[center][color=#"+authcolor+"]" + str(author) + "[/color] has [color=#8205B4]subscribed[/color] for "+str(consecutive_months)+" months![/center]"
					2000:
						$Alert/Author.bbcode_text = "[center][color=#"+authcolor+"]" + str(author) + "[/color] has [color=#8205B4]subscribed[/color] for "+str(consecutive_months)+" months with [color=#BE0078]tier 2[/color]![/center]"
					3000:
						$Alert/Author.bbcode_text = "[center][color=#"+authcolor+"]" + str(author) + "[/color] has [color=#8205B4]subscribed[/color] for "+str(consecutive_months)+" months with [color=#41145F]tier 3[/color]![/center]"
			else:
				match(amount):
					0:
						$Alert/Author.bbcode_text = "[center][color=#"+authcolor+"]" + str(author) + "[/color] has [color=#FA1ED2]subscribed with prime[/color]![/center]"
					1000:
						$Alert/Author.bbcode_text = "[center][color=#"+authcolor+"]" + str(author) + "[/color] has [color=#8205B4]subscribed[/color]![/center]"
					2000:
						$Alert/Author.bbcode_text = "[center][color=#"+authcolor+"]" + str(author) + "[/color] has subscribed with [color=#BE0078]tier 2[/color]![/center]"
					3000:
						$Alert/Author.bbcode_text = "[center][color=#"+authcolor+"]" + str(author) + "[/color] has subscribed with [color=#41145F]tier 3[/color]![/center]"
	
	var lbl = Label.new()
	lbl.autowrap = true
	lbl.text = "["+format_time(OS.get_ticks_msec()/1000.0)+"]"
	$Options/Console2/ScrollContainer/VBoxContainer.add_child(lbl)
	
	var authlbl = Label.new()
	authlbl.add_color_override("font_color", Color("FACDCD"))
	authlbl.autowrap = true
	authlbl.text = $Alert/Author.text
	$Options/Console2/ScrollContainer/VBoxContainer.add_child(authlbl)
	
	var msglbl = Label.new()
	msglbl.add_color_override("font_color", Color("FAB4FF"))
	msglbl.autowrap = true
	msglbl.text = message_raw
	$Options/Console2/ScrollContainer/VBoxContainer.add_child(msglbl)
	
	if Globals.global_emotes_loaded and Globals.chnl_emotes_loaded:
		$Alert/Message.bbcode_text = ""
		var last_end = 0
		var strmsg = str(message_raw)
		for n in emote_data:
			var image = Image.new()
			image.load(userpath+"emotes/"+str(n["id"])+".png")
			var txtr = ImageTexture.new()
			txtr.create_from_image(image)
			if !txtr:
				$WebSocket.connection_print("Emote file not found! ID: "+str(n["id"]), $WebSocket.FAIL)
				$Alert/Message.bbcode_text += strmsg.substr(last_end, n["start"]+n["end"])
			else:
				$Alert/Message.bbcode_text += "[center]"+strmsg.substr(last_end, n["start"])+"[/center]"
				$Alert/Message.add_image(txtr)
			last_end = n["start"] + n["end"]
	else:
		$Alert/Message.bbcode_text = "[center]"+str(message_raw)+"[/center]"
	
	if !(type == BITS and amount < minimum_tts_bits) and sound_alert_list.size() > 0:
		$Sound.stream = load(sound_alert_list[rng.randi_range(0, sound_alert_list.size()-1)])
		$Sound.play()
	
	
	$Tween.interpolate_property($Alert, "modulate:a",
		0, 1, 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	
	var stream_len
	if $Sound.stream:
		stream_len = $Sound.stream.get_length()
	else:
		stream_len = 0
	yield(get_tree().create_timer(stream_len + 1), "timeout")
	
	
	
	if (type == BITS and amount >= minimum_tts_bits) or (type == SUBSCRIPTION) or (type == DONATION and amount >= minimum_tts_usd):
		$TTS.speak(message)
	else:
		yield(get_tree().create_timer(3), "timeout")
		$Tween.interpolate_property($Alert, "modulate:a",
			1, 0, 1,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Tween.start()
		yield(get_tree().create_timer(2), "timeout")
		alert_playing = false

func format_time(time):
	var digits = ""
	
	var hours = "%02d:" % [time / 3600]
	digits += hours
	
	var minutes = "%02d:" % [time / 60]
	digits += minutes
	
	var seconds = "%02d" % [int(ceil(time)) % 60]
	digits += seconds
	
	return digits


func _on_TTS_utterance_begin(_utterance):
	#print("TTS Begin: ", utterance)
	pass


func _on_TTS_utterance_end(_utterance):
	#print("TTS End: ", utterance)
	yield(get_tree().create_timer(1), "timeout")
	$Tween.interpolate_property($Alert, "modulate:a",
		1, 0, 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	yield(get_tree().create_timer(2), "timeout")
	alert_playing = false


func _on_TTS_utterance_stop(_utterance):
	#print("TTS Stop: ", utterance)
	yield(get_tree().create_timer(1), "timeout")
	$Tween.interpolate_property($Alert, "modulate:a",
		1, 0, 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	yield(get_tree().create_timer(2), "timeout")
	alert_playing = false


func _on_minimum_tts_usd_text_changed(_str):
	var value = $Options/Values/minimum_tts_usd.text
	var config = ConfigFile.new()
	minimum_tts_usd = float(value)
	config.load(userpath + "alert_settings.cfg")
	config.set_value("TTS", "TTS USD Requirement", float(value))
	config.save(userpath + "alert_settings.cfg")


func _on_maximum_tts_length_text_changed(_str):
	var value = $Options/Values/maximum_tts_length.text
	var config = ConfigFile.new()
	maximum_tts_length = int(value)
	config.load(userpath + "alert_settings.cfg")
	config.set_value("TTS", "TTS Character Limit", int(value))
	config.save(userpath + "alert_settings.cfg")


func _on_minimum_tts_bits_text_changed(_str):
	var value = $Options/Values/minimum_tts_bits.text
	var config = ConfigFile.new()
	minimum_tts_bits = int(value)
	config.load(userpath + "alert_settings.cfg")
	config.set_value("TTS", "TTS Bits Requirement", int(value))
	config.save(userpath + "alert_settings.cfg")


func _on_FetchUpdate_request_completed(_result, response_code, _headers, body):
	var updated = body.get_string_from_utf8()
	var config = ConfigFile.new()
	config.load(userpath + "alert_settings.cfg")
	var seen = config.get_value("User Info", "update_seen", 1) # Don't want to spam users with the same update
	if response_code < 400 and int(updated) > version and int(updated) > seen:
		config.set_value("User Info", "update_seen", int(updated))
		config.save(userpath + "alert_settings.cfg")
		$ConfirmationDialog.text = "Your version: "+str(version)
		$ConfirmationDialog.text += "\nUpdated version: "+updated
		$ConfirmationDialog.text += "\nClick OK to open the repo"
		$ConfirmationDialog.popup()

func _on_ConfirmationDialog_confirmed():
	OS.shell_open("https://github.com/ynot01/GodotTwitchAlerts")

func get_currency(number):

	# Place the decimal separator
	var txt_numb = "%.2f" % number

	# Place the thousands separator
	for idx in range(txt_numb.find(".") - 3, 0, -3):
		txt_numb = txt_numb.insert(idx, ",")
	return(txt_numb)
