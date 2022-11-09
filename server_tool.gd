extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var email = "super2@heroes.com"
	var password = "batsignal2"
	var session : NakamaSession = yield(Global.client.authenticate_email_async(email, password,"chamo"), "completed")
	print(session)
	if session.is_exception():
		print("login error!!!!")
		print(session)
		return
	
	var payload={"sdfsd":[1,2,3],"aaa":1}
	var world: NakamaAPI.ApiRpc = yield(Global.client.rpc_async(session, "level_battle_summary", JSON.print(payload)), "completed")
	print(world)
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
	# 	print("An error occurred")
	# 	return
	# var read_object_id = NakamaStorageObjectId.new("hats", "favorite_hats", session.user_id)
	# var result = yield(Global.client.read_storage_objects_async(session, [read_object_id]), "completed")

	# print("Unlocked hats: ")
	# for o in result.objects:
	# 	print("%s" % o)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
