extends Node

signal inventory_changed(inv: Inventory)
signal queue_changed(queue: PaintSelector)
signal selection_changed(idx: int)
signal queue_capacity_changed(old_count: int, new_count: int)