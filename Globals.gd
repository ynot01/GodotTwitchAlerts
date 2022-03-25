extends Node

# Debug
#var filepath = "res://"
#var userpath = OS.get_user_data_dir()+"/"

# Export
var filepath = OS.get_executable_path().get_base_dir()+"/"
var userpath = OS.get_executable_path().get_base_dir()+"/"

# Encryption key to encrypt OAuth with
var enc_key = "wpez2xEUEA"


# Do not change
var global_emotes_loaded = false
var chnl_emotes_loaded = false
