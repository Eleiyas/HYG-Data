local SingletonUtil = {}
local singleton = {}
local cs_get_func = SingletonManager.GetSingletonInstance

local function get(class_name)
  if singleton[class_name] then
    return singleton[class_name]
  end
  singleton[class_name] = cs_get_func(class_name)
  return singleton[class_name]
end

local function clear_on_back_home()
  singleton = {}
end

SingletonUtil.get = get
SingletonUtil.clear_on_back_home = clear_on_back_home
return SingletonUtil
