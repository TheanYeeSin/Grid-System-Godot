extends Button

class_name IconButton
signal selected(item: ItemData)
@export var item: ItemData = null
@onready var icon_rect: TextureRect = $Icon

func _ready() -> void:
	if item == null: return
	
	text = item.display_name
	
	if item.sprite != null:
		icon_rect.texture = item.sprite
	else:
		icon_rect.visible = false


func _on_pressed() -> void:
	print("pressed fired, item = ", item)
	if item != null:
		selected.emit(item)
		
func _get_drag_data(at_position: Vector2) -> Variant:
	if item == null:
		return null

	var grab_cell: Vector2i = DragPreviewFactory.center_cell(item)
	var preview: Control = DragPreviewFactory.make(item, Vector2(32, 32), grab_cell)
	set_drag_preview(preview)
	return {
		"item": item,
		"origin_placement_id": -1,
		"grab_offset": grab_cell
	}
