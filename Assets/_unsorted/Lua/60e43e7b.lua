function Start()
    API:ShowOptionButton("测试按钮", function() print(111)  end)
end

function OnEditorButton()
    print(111)
    API:DisplayItemsById({1151,1152,1153},"test",true,300,Vector2(100,500))
end

function OnOptionButton(buttonName)
    print("按钮 "..buttonName.."被点击了")
end