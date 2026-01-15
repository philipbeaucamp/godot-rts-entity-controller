class_name DisableQueue

static var requests: Dictionary[Node,Array] = {} #Array of requester

static func has_disable_requests(target: Node) -> bool:
	return requests.has(target)

static func add_disable_request(requester: Object, target: Node):
	if !requests.has(target):
		requests.set(target,[])
	if !requests[target].has(requester):
		var do_disable: bool = requests[target].is_empty()
		requests[target].append(requester)
		print("Adding Disable Request for: " + target.name + "(Requester: " + str(requester) + ") Total: " + str(requests[target].size()))
		if do_disable:
			target.call("disable")
			target.tree_exited.connect(on_target_exited_tree.bind(target))
	else:
		assert(false,"adding  twice?")

static func remove_disable_request(requester: Object, target: Node):
	if !requests.has(target):
		return
	if !requests[target].has(requester):
		assert(false,"removing twice?")
		return
	requests[target].erase(requester)
	print("Removed Disable Request for: " + target.name + "(Requester: " + str(requester) + ") Total: " + str(requests[target].size()))
	if requests[target].is_empty():
		target.call("enable")
		requests.erase(target)
		target.tree_exited.disconnect(on_target_exited_tree.bind(target))


static func on_target_exited_tree(target: Node):
	printerr("Disable requests should be removed before target is removed from tree")
