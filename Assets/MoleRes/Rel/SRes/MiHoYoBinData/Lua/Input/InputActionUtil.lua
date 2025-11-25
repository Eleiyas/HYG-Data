local InputActionUtil = InputActionUtil or {}

function pack_action(...)
  return {
    ...
  }
end

local function bind_d_pad_horizontal(panel, func, with_repeat)
  if panel then
    if with_repeat then
      panel:bind_input_and_fun(ActionType.Act.DPad_Left, func, ActionType.EType.ButtonRepeating)
      panel:bind_input_and_fun(ActionType.Act.DPad_Right, func, ActionType.EType.ButtonRepeating)
    else
      panel:bind_input_and_fun(ActionType.Act.DPad_Left, func)
      panel:bind_input_and_fun(ActionType.Act.DPad_Right, func)
    end
  end
end

local function bind_d_pad_vertical(panel, func, with_repeat)
  if panel then
    if with_repeat then
      panel:bind_input_and_fun(ActionType.Act.DPad_Up, func, ActionType.EType.ButtonRepeating)
      panel:bind_input_and_fun(ActionType.Act.DPad_Down, func, ActionType.EType.ButtonRepeating)
    else
      panel:bind_input_and_fun(ActionType.Act.DPad_Up, func)
      panel:bind_input_and_fun(ActionType.Act.DPad_Down, func)
    end
  end
end

local function bind_stick_horizontal(panel, func, with_repeat)
  if panel then
    if with_repeat then
      panel:bind_input_and_fun(ActionType.Act.LeftStickLeft, func, ActionType.EType.ButtonRepeating)
      panel:bind_input_and_fun(ActionType.Act.LeftStickRight, func, ActionType.EType.ButtonRepeating)
    else
      panel:bind_input_and_fun(ActionType.Act.LeftStickLeft, func, ActionType.EType.ButtonPressed)
      panel:bind_input_and_fun(ActionType.Act.LeftStickRight, func, ActionType.EType.ButtonPressed)
    end
  end
end

local function bind_stick_vertical(panel, func, with_repeat)
  if panel then
    if with_repeat then
      panel:bind_input_and_fun(ActionType.Act.LeftStickDown, func, ActionType.EType.ButtonRepeating)
      panel:bind_input_and_fun(ActionType.Act.LeftStickUp, func, ActionType.EType.ButtonRepeating)
    else
      panel:bind_input_and_fun(ActionType.Act.LeftStickDown, func, ActionType.EType.ButtonPressed)
      panel:bind_input_and_fun(ActionType.Act.LeftStickUp, func, ActionType.EType.ButtonPressed)
    end
  end
end

local function bind_right_stick_horizontal(panel, func, with_repeat)
  if panel then
    if with_repeat then
      panel:bind_input_and_fun(ActionType.Act.RightStickLeft, func, ActionType.EType.ButtonRepeating)
      panel:bind_input_and_fun(ActionType.Act.RightStickRight, func, ActionType.EType.ButtonRepeating)
    else
      panel:bind_input_and_fun(ActionType.Act.RightStickLeft, func, ActionType.EType.ButtonPressed)
      panel:bind_input_and_fun(ActionType.Act.RightStickRight, func, ActionType.EType.ButtonPressed)
    end
  end
end

local function bind_right_stick_vertical(panel, func, with_repeat)
  if panel then
    if with_repeat then
      panel:bind_input_and_fun(ActionType.Act.RightStickUp, func, ActionType.EType.ButtonRepeating)
      panel:bind_input_and_fun(ActionType.Act.RightStickDown, func, ActionType.EType.ButtonRepeating)
    else
      panel:bind_input_and_fun(ActionType.Act.RightStickUp, func, ActionType.EType.ButtonPressed)
      panel:bind_input_and_fun(ActionType.Act.RightStickDown, func, ActionType.EType.ButtonPressed)
    end
  end
end

local function is_up(action)
  if not action then
    return false
  end
  local type = action.type
  local event = action.event_type
  local meet_event = event == ActionType.EType.ButtonRepeating or event == ActionType.EType.ButtonPressed
  if (type == ActionType.Act.DPad_Up or type == ActionType.Act.LeftStickUp or type == ActionType.Act.RightStickUp) and meet_event then
    return true
  end
  return false
end

local function is_down(action)
  if not action then
    return false
  end
  local type = action.type
  local event = action.event_type
  local meet_event = event == ActionType.EType.ButtonRepeating or event == ActionType.EType.ButtonPressed
  if (type == ActionType.Act.DPad_Down or type == ActionType.Act.RightStickDown or type == ActionType.Act.LeftStickDown) and meet_event then
    return true
  end
  return false
end

local function is_left(action)
  if not action then
    return false
  end
  local type = action.type
  local event = action.event_type
  local meet_event = event == ActionType.EType.ButtonRepeating or event == ActionType.EType.ButtonPressed
  if (type == ActionType.Act.LeftStickLeft or type == ActionType.Act.RightStickLeft or type == ActionType.Act.DPad_Left) and meet_event then
    return true
  end
  return false
end

local function is_right(action)
  if not action then
    return false
  end
  local type = action.type
  local event = action.event_type
  local meet_event = event == ActionType.EType.ButtonRepeating or event == ActionType.EType.ButtonPressed
  if (type == ActionType.Act.DPad_Right or type == ActionType.Act.RightStickRight or type == ActionType.Act.LeftStickRight) and meet_event then
    return true
  end
  return false
end

InputActionUtil.bind_d_pad_vertical = bind_d_pad_vertical
InputActionUtil.bind_d_pad_horizontal = bind_d_pad_horizontal
InputActionUtil.bind_stick_vertical = bind_stick_vertical
InputActionUtil.bind_stick_horizontal = bind_stick_horizontal
InputActionUtil.bind_right_stick_vertical = bind_right_stick_vertical
InputActionUtil.bind_right_stick_horizontal = bind_right_stick_horizontal
InputActionUtil.is_up = is_up
InputActionUtil.is_down = is_down
InputActionUtil.is_left = is_left
InputActionUtil.is_right = is_right
return InputActionUtil
