task_module = task_module or {}
task_module.chapter_type = {
  main = 1,
  npc = 2,
  random = 3,
  time_book = 4
}
task_module.task_item_cls_name = "UI/Task/TaskItem"
task_module.task_page_show_type_ongoing = -1
task_module.task_page_show_type_main = task_module.chapter_type.main
task_module.task_page_show_type_npc = task_module.chapter_type.npc
task_module.task_page_sort_show_type = {
  task_module.task_page_show_type_ongoing
}
task_module.task_page_sort_str = {
  [task_module.task_page_show_type_ongoing] = "TaskBoard_TaskTab_Ongoing",
  [task_module.task_page_show_type_main] = "TaskBoard_TaskTab_Main",
  [task_module.task_page_show_type_npc] = "TaskBoard_TaskTab_NPC"
}
return task_module or {}
