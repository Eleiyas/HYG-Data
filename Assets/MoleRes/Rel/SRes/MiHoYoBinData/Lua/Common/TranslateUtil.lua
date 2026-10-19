local M = {}
local INIT_NONE = 0
local INIT_DOING = 1
local INIT_OK = 2
local INIT_FAILED = 3
local DEFAULT_CACHE_BYTE_BUDGET = 65536
local PENDING_TIMEOUT = 30
local INIT_TIMEOUT = 30
local MAX_QUEUED = 64
local _buckets = {}
local _pending = {}
local _pending_uncached = {}
local _init_state = INIT_NONE
local _init_deadline = 0
local _init_epoch = 0
local _queued = {}

local function _now()
  return Time.realtimeSinceStartup
end

local function _target_lang()
  return CsLocalizationManagerUtil.curLanguageStr or ""
end

local function _cache_get(scene_id, text)
  local bucket = _buckets[scene_id]
  if bucket == nil then
    return nil
  end
  return bucket.map[text]
end

local function _cache_put(scene_id, text, translated, budget)
  local limit = budget or DEFAULT_CACHE_BYTE_BUDGET
  local cost = #text + #translated
  if limit < cost then
    return
  end
  local bucket = _buckets[scene_id]
  if bucket == nil then
    bucket = {
      map = {},
      order = {},
      head = 1,
      tail = 0,
      bytes = 0,
      budget = limit
    }
    _buckets[scene_id] = bucket
  end
  if bucket.map[text] ~= nil then
    return
  end
  bucket.map[text] = translated
  bucket.tail = bucket.tail + 1
  bucket.order[bucket.tail] = {text = text, cost = cost}
  bucket.bytes = bucket.bytes + cost
  while bucket.bytes > bucket.budget and bucket.head <= bucket.tail do
    local oldest = bucket.order[bucket.head]
    bucket.order[bucket.head] = nil
    bucket.head = bucket.head + 1
    if oldest ~= nil then
      bucket.bytes = bucket.bytes - oldest.cost
      bucket.map[oldest.text] = nil
    end
  end
end

local function _on_language_changed()
  _buckets = {}
  _pending = {}
  _pending_uncached = {}
end

EventCenter.LuaAddListener(EventID.onAfterLanguageChange, _on_language_changed)

local function _pending_peek(registry, scene_id, text)
  local bucket = registry[scene_id]
  if bucket == nil then
    return nil
  end
  return bucket[text]
end

local function _pending_set(registry, scene_id, text, entry)
  local bucket = registry[scene_id]
  if bucket == nil then
    bucket = {}
    registry[scene_id] = bucket
  end
  bucket[text] = entry
end

local function _pending_get(registry, scene_id, text)
  local entry = _pending_peek(registry, scene_id, text)
  if entry == nil then
    return nil
  end
  if _now() > entry.deadline then
    _pending_set(registry, scene_id, text, nil)
    return nil
  end
  return entry
end

function M.is_available(opts)
  if opts == nil or type(opts.scene_id) ~= "string" or opts.scene_id == "" then
    return false
  end
  if not string.is_valid(_target_lang()) then
    return false
  end
  if opts.enabled ~= nil and not opts.enabled() then
    return false
  end
  return true
end

function M.get_cached(text, opts)
  if not string.is_valid(text) or not M.is_available(opts) then
    return nil
  end
  return _cache_get(opts.scene_id, text)
end

local _request

local function _flush_queued(success)
  local queued = _queued
  _queued = {}
  for _, item in ipairs(queued) do
    if success then
      _request(item.text, item.opts, item.result_callback, item.use_cache)
    else
      item.result_callback(false, item.text)
    end
  end
end

local function _try_hold_until_init(text, opts, result_callback, use_cache)
  if _init_state == INIT_OK then
    return false
  end
  if _init_state == INIT_FAILED then
    result_callback(false, text)
    return true
  end
  if _init_state == INIT_DOING and _now() > _init_deadline then
    _init_state = INIT_NONE
    _init_epoch = _init_epoch + 1
    _flush_queued(false)
  end
  if #_queued >= MAX_QUEUED then
    result_callback(false, text)
    return true
  end
  table.insert(_queued, {
    text = text,
    opts = opts,
    result_callback = result_callback,
    use_cache = use_cache
  })
  if _init_state == INIT_DOING then
    return true
  end
  _init_state = INIT_DOING
  _init_deadline = _now() + INIT_TIMEOUT
  _init_epoch = _init_epoch + 1
  local epoch = _init_epoch
  CsChatModuleUtil.InitTranslateModule(function(success, msg)
    if epoch ~= _init_epoch then
      return
    end
    _init_state = success and INIT_OK or INIT_FAILED
    if not success then
      Logger.LogWarning(string.format("[Translate] init failed: %s", tostring(msg)))
    end
    _flush_queued(success)
  end)
  return true
