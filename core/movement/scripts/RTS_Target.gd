class_name RTS_Target

# A target point for RTS_Movable entities to move to or interact with.

var pos: Vector3
var type : RTS_Movable.Type
var source: RTS_Entity #null or RTS_Entity
var group_id: int #-1 or duplicate ints in selection will not get drawn a path
var offset: Vector3 #offset to original target before formation offset was applied
var callbacks: Dictionary #Dictionary[callback_id,{fun: Callable, args: Array}]
var owner: Object #who created this target. if player leave empty ?
var display: bool = true

var previous: RTS_Target #pointing to previous target in double linked list
var next: RTS_Target #pointing to next target in double linked list

func _init(_pos: Vector3, _type: RTS_Movable.Type,_source: RTS_Entity, _group_id:int = -1, _offset: Vector3 = Vector3.ZERO, _callbacks: Dictionary = {}, _owner: Object = null):
	pos = _pos
	type = _type
	source = _source
	group_id = _group_id
	offset = _offset
	callbacks = _callbacks
	owner = _owner
