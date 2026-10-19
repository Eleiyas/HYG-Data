local M = G.Class("RabbitTabletopEmojiItem", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn, function()
    if self._data then
      local cfg = ExcelDataUtil.get_value(typeof(BReactionCfg), self._data.id)
      if cfg then
        local atl_tag = cfg.hostatltagname
        if string.is_valid(atl_tag) then
          Logger.Log("[RabbitTabletopMainPage] broadcast settle animation, atl_tag=" .. atl_tag)
          EventCenter.Broadcast(EventID.TabletopSettleAnimation, atl_tag)
        end
      end
    end
  end)
end

function M:refresh(data)
  if is_null(data) then
    return
  end
  self._data = data
  local cfg = ExcelDataUtil.get_value(typeof(BReactionCfg), data.id)
  if cfg then
    UIUtil.set_image(self._img, cfg.iconpath, self:get_load_proxy())
    UIUtil.set_text(self._txt_name, cfg.name)
  end
end

return M
