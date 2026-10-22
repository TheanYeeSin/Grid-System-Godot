extends Control

class_name Grid

const TOTAL_COLUMN_COUNT: int = 7
const TOTAL_ROW_COUNT: int = 5

@onready var slot_scene: PackedScene = preload("res://scenes/grid/grid_slot.tscn")
@onready var placed_item_scene: PackedScene = preload("res://scenes/grid/placed_item.tscn")
@onready var grid_container: GridContainer = $GridContainer
@onready var items_layer: Control = $ItemsLayer

var slots: Array[GridSlot] = []
var occupancy: Array = []
var placements: Dictionary = {}
var next_placement_id: int = 0
var cell_size: Vector2 = Vector2(32, 32)  # matches the 32x32 slot texture

var _highlighted_cells: Array[Vector2i] = []

func _ready() -> void:
	grid_container.columns = TOTAL_COLUMN_COUNT
	grid_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	items_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	mouse_filter = Control.MOUSE_FILTER_STOP
	var grid_area := Vector2(TOTAL_COLUMN_COUNT, TOTAL_ROW_COUNT) * cell_size
	custom_minimum_size = grid_area
	size = grid_area

	for y in TOTAL_ROW_COUNT:
		var row: Array = []
		for x in TOTAL_COLUMN_COUNT:
			row.append(-1)
		occupancy.append(row)

	for i in range(TOTAL_COLUMN_COUNT * TOTAL_ROW_COUNT):
		create_grid(i)

	mouse_exited.connect(clear_highlights)

func create_grid(i: int) -> void:
	var new_slot = slot_scene.instantiate()
	new_slot.cell = Vector2i(i % TOTAL_COLUMN_COUNT, i / TOTAL_COLUMN_COUNT)
	new_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slots.append(new_slot)
	grid_container.add_child(new_slot)

func get_slot(cell: Vector2i) -> GridSlot:
	if cell.x < 0 or cell.y < 0 or cell.x >= TOTAL_COLUMN_COUNT or cell.y >= TOTAL_ROW_COUNT:
		return null
	return slots[cell.x + cell.y * TOTAL_COLUMN_COUNT]

func get_cell_at_global_position(global_pos: Vector2) -> Vector2i:
	for slot in slots:
		if slot.get_global_rect().has_point(global_pos):
			return slot.cell
	return Vector2i(-1, -1)

func _shape_cells(item: ItemData, anchor: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in item.shape:
		cells.append(anchor + offset)

	print(cells)
	return cells

func can_place(item: ItemData, anchor: Vector2i, ignore_placement_id: int = -1) -> bool:
	for cell in _shape_cells(item, anchor):
		if cell.x < 0 or cell.y < 0 or cell.x >= TOTAL_COLUMN_COUNT or cell.y >= TOTAL_ROW_COUNT:
			return false
		var occupant = occupancy[cell.y][cell.x]
		if occupant != -1 and occupant != ignore_placement_id:
			return false
	return true

func place_item(item: ItemData, anchor: Vector2i) -> int:
	var id: int = next_placement_id
	next_placement_id += 1

	for cell in _shape_cells(item, anchor):
		occupancy[cell.y][cell.x] = id

	var node: PlacedItem = placed_item_scene.instantiate()
	items_layer.add_child(node)
	node.setup(item, anchor, cell_size)
	node.placement_id = id
	node.grid = self
	node.picked_up.connect(_on_placed_item_picked_up)

	placements[id] = {"item": item, "anchor": anchor, "node": node}
	return id

func remove_placement(id: int) -> void:
	if not placements.has(id):
		return
	var data = placements[id]
	for cell in _shape_cells(data["item"], data["anchor"]):
		occupancy[cell.y][cell.x] = -1
	data["node"].queue_free()
	placements.erase(id)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return can_drop_item(data, get_global_transform() * at_position)

func _drop_data(at_position: Vector2, data: Variant) -> void:
	drop_item(data, get_global_transform() * at_position)

func can_drop_item(data: Variant, global_point: Vector2) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("item"):
		clear_highlights()
		return false

	var item: ItemData = data["item"]
	var grab_offset: Vector2i = data.get("grab_offset", Vector2i.ZERO)
	var mouse_cell := get_cell_at_global_position(global_point)

	if mouse_cell == Vector2i(-1, -1):
		clear_highlights()
		return false

	var anchor: Vector2i = mouse_cell - grab_offset
	var ignore_id: int = data.get("origin_placement_id", -1)

	var valid: bool = can_place(item, anchor, ignore_id)
	_highlight_shape(item, anchor, valid)
	return valid

func drop_item(data: Variant, global_point: Vector2) -> void:
	if typeof(data) != TYPE_DICTIONARY or not data.has("item"):
		return

	var item: ItemData = data["item"]
	var grab_offset: Vector2i = data.get("grab_offset", Vector2i.ZERO)
	var mouse_cell := get_cell_at_global_position(global_point)
	var origin_id: int = data.get("origin_placement_id", -1)

	if mouse_cell == Vector2i(-1, -1):
		return

	var anchor: Vector2i = mouse_cell - grab_offset

	if not can_place(item, anchor, origin_id):
		clear_highlights()
		return

	if origin_id != -1:
		remove_placement(origin_id)

	place_item(item, anchor)
	clear_highlights()

func _highlight_shape(item: ItemData, anchor: Vector2i, valid: bool) -> void:
	clear_highlights()
	var state = GridSlot.State.VALID if valid else GridSlot.State.INVALID
	for offset in item.shape:
		var cell: Vector2i = anchor + offset
		var slot: GridSlot = get_slot(cell)
		if slot:
			slot.update_state_visual(state)
			_highlighted_cells.append(cell)

func _on_placed_item_picked_up(_id: int) -> void:
	pass

func clear_highlights() -> void:
	for cell in _highlighted_cells:
		var slot: GridSlot = get_slot(cell)
		if slot:
			slot.update_state_visual(GridSlot.State.DEFAULT)
	_highlighted_cells.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		clear_highlights()
