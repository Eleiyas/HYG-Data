local M = G.Class("PerformanceBubbleHintScene", "UI/OverheadHint/BubbleHintScene")
local base = G.BubbleHintScene

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/OverheadHint/PerformanceBubbleHintScene"
  self.config.type = EUIType.Scene
  self._hint_order = overhead_hint_module.overhead_hint_order.performance_bubble
  self._ui_max_distance = 10000
end

function M:_is_entity_ready_for_bubble(guid)
  return true
end

function M:_add_bubble_hint_item(bubble_data)
  base._add_bubble_hint_item(self, bubble_data)
  if bubble_data ~= nil and EntityUtil.is_valid(bubble_data.guid) then
    CsOverheadHintManagerUtil.ShowOverheadHint(bubble_data.guid)
  end
end

return M
