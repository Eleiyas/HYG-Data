local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local M = G.Class("StorySection", base_path)
local base = G.DetailSectionBase

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_story, pack(self, M._on_btn_story))
  if not_null(self._trans_story_popup) then
    self._popup = self:add_panel("UI/Codex/DetailPage/V2/Sections/StoryPopupPanel", self._trans_story_popup)
    self._popup:hide()
  end
end

function M:should_show(item_data)
  if not codex_module:is_package_sub_type(item_data.SubType) then
    return false
  end
  local story_text = item_data.ItemCfg and item_data.ItemCfg.itemdescribe
  return story_text and story_text ~= ""
end

function M:refresh(item_data)
  UIUtil.set_text_by_id(self._txt_option, "Codex_SpecialDescribeButton")
  self._item_data = item_data
  if self._popup then
    self._popup:hide()
  end
end

function M:_on_btn_story()
  if self._popup and self._popup:is_showing() then
    self:close_popup()
    return
  end
  local story_text = self._item_data.ItemCfg.itemdescribe or ""
  if self._popup then
    self._popup:show(story_text)
    if self._popup_visibility_cb then
      self._popup_visibility_cb(true)
    end
  end
end

function M:close_popup()
  if self._popup and self._popup:is_showing() then
    self._popup:hide()
    if self._popup_visibility_cb then
      self._popup_visibility_cb(false)
    end
    return true
  end
  return false
end

return M
