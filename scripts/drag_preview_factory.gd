class_name DragPreviewFactory extends RefCounted

static func make(item: ItemData, cell_size: Vector2, grab_cell: Vector2i = Vector2i.ZERO) -> Control:
	var shape: Control = _make_shape(item, cell_size)
	shape.position = -(Vector2(grab_cell) + Vector2(0.5, 0.5)) * cell_size

	var preview: Control = Control.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(shape)

	return preview

static func center_cell(item: ItemData) -> Vector2i:
	return (_cell_bounds(item) - Vector2i.ONE) / 2

static func _cell_bounds(item: ItemData) -> Vector2i:
	var max_cell: Vector2i = Vector2i.ZERO

	for cell in item.shape:
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)

	return max_cell + Vector2i.ONE

static func _make_shape(item: ItemData, cell_size: Vector2) -> Control:
	var container: Control = Control.new()
	container.size = Vector2(_cell_bounds(item)) * cell_size
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.modulate.a = 0.75

	for cell in item.shape:
		var rect: ColorRect = ColorRect.new()
		rect.color = item.color
		rect.size = cell_size
		rect.position = Vector2(cell.x, cell.y) * cell_size
		container.add_child(rect)

	if item.sprite != null:
		var icon: TextureRect = TextureRect.new()
		icon.texture = item.sprite
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = container.size
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(icon)

	return container
