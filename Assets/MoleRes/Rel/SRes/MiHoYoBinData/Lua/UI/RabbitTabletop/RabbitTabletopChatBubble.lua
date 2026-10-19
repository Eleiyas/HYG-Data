local M = G.Class("RabbitTabletopChatBubble", G.UIBase)
local base = G.UIBase
local chat_show_time = 8
local chat_max_num = 3

function M:on_create()
  base.on_create(self)
  local show_time_cfg = ExcelDataUtil.get_value(typeof(BPlayerCfg), 75)
  if show_time_cfg then
    chat_show_time = show_time_cfg.value
  end
  self._emoji_pool = {
    active = {},
    cache = {}
  }
  self._message_pool = {
    active = {},
    cache = {}
  }
end

function M:init_pools(emoji_template, msg_template)
  self._emoji_template = emoji_template
  self._msg_template = msg_template
end

function M:add_chat(chat_data)
  if not self._emoji_template or not self._msg_template then
    return
  end
  self:_trim_oldest()
  local is_emoji = chat_module:chat_is_emoji(chat_data)
  local item = self:_get_or_create(is_emoji)
  if not item then
    return
  end
  if is_emoji then
    if item.img_icon then
      chat_module:set_chat_emoji(item.img_icon, chat_data.content, self:get_load_proxy())
    end
  elseif item.txt_msg then
    UIUtil.set_text(item.txt_msg, chat_data.content or "")
  end
end

function M:update_time(dt)
  self:_update_pool(self._emoji_pool, dt)
  self:_update_pool(self._message_pool, dt)
end

function M:clear()
  self:_recycle_all(self._emoji_pool)
  self:_recycle_all(self._message_pool)
end

function M:on_disable()
  self:clear()
  base.on_disable(self)
end

function M:_active_count()
  return #self._emoji_pool.active + #self._message_pool.active
end

function M:_trim_oldest()
  while self:_active_count() >= chat_max_num do
    local emoji_first = self._emoji_pool.active[1]
    local msg_first = self._message_pool.active[1]
    if emoji_first and (not msg_first or emoji_first.show_time <= msg_first.show_time) then
      self:_recycle_item(self._emoji_pool, 1)
    elseif msg_first then
      self:_recycle_item(self._message_pool, 1)
    else
      break
    end
  end
end

function M:_get_or_create(is_emoji)
  local pool = is_emoji and self._emoji_pool or self._message_pool
  local template = is_emoji and self._emoji_template or self._msg_template
  local item
  if #pool.cache > 0 then
    item = table.remove(pool.cache)
  else
    local go = UIUtil.load_prefab_set_parent(template.gameObject, self.trans)
    if is_null(go) then
      return nil
    end
    item = {
      go = go,
      trans = go.transform
    }
    if is_emoji then
      item.img_icon = UIUtil.find_image(go.transform, "img_icon")
    else
      item.txt_msg = UIUtil.find_text(go.transform, "txt_msg")
    end
  end
  UIUtil.set_active(item.go, true)
  item.trans:SetAsLastSibling()
  table.insert(pool.active, {item = item, show_time = chat_show_time})
  return item
end

function M:_update_pool(pool, dt)
  local i = 1
  while i <= #pool.active do
    local entry = pool.active[i]
    entry.show_time = entry.show_time - dt
    if entry.show_time <= 0 then
      self:_recycle_item(pool, i)
    else
      i = i + 1
    end
  end
end

function M:_recycle_item(pool, index)
  local entry = table.remove(pool.active, index)
  if entry and entry.item then
    UIUtil.set_active(entry.item.go, false)
    table.insert(pool.cache, entry.item)
  end
end

function M:_recycle_all(pool)
  while #pool.active > 0 do
    self:_recycle_item(pool, 1)
  end
end

return M
