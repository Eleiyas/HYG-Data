function math.get_bit(num, index)
  return (num & 1 << index) >> index
end

function math.set_bit(num, index, value)
  if 0 < value then
    num = num | 1 << index
  else
    num = num & ~(1 << index)
  end
  return num
end

function math.get_vec3_distance(vec3_a, vac3_b)
  local x = vec3_a.x - vac3_b.x
  local y = vec3_a.y - vac3_b.y
  local z = vec3_a.z - vac3_b.z
  return math.sqrt(x * x + y * y + z * z)
end

function math.clamp(value, min_val, max_val)
  return math.max(min_val, math.min(max_val, value))
end
