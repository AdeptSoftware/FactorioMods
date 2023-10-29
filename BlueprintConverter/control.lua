-- control.lua
require("utils")

g_entity 		= nil
g_merging_mode 		= false

local g_request_objects = {"logistic-chest-requester", "logistic-chest-buffer", "spidertron"}

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
	    	end
	end
    	return nil
end

local function blueprint2requests(blueprint)
	if not empty(blueprint.cost_to_build) and contain_any(blueprint.cost_to_build, g_request_objects) then
		local entities = blueprint.get_blueprint_entities()
		if #entities == 1 and contain(entities[1], "request_filters") then
			local requests = {}
			local request_filters = entities[1].request_filters
			for index = 1, #request_filters do
				requests[request_filters[index].name] = request_filters[index].count
			end
			return requests
		end
	end
	return blueprint.cost_to_build
end

local function set_requester_chest(blueprint, requests, is_disposable)
	local entities 	= {}
	entities[1] 	= {entity_number = 1, name = "logistic-chest-requester", position = {x = 0, y = 0}, items = {}, request_filters = {}}

	local index = 1
	local requester_chest = entities[1]
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
	local requests = {}
	for index = 1, entity.request_slot_count do
		local item = entity.get_request_slot(index)
		if item and item["count"] > 0 then
			requests[item["name"]] = item["count"]
		end
	end

	return requests
end

local function set_requests(entity, requests)
	local index = 1
	for key, count in pairs(requests) do
		if count > 0 then							-- check repeat?
			entity.set_request_slot({name = key, count = count}, index)
			index = index + 1 
		end
	end
end

local function update_requests(entity, new_requests)
	if g_merging_mode then
		local requests = get_requests(entity)
		if not empty(requests) then
			for key, count in pairs(requests) do
				if contain(new_requests, key) then
					if new_requests[key] + requests[key] + 0.0 > 4294967295.0 then
						new_requests[key] = 4294967295
					else
						new_requests[key] = new_requests[key] + requests[key]
					end
				else
					new_requests[key] = requests[key]
				end
			end
		end
	end

	clear_requests(entity)
	set_requests(entity, new_requests)
end


-- Commands

local function save_target_entity(event)
	local player = game.get_player(event.player_index)
	if player and player.character then
		if player.selected and player.selected.valid then
			if has(g_request_objects, player.selected.name) then
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

local function blueprint_merging_mode(event)
	g_merging_mode = not g_merging_mode
	game.get_player(event.player_index).print("Merging mode: "..tostring(g_merging_mode))
end

local function paste_blueprint(event, is_disposable)
	local player = game.get_player(event.player_index)
	if player and player.character then
		local blueprint = get_blueprint(player)		
		if blueprint then
			if not is_disposable and g_entity then
				if g_entity.valid then
					update_requests(g_entity, blueprint2requests(blueprint))
					clear_cursor_stack(player)
					player.print("Blueprint pasted!")
				end
			else
				set_requester_chest(blueprint, blueprint2requests(blueprint), is_disposable)
				player.cursor_stack_temporary = true
			end
		end
	end
end

local function backup_request_slots(event)
	local player = game.get_player(event.player_index)
	if player and player.character then
		if g_entity then
			if g_entity.valid then
				local requests = get_requests(player.character)
				if not empty(requests) then
					update_requests(g_entity, requests)
					player.print("The backup is ready!")
				end
			end
		else
			local requests = get_requests(player.character)
			if not empty(requests) then
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
		if g_entity and g_entity.valid then
			local requests = get_requests(g_entity)
			if not empty(requests) then
				update_requests(player.character, requests)
				player.print("Restored from object!")
			end
		else
			local blueprint = get_blueprint(player)
			if blueprint then
				update_requests(player.character, blueprint2requests(blueprint))
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
script.on_event("BlueprintConverter_BLUEPRINT_MERGING_MODE",		function(event) blueprint_merging_mode(event) 		end)
