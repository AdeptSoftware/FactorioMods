-- control.lua
g_entity = nil


-- Utils

local function clear_cursor_stack(player)
	player.cursor_stack_temporary = false
	player.cursor_stack.clear()
end

local function spawn(inventory, item_name)
	inventory.insert{name=item_name}
	
	for index = #inventory, 0, -1 do
		if inventory[index].valid_for_read then
			if inventory[index].name == item_name then
				return inventory[index]
			end
		end
	end

	return nil
end


-- Blueprints

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

local function set_requester_chest(blueprint, requests, is_disposable)
	local entities 	= {}
	entities[0] 	= {entity_number = 0, name = "logistic-chest-requester", position = {x = 0, y = 0}, items = {}, request_filters = {}}

	local index = 1
	local requester_chest = entities[0]
	for key, value in pairs(requests) do
		if is_disposable then
			requester_chest.items[key] = value
		else
			requester_chest.request_filters[index] = {index = index, name = key, count = value}
		end
		index = index + 1
	end

	blueprint.clear_blueprint()
	blueprint.set_blueprint_entities(entities)
end


-- Requests

local function clear_requests(entity)
	for index = 1, entity.request_slot_count do
		entity.clear_request_slot(index)
	end
end

local function get_requests(entity)
	local flag = false
	local requests = {}
	for index = 1, entity.request_slot_count do
		local item = entity.get_request_slot(index)
		if item then
			requests[item["name"]] = item["count"]
			flag = true
		end
	end

	if not flag then
		return nil
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


-- Commands

local function save_target_entity(event)
	local player = game.get_player(event.player_index)
	if player and player.character then
		if player.selected and player.selected.valid then
			if player.selected.name == "logistic-chest-requester" or player.selected.name == "spidertron" then
				g_entity = player.selected
				player.print("Object saved!")
				return nil
			end
		end

		if g_entity then
			g_entity = nil
			player.print("Installed by default!")
		end
	end
end

local function paste_blueprint(event, is_disposable)
	local player = game.get_player(event.player_index)
	if player and player.character then
		local blueprint = get_blueprint(player)		
		if blueprint then
			if not is_disposable and g_entity then
				if g_entity.valid then
					clear_requests(g_entity)
					set_requests(g_entity, blueprint.cost_to_build)
					clear_cursor_stack(player)
					player.print("Blueprint pasted!")
				end
			else
				set_requester_chest(blueprint, blueprint.cost_to_build, is_disposable)
			end
		end
	end
end

local function backup_request_slots(event)
	local player = game.get_player(event.player_index)
	if player and player.character then
		if g_entity then
			if g_entity.valid then
				clear_requests(g_entity)
				set_requests(g_entity, get_requests(player.character))
				player.print("The backup is ready!")
			end
		else
			local requests = get_requests(player.character)
			if requests then
				local inventory = player.get_main_inventory()
				local blueprint = spawn(inventory, "blueprint")
				if blueprint then
					set_requester_chest(blueprint, requests, false)
					player.cursor_stack.set_stack(blueprint)
					player.cursor_stack_temporary = true
				end
				inventory.remove(blueprint)
			end
		end
	end
end

local function restore_request_slots(event)
	local player = game.get_player(event.player_index)
	if player and player.character then
		if g_entity then
			if g_entity.valid then
				clear_requests(player.character)
				set_requests(player.character, get_requests(g_entity))
				player.print("Restored from object!")
			end
		else
			local blueprint = get_blueprint(player)
			if blueprint then
				clear_requests(player.character)
				set_requests(player.character, blueprint.cost_to_build)
				clear_cursor_stack(player)
				player.print("Restored from blueprint!")
			end
		end
	end
end

script.on_event("BlueprintConverter_SAVE_TARGET_ENTITY", 		function(event) save_target_entity(event) 		end)
script.on_event("BlueprintConverter_PASTE_BLUEPRINT",			function(event) paste_blueprint(event, false) 		end)
script.on_event("BlueprintConverter_PASTE_BLUEPRINT_DISPOSABLE",	function(event) paste_blueprint(event, true) 		end)
script.on_event("BlueprintConverter_BACKUP_REQUEST_SLOTS",		function(event) backup_request_slots(event) 		end)
script.on_event("BlueprintConverter_RESTORE_REQUEST_SLOTS",		function(event) restore_request_slots(event) 		end)