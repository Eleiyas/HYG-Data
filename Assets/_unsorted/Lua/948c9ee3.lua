local avatar = nil;

function Update()
	if avatar == nil then
		avatar = GameObject.Find("Avatar(Clone)");
	end

	if avatar ~= nil then
		host.transform.position = Vector3(avatar.transform.position.x,0,avatar.transform.position.z);
	end
end

function OnDestroy()
	avatar = nil;
end