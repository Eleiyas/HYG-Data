world_editor_module = world_editor_module or {}
world_editor_module.edit_type = {
  none = 0,
  entity = 1,
  road = 2,
  mountain = 3,
  river = 4
}
world_editor_module.edit_entity_source = {
  scene = 0,
  limbo = 1,
  inventory = 2
}
world_editor_module.map_mode = {normal = 0, world_editor = 1}
world_editor_module.test_camera_speed = 100
return world_editor_module or {}
