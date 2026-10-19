local M = G.Class("RabbitTabletopOrderAvatar", G.UIBase)
local base = G.UIBase

function M:on_create()
  base.on_create(self)
end

function M:refresh(data)
  if not data then
    return
  end
  self._state_state:SetState(data.state or 0)
  self._state_name:SetState(data.name_state or 0)
  if data.avatar_id and 0 < data.avatar_id then
    local head_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), data.avatar_id)
    if head_cfg then
      UIUtil.set_image(self._img_head, head_cfg.respath, self:get_load_proxy())
    end
  end
end

return M
