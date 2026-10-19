function string.is_valid(str)
  return str ~= nil and type(str) == "string" and 0 < #str
end
