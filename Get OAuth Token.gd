extends Button

var client_id = "kukpjyjkfttxf7ru2jjnbext6mm79k"
var redirect_uri = "https://twitchapps.com/tokengen/"
var scope = "bits:read%20channel:read:subscriptions"

func _pressed():
	var url = "https://api.twitch.tv/kraken/oauth2/authorize?response_type=token&client_id="
	url += client_id
	url += "&redirect_uri="
	url += redirect_uri
	url += "&scope="
	url += scope
	url += "&force_verify=true"
	
# warning-ignore:return_value_discarded
	OS.shell_open(url)
