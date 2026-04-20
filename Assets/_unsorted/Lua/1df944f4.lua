function OnEditorButton()
    --print("点击了编辑器按钮！")
    --API示例：给玩家加速50%
    --API:AddMoveSpeedMultiplier(Player.guid,value)
    print(move_horizontal);
end

function player_controller:_handle_move_rotate()
    move_horizontal = InputManagerIns:get_axis(ActionType.Act.Horizontal);
    move_vertical = InputManagerIns:get_axis(ActionType.Act.Vertical);
end 