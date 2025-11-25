function Awake()
    root = host.transform:Find("Root");
    rootFull = root.transform:Find("Full");
    rootCut = root.transform:Find("Cut");
    print("Planet is ready");
    print(rootCut);
    print(healthPoint);
end

function OnAttacked_BeforeDamage(hitInfo)
    
    rootCut.parent = null;
    print("被武器击中了！")
    healthPoint = healthPoint-1;
    print(healthPoint)
    if healthPoint <= 0 then
            rootFull:SetActive(false);
            rootCut:SetActive(true);
            healthPoint=0;
    end
    
end