end

function _request(text, opts, result_callback, use_cache)
  if type(result_callback) ~= "function" then
    return
  end
  if not string.is_valid(text) or not M.is_available(opts) then
    result_callback(false, text)
    return
  end
  local scene_id = opts.scene_id
  if use_cache then
    local cached = _cache_get(scene_id, text)
    if cached ~= nil then
      result_callback(true, cached)
      return
    end
  end
  local registry = use_cache and _pending or _pending_uncached
  local waiting = _pending_get(registry, scene_id, text)
  if waiting ~= nil then
    table.insert(waiting.callbacks, result_callback)
    return
  end
  if _try_hold_until_init(text, opts, result_callback, use_cache) then
    return
  end
  local lang = _target_lang()
  local entry = {
    callbacks = {result_callback},
    deadline = _now() + PENDING_TIMEOUT
  }
  _pending_set(registry, scene_id, text, entry)
  CsChatModuleUtil.RequestTranslateText(text, opts.source_language or "", lang, scene_id, function(success, result, error_message)
    if _pending_peek(registry, scene_id, text) == entry then
      _pending_set(registry, scene_id, text, nil)
    end
    local translated
    if not success then
      Logger.LogWarning(string.format("[Translate] failed, scene=%s, lang=%s, err=%s", tostring(scene_id), tostring(lang), tostring(error_message)))
    elseif _target_lang() ~= lang then
    elseif string.is_valid(result) then
      if use_cache then
        _cache_put(scene_id, text, result, opts.cache_byte_budget)
        translated = _cache_get(scene_id, text) or result
      else
        translated = result
      end
    end
    for _, cb in ipairs(entry.callbacks) do
      cb(translated ~= nil, translated or text)
    end
  end)
end

function M.apply_with_translation(text, opts, apply_callback, guard_callback, use_cache)
  local with_cache = use_cache ~= false
  if not string.is_valid(text) or not M.is_available(opts) then
    apply_callback(text)
    return
  end
  if with_cache then
    local cached = _cache_get(opts.scene_id, text)
    if cached ~= nil then
      apply_callback(cached)
      return
    end
  end
  apply_callback(text)
  _request(text, opts, function(success, result)
    if not success then
      return
    end
    if guard_callback ~= nil and not guard_callback() then
      return
    end
    apply_callback(result)
  end, with_cache)
end

function M.gate_server_language()
  if CsGameManagerUtil.gameConfig:IsCN() then
    return false
  end
  return CsLocalizationManagerUtil.GetCurLanguageType() ~= CsGameManagerUtil.gameConfig.CurServerLanguageType
end

M.SCENE_LLM_TEXT = {
  scene_id = "llm_npc_text",
  source_language = "",
  enabled = M.gate_server_language
}

function M.translate_once(text, result_callback, scene_id, use_cache)
  if type(result_callback) ~= "function" then
    return
  end
  if not string.is_valid(text) then
    result_callback(false, text)
    return
  end
  
  local function on_result(success, result, error_message)
    if not success or not string.is_valid(result) then
      Logger.LogWarning(string.format("[Translate] once failed, scene=%s, err=%s", tostring(scene_id), tostring(error_message)))
      result_callback(false, text)
      return
    end
    result_callback(true, result)
  end
  
  CsChatModuleUtil.TranslateOnce(text, scene_id or "", use_cache == true, on_result)
end

function M.clear_scene_context(scene_id)
  if not string.is_valid(scene_id) then
    return
  end
  CsChatModuleUtil.ClearTranslateSceneContext(scene_id)
end

function M.apply_once(text, apply_callback, guard_callback, scene_id, use_cache)
  apply_callback(text)
  if CsGameManagerUtil.gameConfig:IsCN() then
    return
  end
  M.translate_once(text, function(success, result)
    if not success then
      return
    end
    if guard_callback ~= nil and not guard_callback() then
      return
    end
    apply_callback(result)
  end, scene_id, use_cache)
end

return M
