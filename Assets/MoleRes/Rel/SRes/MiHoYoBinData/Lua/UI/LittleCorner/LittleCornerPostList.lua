local M = G.Class("LittleCornerPostList", G.UIPanel)
local base = G.UIPanel
local post_item_cls = "UI/LittleCorner/LittleCornerPostListItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LittleCorner/LittleCornerPostList"
  self._waterfall_scroller = nil
  self._empty_group = nil
  self._posts_inited = false
  self._post_items = {}
  self._item_instance_ids = {}
  self._on_reach_bottom_cb = nil
  self._posts_provider = nil
  self._is_refreshing = false
  self._cached_posts = nil
  self._cached_is_lua_table = false
  self._item_extra = {}
end

function M:on_create()
  base.on_create(self)
  if not_null(self._waterfall_scroller) then
    self._waterfall_scroller:RegisterReachBottomAction(pack(self, M._on_reach_bottom))
  end
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
  if not_null(self._waterfall_scroller) then
    self._waterfall_scroller:UnregisterReachBottomAction()
  end
end

function M:register_events()
  base.register_events(self)
end

function M:set_posts_provider(fn)
  self._posts_provider = fn
end

function M:set_on_reach_bottom(callback)
  self._on_reach_bottom_cb = callback
end

function M:refresh_list()
  if not self._posts_provider then
    return
  end
  if self._is_refreshing then
    return
  end
  self._is_refreshing = true
  local posts, is_lua_table = self._posts_provider()
  local prev_posts = self._cached_posts
  self._cached_posts = posts
  self._cached_is_lua_table = is_lua_table
  if is_null(posts) then
    if not_null(self._empty_group) then
      UIUtil.set_active(self._empty_group, true)
    end
    self._is_refreshing = false
    return
  end
  local post_count
  if is_lua_table then
    post_count = #posts
  else
    post_count = posts.Count
  end
  local source_changed = self._posts_inited and posts ~= prev_posts
  if not self._posts_inited then
    if post_count == 0 then
      if not_null(self._empty_group) then
        UIUtil.set_active(self._empty_group, true)
      end
      self._is_refreshing = false
      return
    end
    self._post_items = {}
    self._item_instance_ids = {}
    self._waterfall_scroller:Init(pack(self, M._refresh_post_item), post_count)
    self._posts_inited = true
  elseif source_changed then
    self._waterfall_scroller:Init(pack(self, M._refresh_post_item), post_count)
  else
    local current_count = self._waterfall_scroller.ItemCount
    if post_count > little_corner_module.max_feed_posts then
      self._waterfall_scroller:ReLoad(pack(self, M._refresh_post_item), post_count)
    elseif post_count > current_count then
      self._waterfall_scroller:AppendItems(post_count)
    elseif post_count == current_count then
      self._waterfall_scroller:RefreshCurrent()
    else
      self._waterfall_scroller:ReLoad(pack(self, M._refresh_post_item), post_count)
    end
  end
  if not_null(self._empty_group) then
    UIUtil.set_active(self._empty_group, post_count == 0)
  end
  self._is_refreshing = false
end

function M:reset()
  if self._posts_inited and not_null(self._waterfall_scroller) then
    self._waterfall_scroller:ReLoad(pack(self, M._refresh_post_item), 0)
  end
  if not_null(self._empty_group) then
    UIUtil.set_active(self._empty_group, true)
  end
end

function M:insert_item_at_top()
  if self._posts_inited and not_null(self._waterfall_scroller) then
    self._waterfall_scroller:InsertItem(0)
  end
end

function M:_on_reach_bottom()
  if self._on_reach_bottom_cb then
    self._on_reach_bottom_cb()
  end
end

function M:_refresh_post_item(trans, index)
  local posts = self._cached_posts
  local is_lua_table = self._cached_is_lua_table
  if is_null(posts) then
    return
  end
  local post_view
  if is_lua_table then
    post_view = posts[index + 1]
  else
    post_view = posts[index]
  end
  if is_null(post_view) then
    return
  end
  local instance_id = trans:GetInstanceID()
  self._item_instance_ids[index] = instance_id
  local cls_obj = self._post_items[instance_id]
  if is_null(cls_obj) then
    cls_obj = self:add_panel(post_item_cls, trans)
    self._post_items[instance_id] = cls_obj
  end
  self._item_extra.post_view = post_view
  cls_obj:set_extra_data(self._item_extra)
  cls_obj:force_refresh()
end

return M
