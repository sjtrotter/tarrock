extends SceneTree

## Diagnostic: boot the persistent layer windowed, wait, screenshot, dump the HUD tree.

var _frames := 0
var _out := "/tmp/hud-probe.png"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	var packed: PackedScene = load("res://scenes/persistent_layer.tscn")
	root.add_child(packed.instantiate())


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 90:
		return false
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(_out)
	print("saved ", _out, " ", img.get_width(), "x", img.get_height())
	var ui_root := root.find_child("UIRoot", true, false)
	print("UIRoot: ", ui_root, " layer=", ui_root.layer if ui_root is CanvasLayer else -999)
	_dump(ui_root, 0)
	quit(0)
	return true


func _dump(node: Node, depth: int) -> void:
	if node == null:
		return
	var line := "  ".repeat(depth) + node.name + " (" + node.get_class() + ")"
	if node is Control:
		var c := node as Control
		line += " vis=%s rect=%s min=%s modulate=%s" % [str(c.is_visible_in_tree()), str(c.get_global_rect()), str(c.get_combined_minimum_size()), str(c.modulate)]
	elif node is CanvasLayer:
		line += " visible=%s layer=%d" % [str((node as CanvasLayer).visible), (node as CanvasLayer).layer]
	print(line)
	if depth < 6:
		for child: Node in node.get_children():
			_dump(child, depth + 1)
