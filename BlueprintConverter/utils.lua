-- utils.lua

function contain(t, key)
	for k, _ in pairs(t) do
		if key == k then
			return true
		end
	end
	return false
end

function contain_any(t, arr)
	for key, _ in pairs(t) do
		for index = 1, #arr do
			if key == arr[index] then
				return true
			end
		end
	end
	return false
end 

function has(arr, obj)
	for index = 1, #arr do
		if arr[index] == obj then
			return true
		end
	end
	return false
end

function empty(t)
	for _, _ in pairs(t) do
		return false
	end
	return true
end