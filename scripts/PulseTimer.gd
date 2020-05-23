extends Timer

func _on_PulseTimer_timeout():
	for mcp in get_tree().get_nodes_in_group("mcp"):
		mcp.on_PulseTimer_timeout()
