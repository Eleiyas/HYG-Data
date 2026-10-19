local _class = {}
ClassType = {Class = 1, Instance = 2}

local function class(classname, super, namespace)
  assert(type(classname) == "string" and 0 < #classname)
  if super ~= nil and type(super) == "string" then
    super = require(super)
  end
  local class_type = {}
  class_type.__ctor = false
  class_type.__delete = false
  class_type.__cname = classname
  class_type.__ctype = ClassType.Class
  class_type.super = super
  
  function class_type.new(...)
    local obj = {}
    obj._class_type = class_type
    obj.__cname = classname
    obj.__ctype = ClassType.Instance
    obj.super = class_type.super
    setmetatable(obj, {
      __index = _class[class_type]
    })
    do
      local create
      
      function create(c, ...)
        if c.super then
          create(c.super, ...)
        end
        if c.__ctor then
          c.__ctor(obj, ...)
        end
      end
      
      create(class_type, ...)
    end
    
    function obj:Delete()
      local now_super = self._class_type
      while now_super ~= nil do
        if now_super.__delete then
          now_super.__delete(self)
        end
        now_super = now_super.super
      end
    end
    
    return obj
  end
  
  local vtbl = {}
  _class[class_type] = vtbl
  setmetatable(class_type, {
    __newindex = function(t, k, v)
      vtbl[k] = v
    end,
    __index = vtbl
  })
  if super then
    setmetatable(vtbl, {
      __index = function(t, k)
        local ret = _class[super][k]
        vtbl[k] = ret
        return ret
      end
    })
  end
  if namespace ~= nil and classname ~= nil then
    namespace[classname] = class_type
  end
  return class_type
end

local function new(class, ...)
  if class == nil then
    error("class is nil!")
    return nil
  end
  local name = class
  if type(class) == "string" then
    class = require(name)
  end
  if class.__ctype ~= ClassType.Class then
    error(tostring(name) .. " is not a class!")
    return nil
  end
  return class.new(...)
end

G = G or {}

function G.Class(name, super, namespace)
  return class(name, super, namespace or G)
end

G.New = new
