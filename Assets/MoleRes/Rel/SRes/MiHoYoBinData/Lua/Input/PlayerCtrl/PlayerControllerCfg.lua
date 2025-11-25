local PlayerControllerCfg = {}
player_controller_short_cut = {
  interact = 1,
  pick = 2,
  back = 3
}
short_cut_type = {img = 1, text = 2}
PlayerControllerCfg.e_camera = {
  multi_platform = true,
  [ActionType.ControlModeType.KeyboardWithMouse] = {
    value_from = ActionType.CamValFrom.Mouse,
    camera = ActionType.Act.Camera,
    fixed_camera = ActionType.Act.FixedCamera,
    rotate_allowed = ActionType.Act.CameraRAllowed,
    rotate_allowed_new = ActionType.Act.RotateAllow,
    mouse_wheel = ActionType.Act.CameraUpAndDown
  },
  [ActionType.ControlModeType.TouchScreen] = {
    value_from = ActionType.CamValFrom.Touch,
    camera = ActionType.Act.Camera,
    fixed_camera = ActionType.Act.FixedCamera
  },
  [ActionType.ControlModeType.Joypad] = {
    value_from = ActionType.CamValFrom.Joypad,
    camera = ActionType.Act.Camera,
    fixed_camera = ActionType.Act.FixedCamera
  }
}
PlayerControllerCfg.e_ability = {
  pick = ActionType.Act.Pick,
  prop = ActionType.Act.UseProp,
  inter_action = ActionType.Act.InterAction,
  inter_action_down_and_up = ActionType.Act.InteractionDownUp,
  tool_wheel = ActionType.Act.ToolWheel
}
return PlayerControllerCfg
