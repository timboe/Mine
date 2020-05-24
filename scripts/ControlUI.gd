extends Control

onready var building_manager : BuildingManager = $"../BuildingManager"

func _on_Gen_gui_input(event):
	if not event is InputEventMouseButton or not event.is_pressed() or not event.button_index == BUTTON_LEFT:
		return
	building_manager.show_blueprint(0, BuildingManager.Type.GEN)


func _on_Vat_gui_input(event):
	if not event is InputEventMouseButton or not event.is_pressed() or not event.button_index == BUTTON_LEFT:
		return
	building_manager.show_blueprint(0, BuildingManager.Type.VAT)
