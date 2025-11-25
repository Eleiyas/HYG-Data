function Start()
    
    --获取Avatar的根并重设父对象
    API:DelayCall(1, function()
        host.transform:SetParent(Player.root.transform, false);
    end);
end
