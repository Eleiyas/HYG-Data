local function func()
  print("func with 0 param")
end

local function func(param1)
  print("func with 1 param")
end

local function func(param1, param2)
  print("func with 2 param")
end

local function Run()
  func()
  func("p1")
  func("p1", "p2")
end

local function Run2()
  local dic = {
    [1] = "a",
    [3] = "c",
    [4] = "d"
  }
  for k, v in pairs(dic) do
    print(k)
    print(dic[k])
  end
  print("------------------")
  for k, v in ipairs(dic) do
    print(dic[k])
  end
end

local function Run3()
  local a = {}
  a.x = 10
  local b = a
  print(b.x)
  b.x = 20
  print(a.x)
end

local avatar = {level = 10, hp = 200}

local function set_const(tbl)
  local mt = {}
  for i, v in pairs(tbl) do
    mt[i] = v
  end
  
  function mt.__index(table, key)
    local value = mt[key]
    if value == nil then
      print(key .. " 字段是不存在的, 不要试图获取它")
    end
    return value
  end
  
  function mt.__newindex(table, key, value)
    print(key .. " 字段是不存在的, 不要试图给它赋值")
  end
  
  setmetatable(tbl, mt)
end

local function set_const_simple(tbl)
  setmetatable(tbl, {
    __index = function(table, key)
      print(key .. " 字段是不存在的, 不要试图获取它")
    end,
    __newindex = function(table, key, value)
      print(key .. " 字段是不存在的, 不要试图给它赋值")
    end
  })
end

set_const_simple(avatar)
print(avatar.hp)
avatar.hp = 250
print(avatar.hp)
print(avatar.mp)
avatar.mp = 200
local gifts = {
  {name = "mac", weight = 1},
  {name = "iphone", weight = 10},
  {name = "xiaomi", weight = 40},
  {name = "switch", weight = 60}
}

local function gacha_get_item(gift_arr)
  local sum = 0
  for i = 1, #gift_arr do
    sum = sum + gift_arr[i].weight
  end
  local index = 0
  math.randomseed(tostring(os.time()):reverse():sub(1, 6))
  local point = math.random(sum)
  while 0 <= point do
    print(index .. " " .. point)
    index = index + 1
    point = point - gift_arr[index].weight
  end
  return gift_arr[index].name
end

print(gacha_get_item(gifts))
