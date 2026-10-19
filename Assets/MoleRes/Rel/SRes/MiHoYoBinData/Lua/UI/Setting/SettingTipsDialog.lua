local M = G.Class("SettingTipsDialog", G.UIWindow)
local base = G.UIWindow
local TIPS_STATE_ABOVE = 0
local TIPS_STATE_BELOW = 1

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Setting/SettingTipsDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_closearea, pack(self, M._on_btn_close_click))
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_view()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, M._on_back)
end

function M:_on_back(action)
  self:_on_btn_close_click()
end

function M:_on_btn_close_click()
  self:close_self()
end

function M:_refresh_view()
  local extra_data = self:get_extra_data()
  if extra_data == nil or extra_data.detail_data == nil or extra_data.target_trans == nil or is_null(extra_data.target_trans) then
    Logger.LogWarning("[SettingTipsDialog] Invalid extra data.")
    self:close_self()
    return
  end
  local detail_data = extra_data.detail_data
  local title
  if detail_data.useEntryTitle then
    title = self:_get_text_map_content_text(extra_data.fallback_title)
  else
    title = self:_get_text_map_content_text(detail_data.titleTextMapContent)
    if not string.is_valid(title) then
      title = self:_get_text_map_content_text(extra_data.fallback_title)
    end
  end
  local content = self:_get_text_map_content_text(detail_data.contentTextMapContent)
  UIUtil.set_text(self._txt_title, title or "")
  UIUtil.set_text(self._txt_info, content or "")
  self:_refresh_anchor(extra_data.target_trans)
end

function M:_refresh_anchor(target_trans)
  local position = CsUIUtil.CalculateCanvasLocalPosition(target_trans, UIManagerInstance.canvas_rect, 0.5, 0.5)
  if self._state_group == nil or is_null(self._state_group) or self._trans_position_root == nil or is_null(self._trans_position_root) then
    Logger.LogWarning("[SettingTipsDialog] Anchor components not found.")
    self:close_self()
    return
  end
  local state = position.y < 0 and TIPS_STATE_BELOW or TIPS_STATE_ABOVE
  self._state_group:SetState(state)
  self._trans_position_root:SetAnchoredPos(position.x, position.y)
end

function M:_get_text_map_content_text(text_map_content)
  if text_map_content == nil then
    return ""
  end
  if text_map_content.textId ~= nil and string.is_valid(text_map_content.textId) then
    return UIUtil.get_text_by_id(text_map_content.textId)
  end
  if text_map_content.ToStringExplicit ~= nil then
    return text_map_content:ToStringExplicit()
  end
  return ""
end

return M
