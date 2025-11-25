function Awake()
    root = host.transform:Find("Root");
    rootFull = root.transform:Find("Full");
    rootCut = root.transform:Find("Cut");
    print("Planet is ready");
    print(rootCut);
end

function OnAttacked_BeforeDamage(hitInfo)
    
    rootCut.parent = null;
    print("被武器击中了！")
    rootCut:SetActive(true);
    
end

