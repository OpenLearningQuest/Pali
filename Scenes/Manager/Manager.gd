extends Node

@onready var main_menu_ui = $MainMenuUI

var enet = ENetMultiplayerPeer.new()
var peers: Array[int] = []
var peers_intro_done: Array[int] = []
var my_id: int = 0
var world: Node3D

func _ready() -> void:	
	if OS.has_feature("dedicated_server"):
		on_create_server_pressed()
	else:
		main_menu_ui.connect("join_server_pressed", on_join_server_pressed)
		main_menu_ui.connect("create_server_pressed", on_create_server_pressed)
		
func on_join_server_pressed(display_name: String):
	print("Join server btn pressed with name %s" % display_name)
	print("Creating client")
	var err = enet.create_client(Global.SERVER_ADDRESS, Global.PORT)
	if err:
		print("Failed to create client")
	
	multiplayer.connected_to_server.connect(on_connected_to_server)
	multiplayer.connection_failed.connect(on_connection_failed)
	multiplayer.server_disconnected.connect(on_server_disconnected)
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
	multiplayer.multiplayer_peer = enet
	my_id = enet.get_unique_id()

func on_create_server_pressed():
	print("Creating server")
	var err = enet.create_server(Global.PORT, 2)
	if err:
		print("Failed to create server")
		return

	multiplayer.peer_connected.connect(on_peer_connected_to_server)
	multiplayer.peer_disconnected.connect(on_peer_disconnected_to_server)
	multiplayer.multiplayer_peer = enet
	my_id = enet.get_unique_id()
	main_menu_ui.hide()

func on_start_game():
	create_world.rpc()

@rpc
func create_world() -> void:
	print("[%s] Create world called" % multiplayer.get_unique_id())
	main_menu_ui.hide()
	var world_scene = load("res://Scenes/World/World.tscn")
	world = world_scene.instantiate()
	add_child(world)
	world.connect("intro_done", on_intro_done)
	
@rpc
func start_tweens():
	world.start_cards_tween()
	
@rpc("any_peer")
func on_intro_done_server(id: int):
	if not multiplayer.is_server(): return
	
	peers_intro_done.append(id)
	
	if len(peers_intro_done) == 2:
		start_tweens.rpc()
	
func on_intro_done():
	on_intro_done_server.rpc(my_id)

func on_peer_connected_to_server(id: int) -> void:
	print("[1] peer '%s' connected" % id)
	peers.append(id)
	print("[1] peers ", peers)
	
	if len(peers) == 2:
		create_world.rpc()

func on_peer_disconnected_to_server(id: int) -> void:
	print("[1] peer '%s' disconnected" % id)
	peers.erase(id)
	print("[1] peers ", peers)
	
func on_peer_connected(id: int) -> void:
	print("[%s] peer '%s' connected" % [my_id , id])

func on_peer_disconnected(id: int) -> void:
	print("[%s] peer '%s' disconnected" % [my_id, id])
	
func on_connected_to_server() -> void:
	print("[%s] on_connected_to_server called" % my_id)
	
func on_connection_failed() -> void:
	print("[%s] on_connection_failed called" % my_id)
	
func on_server_disconnected() -> void:
	print("[%s] on_server_disconnected called" % my_id)
