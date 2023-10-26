-- control.lua
g_entity = nil


local function get_blueprint(player)
	if player.cursor_stack then
		local obj = player.cursor_stack
	    	if obj.is_blueprint then
			if obj.item_number > 0 then
	        		return obj
			end
	    	elseif obj.is_blueprint_book and obj.active_index then
	        	local inventory = obj.get_inventory(defines.inventory.item_main)
	        	if #inventory > 0 then
	            		return get_blueprint(inventory[obj.active_index])
	       		end
	    	end
	end
    	return nil
end

local function clear_request_slots(entity)
	for index = 1, entity.request_slot_count do
		entity.clear_request_slot(index)
	end
end

local function get_requests(entity)
	local requests = {}
	for index = 1, entity.request_slot_count do
		local item = entity.get_request_slot(index)
		if item then
			requests[item["name"]] = item["count"]
		end
	end
	return requests
end

local function set_requests(entity, requests)
	local index = 1
	for key, count in pairs(requests) do
		entity.set_request_slot({name = key, count = count}, index)
		index = index + 1 
	end
end

local function set_requests_from_blueprint(player, blueprint, entity)
	local index = 1
	for key, count in pairs(blueprint.cost_to_build) do
		entity.set_request_slot({name = key, count = count}, index)
		index = index + 1
	end

	player.cursor_stack_temporary = false
	player.cursor_stack.clear()
end

local function save_entity(event)
	local player = game.get_player(event.player_index)
	if player.character then
		if player.selected and player.selected.valid and player.selected.name == "logistic-chest-requester" then
			g_entity = player.selected
			player.print("Requester chest saved!")
			return nil
		end

		if g_entity then
			g_entity = nil
			player.print("Installed by default!")
		end
	end
end

local function copy_blueprint_to_requester_chest(event)
	if g_entity and g_entity.valid then
		local player = game.get_player(event.player_index)
		if player.character then
			local blueprint = get_blueprint(player)
			if blueprint then
				clear_request_slots(g_entity)
				set_requests_from_blueprint(player, blueprint, g_entity)
				player.print("Blueprint pasted!")
			end
		end
	end
end

local function copy_blueprint_to_disposable_requester_chest(event)
	local player = game.get_player(event.player_index)
	if player.character then
		local blueprint = get_blueprint(player)
		if blueprint then
			local entities = {}
			entities[0] = {entity_number = 0, name = "logistic-chest-requester", position = {x = 0, y = 0}, items = {}}
		
			for key, count in pairs(blueprint.cost_to_build) do
				entities[0].items[key] = count
			end
		
			player.cursor_stack.clear_blueprint()
			player.cursor_stack.set_blueprint_entities(entities)
		end
	end
end


local function backup_request_slots(event)
	if g_entity and g_entity.valid then
		local player = game.get_player(event.player_index)
		if player.character then
			local requests = get_requests(player.character)
			clear_request_slots(g_entity)
			set_requests(g_entity, requests)
			player.print("The backup is ready!")
		end
	end
end

local function restore_request_slots(event)
	local player = game.get_player(event.player_index)
	if player.character then
		local blueprint = get_blueprint(player)
		if blueprint then
			clear_request_slots(player.character)
			set_requests_from_blueprint(player, blueprint, player.character)
			player.print("Restored from blueprint!")
		elseif g_entity and g_entity.valid then
			local requests = get_requests(g_entity)
			clear_request_slots(player.character)
			set_requests(player.character, requests)
			player.print("Restored from requester chest!")
		end
	end
end

script.on_event("BlueprintConverter_SAVE_ENTITY", 		function(event) save_entity(event) 					end)
script.on_event("BlueprintConverter_COPY_BLUEPRINT",		function(event) copy_blueprint_to_requester_chest(event) 		end)
script.on_event("BlueprintConverter_COPY_BLUEPRINT_DISPOSABLE",	function(event) copy_blueprint_to_disposable_requester_chest(event) 	end)
script.on_event("BlueprintConverter_BACKUP_REQUEST_SLOTS",	function(event) backup_request_slots(event) 				end)
script.on_event("BlueprintConverter_RESTORE_REQUEST_SLOTS",	function(event) restore_request_slots(event) 				end)