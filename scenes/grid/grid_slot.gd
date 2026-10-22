extends TextureRect

class_name GridSlot

@onready var status_filter_rect: ColorRect = $StatusFilter

enum State {
	DEFAULT,
	VALID,
	INVALID
}
var cell: Vector2i = Vector2i.ZERO
var state: State = State.DEFAULT

func update_state_visual(new_state: State) -> void:
	state = new_state
	match new_state:
		State.DEFAULT:
			status_filter_rect.color = Color(Color.WHITE, 0.0)

		State.INVALID:
			status_filter_rect.color = Color(Color.RED, 0.2)

		State.VALID:
			status_filter_rect.color = Color(Color.GREEN, 0.2)
