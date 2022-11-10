extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var cmds=OS.get_cmdline_args()
	var email = cmds[1]
	var password = cmds[2]
	print(email)
	# var email = "12345678@qq.com"
	# var password = "la009296"
	# var email = "283136745@qq.com"
	# var password = "la009296"
	var succ = yield(Global.login_remote(email, "", password, false), "completed")
	if succ:
		print("login succ")
		Global.fetch_level_data()
		# yield(Global.fetch_user_remote(), "completed")
		# yield(Global.request_level_battle("1"), "completed") 



	# var global_userid="00000000-0000-0000-0000-000000000000"
	# var unlocks_object_list = yield(Global.client.list_storage_objects_async(session, "global_data", global_userid, 3), "completed")
	# print(unlocks_object_list)
	# var favorite_hats = {"aaa":["cow333boy", "2222"]}
	# var can_read = 2 # Only the server and owner can read
	# var can_write = 1 # The server and owner can write
	# var serialized = JSON.print(favorite_hats)
	# var w_objs=[NakamaWriteStorageObject.new("global", "ssss", can_read, can_write,serialized,"")]
	# var acks : NakamaAPI.ApiStorageObjectAcks = yield(Global.client.write_storage_objects_async(session, w_objs), "completed")
	# if acks.is_exception():
	#     print("An error occurred")
	#     return
	# var read_object_id = NakamaStorageObjectId.new("hats", "favorite_hats", session.user_id)
	# var result = yield(Global.client.read_storage_objects_async(session, [read_object_id]), "completed")

	# print("Unlocked hats: ")
	# for o in result.objects:
	#     print("%s" % o)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
