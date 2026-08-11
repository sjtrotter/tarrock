extends Node2D

signal leap_point_reached

@onready var _leap_point: Area2D = $LeapPoint
@onready var _fool: CharacterBody2D = $World/Fool

var _leap_fired := false


func _ready() -> void:
	_leap_point.body_entered.connect(_on_leap_point_body_entered)


func _on_leap_point_body_entered(body: Node2D) -> void:
	if _leap_fired:
		return
	if body != _fool and not body.is_in_group("fool"):
		return
	_leap_fired = true
	print("LEAP_POINT_REACHED")
	leap_point_reached.emit()
