function Awake()
    host.transform:DOScale(0,  2)
    API:DelayCall(2, function()
        --2秒后执行
        host:SetActive(false);
        print("延迟2秒才执行的内容")
    end);
end

