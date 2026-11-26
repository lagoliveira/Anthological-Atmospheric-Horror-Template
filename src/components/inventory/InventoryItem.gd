extends Resource
class_name InventoryItem

# Data resource representing an item in the player's inventory.

@export var item_id: String = ""
@export var item_name: String = "Item"
@export var item_description: String = ""
@export var item_icon: Texture2D
@export var is_stackable: bool = false
@export var max_stack: int = 1
