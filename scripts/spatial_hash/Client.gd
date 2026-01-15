class_name Client

var position: Vector2
var dimensions: Vector2
var group: int #arbitrary int to filter clients
var _cells = {
	"min": null, #index, int
	"max": null, # index, int
	"nodes": null, # covered nodes, Array[Array[HashNode]] (rows/columns)
}
var query_id: int = -1
