extends Control

class_name PlacedItem

signal picked_up(placement_id: int)

var item: ItemData
var anchor: Vector2i
var placement_id: int = -1
var cell_size: Vector2 = Vector2(32, 32)
var grid: Grid = null

@onready var icon_rect: TextureRect = $Icon

func setup(p_item: ItemData, p_anchor: Vector2i, p_cell_size: Vector2) -> void:
	item = p_item
	anchor = p_anchor
	cell_size = p_cell_size

	var max_x: int = 0
	var max_y: int = 0
	for cell in item.shape:
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)

	position = Vector2(anchor) * cell_size
	size = Vector2(max_x + 1, max_y + 1) * cell_size

	if item.sprite:
		icon_rect.texture = item.sprite

	modulate = item.color

func _get_drag_data(at_position: Vector2) -> Variant:
	var grab_offset: Vector2i = Vector2i(
		floori(at_position.x / cell_size.x),
		floori(at_position.y / cell_size.y)
	)
	var preview: Control = DragPreviewFactory.make(item, cell_size, grab_offset)
	set_drag_preview(preview)

	hide()
	picked_up.emit(placement_id)

	return {
		"item": item,
		"origin_placement_id": placement_id,
		"grab_offset": grab_offset,
	}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if not get_viewport().gui_is_drag_successful():
			show()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if grid == null:
		return false
	return grid.can_drop_item(data, get_global_transform() * at_position)

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if grid != null:
		grid.drop_item(data, get_global_transform() * at_position)
