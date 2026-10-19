local M = G.Class("LittleTheaterHintScene", "UI/OverheadHint/HintSceneBase")
local base = G.HintSceneBase

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/OverheadHint/LittleTheaterHintScene"
  self.config.type = EUIType.Scene
  self.hint_order = overhead_hint_module.overhead_hint_order.small_theater
  self.hint_item_cls_name = "UI/OverheadHint/InCutsceneHintItem"
  self._hide_guids = {}
  self._is_hide_close_listener = false
end

function M:update(deltaTime)
  base.update(self, deltaTime)
end

return M
