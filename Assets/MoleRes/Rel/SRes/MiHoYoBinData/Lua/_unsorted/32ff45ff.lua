MoveController = MoveController or {}

moveSpeed = moveSpeed or 0.01;
rotateSpeed = rotateSpeed or 0.1;

positions = {};
rotations = {};
isShaking = false
count = 0;
isRunning = false;


function Start()
    host.transform:GetAllChildrenRecursively():ForEach(function(t)
        API:ListenCollisionTrigger(function(collider)
            if collider.gameObject.name == "Bus" then
                MoveController:OnCollision();
            end
        end, t.gameObject)
    end)
end

function OnEditorButton()
    isRunning = not isRunning;
end

function Update()
    if (not isRunning) then
        return
    end
    if (not isShaking) then
        Rotate()
        Move()
        if (count % 6 == 0) then
            positions.Add(level.transform.position);
            rotations.Add(level.transform.rotation);
            if (positions.Count >= 10)then positions.RemoveAt(0) end
            if (rotations.Count >= 10)then rotations.RemoveAt(0) end
        end
    end
end

function MoveController:Rotate()
    local x = 0;
    if (Input.GetKey(KeyCode.A)) then x = x-1 end

    if (Input.GetKey(KeyCode.D)) then x = x+1 end

    if (x==0) then return end

    level.transform.RotateAround(bus.transform.position,level.transform.forward, x * rotateSpeed);
end

function MoveController:Move()
    level.transform.position = level.transform.position - host.transform.parent.up * moveSpeed;
end

function MoveController:OnCollision()
    isShaking = true
    level.transform.DOShakePosition(1).onComplete = function()
        level.transform.position = positions[1];
        level.transform.rotation = rotations[1];
        positions = {level.transform.position};
        rotations = {level.transform.rotation};
        isShaking = false;
    end
end
    
