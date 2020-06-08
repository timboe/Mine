extends Control

onready var building_manager : BuildingManager = $"../BuildingManager"

func _on_Generator_toggled(button_pressed):
	print("gen ", button_pressed)
	building_manager.show_blueprint(0, BuildingManager.Type.GEN)


func _on_Vat_toggled(button_pressed):
	print("vat ", button_pressed)
	building_manager.show_blueprint(0, BuildingManager.Type.VAT)

func _on_Barrier_toggled(button_pressed):
	print("bar ", button_pressed)
	building_manager.show_blueprint(0, BuildingManager.Type.BAR)
