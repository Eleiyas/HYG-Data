task_module = task_module or {}

function task_module:get_chapter_cfg_by_task_id(task_id)
  return task_module:get_task_cfg_data():GetChapterCfgByTaskId(task_id)
end

function task_module:get_chapter_id_by_task_id(task_id)
  return task_module:get_task_cfg_data():GetChapterIdByTaskId(task_id)
end

function task_module:get_task_step_cfg_by_task_id(task_id)
  return task_module:get_task_cfg_data():GetTaskFirstStepCfgById(task_id)
end

return task_module or {}
