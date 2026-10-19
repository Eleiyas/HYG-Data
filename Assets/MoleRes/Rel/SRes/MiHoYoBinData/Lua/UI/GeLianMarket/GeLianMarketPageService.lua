local M = G.Class("GeLianMarketPageService", "UIFramework/UIPageService")
local base = G.UIPageService
M.Port = {
  LeftArea = 1,
  RightArea = 2,
  MainPage = 3
}
M.PortMethods = {
  [M.Port.LeftArea] = {
    "show_buttons",
    "enter_sell",
    "leave_sell",
    "refresh",
    "refresh_sell_bar"
  },
  [M.Port.RightArea] = {
    "show_market_overview",
    "show_prediction",
    "enter_sell",
    "show_friend_price",
    "show_return_rank",
    "show_leave_message",
    "refresh"
  }
}
M.Mode = {
  MarketOverview = 1,
  Prediction = 2,
  Selling = 3,
  FriendPrice = 4,
  ReturnRank = 5,
  LeaveMessage = 6
}
local mode_right_area_rollback = {
  [M.Mode.MarketOverview] = "show_market_overview",
  [M.Mode.Prediction] = "show_prediction",
  [M.Mode.FriendPrice] = "show_friend_price",
  [M.Mode.ReturnRank] = "show_return_rank",
  [M.Mode.LeaveMessage] = "show_leave_message"
}

function M:__ctor()
  self._mode = M.Mode.MarketOverview
  self._request_id = 0
  self:define_port(M.Port.LeftArea, M.PortMethods[M.Port.LeftArea])
  self:define_port(M.Port.RightArea, M.PortMethods[M.Port.RightArea])
end

function M:get_mode()
  return self._mode
end

function M:enter_market_overview(payload, complete)
  local request_id = self:_begin_request()
  local left_area, right_area = self:_require_areas(complete)
  if left_area == nil then
    return
  end
  left_area.show_buttons(true)
  right_area.show_market_overview(payload)
  self:_complete_mode(request_id, M.Mode.MarketOverview, complete)
end

function M:enter_prediction(payload, complete)
  local request_id = self:_begin_request()
  local left_area, right_area = self:_require_areas(complete)
  if left_area == nil then
    return
  end
  left_area.show_buttons(true)
  right_area.show_prediction(payload)
  self:_complete_mode(request_id, M.Mode.Prediction, complete)
end

function M:enter_sell(payload, complete)
  local request_id = self:_begin_request()
  local main_page = self:require_port(M.Port.MainPage)
  if main_page ~= nil then
    main_page.set_state_group_sale()
  end
  local left_area, right_area = self:_require_areas(complete)
  if left_area == nil then
    return
  end
  local previous_mode = self._mode
  right_area.enter_sell(payload)
  left_area.enter_sell(payload, function(success)
    if not self:_is_request_active(request_id) then
      if complete ~= nil then
        complete(false)
      end
      return
    end
    if success == false then
      self:_rollback_right_area(previous_mode)
      if complete ~= nil then
        complete(false)
      end
      return
    end
    self:_complete_mode(request_id, M.Mode.Selling, complete)
  end)
end

function M:enter_friend_price(payload, complete)
  self:_enter_social_mode(M.Mode.FriendPrice, "show_friend_price", payload, complete)
end

function M:enter_return_rank(payload, complete)
  self:_enter_social_mode(M.Mode.ReturnRank, "show_return_rank", payload, complete)
end

function M:enter_leave_message(payload, complete)
  self:_enter_social_mode(M.Mode.LeaveMessage, "show_leave_message", payload, complete)
end

function M:refresh(snapshot)
  local left_area = self:get_port(M.Port.LeftArea)
  local right_area = self:get_port(M.Port.RightArea)
  if left_area ~= nil then
    left_area.refresh(snapshot)
  end
  if right_area ~= nil then
    right_area.refresh(snapshot)
  end
end

function M:_enter_social_mode(mode, method_name, payload, complete)
  local request_id = self:_begin_request()
  local left_area, right_area = self:_require_areas(complete)
  if left_area == nil then
    return
  end
  left_area.show_buttons(false)
  right_area[method_name](payload)
  self:_complete_mode(request_id, mode, complete)
end

function M:_require_areas(complete)
  local left_area = self:require_port(M.Port.LeftArea)
  local right_area = self:require_port(M.Port.RightArea)
  if left_area == nil or right_area == nil then
    if complete ~= nil then
      complete(false)
    end
    return nil, nil
  end
  return left_area, right_area
end

function M:cancel_pending_requests()
  self:_next_request_id()
end

function M:_rollback_right_area(previous_mode)
  local method_name = mode_right_area_rollback[previous_mode]
  if method_name == nil then
    return
  end
  local right_area = self:get_port(M.Port.RightArea)
  if right_area ~= nil then
    right_area[method_name]()
  end
end

function M:_begin_request()
  local request_id = self:_next_request_id()
  local left_area = self:get_port(M.Port.LeftArea)
  if left_area ~= nil then
    left_area.leave_sell()
  end
  return request_id
end

function M:_next_request_id()
  self._request_id = self._request_id + 1
  return self._request_id
end

function M:_is_request_active(request_id)
  return not self._is_disposed and self._request_id == request_id
end

function M:_complete_mode(request_id, mode, complete)
  if not self:_is_request_active(request_id) then
    if complete ~= nil then
      complete(false)
    end
    return
  end
  self._mode = mode
  if complete ~= nil then
    complete(true)
  end
end

return M
