function Update()
    if API:IsInRange(Player.root, host.gameObject, 1) then
        API:ShowOptionButton("通关", function()
            print("通关")
            CsLocalCmdHandlerUtil.RunCmd('ShowPage(UI/StarCore/StarLinkPage)',nil);
            --CsLocalCmdHandlerUtil.RunCmd("CfgCallLua(StarSettlement)",nil);
            --EventCenter.Broadcast(EventID.CfgCallLua, "StarSettlement");
        end)
    else
        API:RemoveOptionButton("通关")
    end
end