extends Node
class_name InventoryManager

# Inventory manager component.
# Tracks collected items and exposes them to other systems (doors, puzzles).

var items: Dictionary = {}  # item_id -> {item: InventoryItem, count: int}

signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal inventory_changed()

func add_item(item: InventoryItem, amount: int = 1) -> void:
	if not item or amount <= 0:
		return
	var id: String = item.item_id
	if id == "":
		push_warning("InventoryManager: item added without an item_id")
		return
	if items.has(id):
		items[id]["count"] += amount
	else:
		items[id] = {"item": item, "count": amount}
	item_added.emit(id, items[id]["count"])
	inventory_changed.emit()

func remove_item(item_id: String, amount: int = 1) -> bool:
	if not items.has(item_id):
		return false
	items[item_id]["count"] -= amount
	if items[item_id]["count"] <= 0:
		items.erase(item_id)
	item_removed.emit(item_id, amount)
	inventory_changed.emit()
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return items.has(item_id) and items[item_id]["count"] >= amount

func get_item_count(item_id: String) -> int:
	return items[item_id]["count"] if items.has(item_id) else 0

func get_item(item_id: String) -> InventoryItem:
	if not items.has(item_id):
		return null
	return items[item_id].get("item", null) as InventoryItem

func get_all_items() -> Dictionary:
	# Returns a copy so callers cannot mutate the internal state by accident.
	var copy: Dictionary = {}
	for id: String in items.keys():
		var entry: Dictionary = items[id]
		copy[id] = {"item": entry.get("item", null), "count": entry.get("count", 1)}
	return copy

# Flattens the inventory into plain data. Resources cannot be written by
# FileAccess.store_var, so the item metadata is converted to primitives.
func to_save_data() -> Array:
	var data: Array = []
	for id: String in items.keys():
		var entry: Dictionary = items[id]
		var item: InventoryItem = entry.get("item", null) as InventoryItem
		data.append({
			"id": id,
			"count": entry.get("count", 1),
			"name": item.item_name if item else id,
			"description": item.item_description if item else "",
			"is_stackable": item.is_stackable if item else false,
			"max_stack": item.max_stack if item else 1
		})
	return data

# Rebuilds the inventory from the data produced by to_save_data().
func from_save_data(data: Array) -> void:
	items.clear()
	for entry: Dictionary in data:
		var id: String = entry.get("id", "")
		if id == "":
			continue
		var item: InventoryItem = InventoryItem.new()
		item.item_id = id
		item.item_name = entry.get("name", id)
		item.item_description = entry.get("description", "")
		item.is_stackable = entry.get("is_stackable", false)
		item.max_stack = entry.get("max_stack", 1)
		items[id] = {"item": item, "count": entry.get("count", 1)}
	inventory_changed.emit()

func clear() -> void:
	items.clear()
	inventory_changed.emit()
