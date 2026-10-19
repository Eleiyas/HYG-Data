local M = G.Class("UIPageService")

local function report_error(message)
  pcall(Logger.LogError, message)
end

function M:__ctor()
  self._contracts = {}
  self._ports = {}
  self._is_disposed = false
end

function M:define_port(port_id, method_names)
  if not (not self._is_disposed and self:_is_valid_port_id(port_id)) or type(method_names) ~= "table" then
    report_error("[UIPageService] invalid port contract, port=" .. tostring(port_id))
    return false
  end
  if self._contracts[port_id] ~= nil then
    report_error("[UIPageService] duplicate port contract, port=" .. port_id)
    return false
  end
  local contract = {}
  for i = 1, #method_names do
    local method_name = method_names[i]
    if type(method_name) ~= "string" or #method_name == 0 then
      report_error("[UIPageService] invalid method name, port=" .. port_id)
      return false
    end
    contract[#contract + 1] = method_name
  end
  self._contracts[port_id] = contract
  return true
end

function M:provide(port_id, owner, api)
  if not self:_is_valid_port_id(port_id) then
    report_error("[UIPageService] invalid port id, port=" .. tostring(port_id))
    return false
  end
  if self._is_disposed or owner == nil or type(api) ~= "table" then
    report_error("[UIPageService] invalid provider, port=" .. tostring(port_id))
    return false
  end
  if self._ports[port_id] ~= nil then
    report_error("[UIPageService] duplicate provider, port=" .. tostring(port_id))
    return false
  end
  local contract = self._contracts[port_id]
  if contract == nil then
    report_error("[UIPageService] undefined port, port=" .. tostring(port_id))
    return false
  end
  for i = 1, #contract do
    local method_name = contract[i]
    if type(api[method_name]) ~= "function" then
      report_error("[UIPageService] missing method, port=" .. port_id .. ", method=" .. method_name)
      return false
    end
  end
  self._ports[port_id] = {owner = owner, api = api}
  return true
end

function M:withdraw_owner(owner)
  if owner == nil then
    return
  end
  for port_id, entry in pairs(self._ports) do
    if entry.owner == owner then
      self._ports[port_id] = nil
    end
  end
end

function M:get_port(port_id)
  local entry = self._ports[port_id]
  if entry == nil then
    return nil
  end
  return entry.api
end

function M:require_port(port_id)
  local api = self:get_port(port_id)
  if api == nil then
    report_error("[UIPageService] required port unavailable, port=" .. tostring(port_id))
  end
  return api
end

function M:dispose()
  if self._is_disposed then
    return
  end
  self._is_disposed = true
  self._ports = {}
  self._contracts = {}
end

function M:_is_valid_port_id(port_id)
  return type(port_id) == "number" and 0 < port_id
end

return M
