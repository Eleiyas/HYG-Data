local currentScore = 0
local countTime = false
local passedTime = 0

function OnCollisionToPlayer()
    AddScore()
    model.gameObject:SetActive(false)
    countTime = true
end

function Update()
    if countTime then
        passedTime = passedTime + CS.UnityEngine.Time.deltaTime
        if passedTime >= 5 then
            model.gameObject:SetActive(true)
            countTime = false
            passedTime = 0
        end
    else
    end
end

function AddScore()
    currentScore = currentScore + 1
    API:ShowTooltip("Current Score = "..currentScore)
    if currentScore >= 5 then
        API:ShowTooltip("You Win!")
        currentScore = 0
    end
end
