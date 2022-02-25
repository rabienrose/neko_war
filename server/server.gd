extends Node2D

func _ready():
    var peer = NetworkedMultiplayerENet.new()
    peer.create_server(8001, 5)
    get_tree().network_peer = peer
    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

var player_info = {}

func _player_connected(id):
    print("_player_connected: ",id)

func _player_disconnected(id):
    print("_player_disconnected: ",id)


