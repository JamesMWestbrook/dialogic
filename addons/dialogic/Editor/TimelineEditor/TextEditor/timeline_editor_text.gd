@tool
extends CodeEdit

## Sub-Editor that allows editing timelines in a text format.

 
func _ready():
	syntax_highlighter = load("res://addons/dialogic/Editor/TimelineEditor/TextEditor/syntax_highlighter.gd").new()


func _on_text_editor_text_changed():
	get_parent().current_resource_state = DialogicEditor.ResourceStates.Unsaved


func _gui_input(event):
	if not event is InputEventKey: return
	if not event.is_pressed(): return
	match event.as_text():
		"Ctrl+K":
			toggle_comment()
		"Alt+Up":
			move_line(-1)
		"Alt+Down":
			move_line(1)
		_:
			return
	get_viewport().set_input_as_handled()
	

func clear_timeline():
	text = ''


func load_timeline(object:DialogicTimeline) -> void:
	clear_timeline()
	if get_parent().current_resource.events.size() == 0:
		pass
	else: 
		if typeof(get_parent().current_resource.events[0]) == TYPE_STRING:
			get_parent().current_resource.events_processed = false
			get_parent().current_resource = get_parent().editors_manager.resource_helper.process_timeline(get_parent().current_resource)
	
	
	#text = TimelineUtil.events_to_text(object.events)
	var result:String = ""	
	var indent := 0
	for idx in range(0, len(object.events)):
		var event = object.events[idx]
		
		if event['event_name'] == 'End Branch':
			indent -= 1
			continue
		
		if event != null:
			for i in event.empty_lines_above:
				result += "\t".repeat(indent)+"\n"
			result += "\t".repeat(indent)+event['event_node_as_text'].replace('\n', "\n"+"\t".repeat(indent)) + "\n"
		if event.can_contain_events:
			indent += 1
		if indent < 0: 
			indent = 0
		
	text = result
	get_parent().current_resource.set_meta("timeline_not_saved", false)


func save_timeline():
	if get_parent().current_resource:
		var text_array:Array = text_timeline_to_array(text)
		
		get_parent().current_resource.events = text_array
		get_parent().current_resource.events_processed = false
		ResourceSaver.save(get_parent().current_resource, get_parent().current_resource.resource_path)

		get_parent().current_resource.set_meta("timeline_not_saved", false)
		get_parent().current_resource_state = DialogicEditor.ResourceStates.Saved
		get_parent().editors_manager.resource_helper.rebuild_timeline_directory()


func text_timeline_to_array(text:String) -> Array:
	# Parse the lines down into an array
	var events := []
	
	var lines := text.split('\n', true)
	var idx := -1
	
	while idx < len(lines)-1:
		idx += 1
		var line :String = lines[idx]
		var line_stripped :String = line.strip_edges(true, true)
		events.append(line)
	
	return events


# Toggle the selected lines as comments
func toggle_comment() -> void:
	var cursor: Vector2 = Vector2(get_caret_column(), get_caret_line())
	var from: int = cursor.y
	var to: int = cursor.y
	if has_selection():
		from = get_selection_from_line()
		to = get_selection_to_line()

	var lines: PackedStringArray = text.split("\n")
	var will_comment: bool = not lines[from].begins_with("# ")
	for i in range(from, to + 1):
		lines[i] = "# " + lines[i] if will_comment else lines[i].substr(2)

	text = "\n".join(lines)
	select(from, 0, to, get_line_width(to))
	set_caret_line(cursor.y)
	set_caret_column(cursor.x)
	text_changed.emit()


# Move the selected lines up or down
func move_line(offset: int) -> void:
	offset = clamp(offset, -1, 1)

	var cursor: Vector2 = Vector2(get_caret_column(), get_caret_line())
	var reselect: bool = false
	var from: int = cursor.y
	var to: int = cursor.y
	if has_selection():
		reselect = true
		from = get_selection_from_line()
		to = get_selection_to_line()

	var lines := text.split("\n")

	if from + offset < 0 or to + offset >= lines.size(): return

	var target_from_index: int = from - 1 if offset == -1 else to + 1
	var target_to_index: int = to if offset == -1 else from
	var line_to_move: String = lines[target_from_index]
	lines.remove_at(target_from_index)
	lines.insert(target_to_index, line_to_move)

	text = "\n".join(lines)

	cursor.y += offset
	from += offset
	to += offset
	if reselect:
		select(from, 0, to, get_line_width(to))
	set_caret_line(cursor.y)
	set_caret_column(cursor.x)
	text_changed.emit()
