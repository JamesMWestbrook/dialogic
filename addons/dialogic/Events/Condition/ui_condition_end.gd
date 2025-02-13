@tool
extends HBoxContainer

var parent_resource = null

func _ready():
	$AddElif.button_up.connect(add_elif)
	$AddElse.button_up.connect(add_else)

func refresh():
	if parent_resource is DialogicConditionEvent:
		# hide add elif and add else button on ELSE event
		$AddElif.visible = parent_resource.condition_type != DialogicConditionEvent.ConditionTypes.Else
		$AddElse.visible = parent_resource.condition_type != DialogicConditionEvent.ConditionTypes.Else
		$Label.text = "End of "+["IF", "ELIF", "ELSE"][parent_resource.condition_type]+" ("+parent_resource.condition+")"
		
		# hide add add else button if followed by ELIF or ELSE event
		var timeline_editor = find_parent('TimelineVisualEditor')
		if timeline_editor:
			var next_event = null
			if timeline_editor.get_block_below(get_parent()):
				next_event = timeline_editor.get_block_below(get_parent()).resource
				if next_event is DialogicConditionEvent:
					if next_event.condition_type != DialogicConditionEvent.ConditionTypes.If:
						$AddElse.hide()
		if parent_resource.condition_type == DialogicConditionEvent.ConditionTypes.Else:
			$Label.text = "End of ELSE"
	else:
		hide()

func add_elif():
	var timeline = find_parent('TimelineVisualEditor')
	if timeline:
		var resource = DialogicConditionEvent.new()
		resource.condition_type = DialogicConditionEvent.ConditionTypes.Elif
		timeline.add_event_with_end_branch(resource, get_parent().get_index()+1)
		timeline.indent_events()

func add_else():
	var timeline = find_parent('TimelineVisualEditor')
	if timeline:
		var resource = DialogicConditionEvent.new()
		resource.condition_type = DialogicConditionEvent.ConditionTypes.Else
		timeline.add_event_with_end_branch(resource, get_parent().get_index()+1)
		timeline.indent_events()
