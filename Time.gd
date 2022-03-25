extends Label

func format_time(time):
	var digits = ""
	
	var hours = "%02d:" % [time / 3600]
	digits += hours
	
	var minutes = "%02d:" % [time / 60]
	digits += minutes
	
	var seconds = "%02d" % [int(ceil(time)) % 60]
	digits += seconds
	
	return digits

func _process(_delta):
	var time = OS.get_ticks_msec()/1000.0
	text = "["+format_time(time)+"]\n"
	text += str(time)
