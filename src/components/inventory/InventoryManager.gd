extends Node
class_name InventoryManager

# Inventory manager autoload component.
# Tracks collected items and exposes them to other systems (doors, puzzles).

var items: Dictionary = {}  # item_id -> {item: InventoryItem, count: int}

signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal inventory_changed()

func add_item(item: InventoryItem, amount: int = 1) -> void:
	if not item:
		return
	var id: String = item.item_id
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

func get_all_items() -> Dictionary:
	return items.duplicate()

func clear() -> void:
	items.clear()
	inventory_changed.emit()
