-- control.lua

g_entity    = nil

function get_blueprint(obj)
    	if obj.is_blueprint then
        	return obj
    	elseif obj.is_blueprint_book and obj.active_index then
        	local inventory = obj.get_inventory(defines.inventory.item_main)
        	if #inventory > 0 then
            		return get_blueprint(inventory[obj.active_index])
       		end
    	end

    	return nil
end

-- [[
local function convert_to_disposable_request_chest(player, blueprint)
	local entities = {}
	entities[0] = {entity_number = 0, name = "logistic-chest-requester", position = {x = 0, y = 0}, items = {}}

	for key, count in pairs(blueprint.cost_to_build) do
		entities[0].items[key] = count
	end

	player.cursor_stack.clear_blueprint()
	player.cursor_stack.set_blueprint_entities(entities)
end
-- ]]	

local function save_entity(event)
	local player = game.get_player(event.player_index)
	if player.character and player.selected and player.selected.valid and player.selected.name == "logistic-chest-requester" then
		g_entity = player.selected
		player.print("Request chest saved!")
	end
end

local function copy_blueprint_to_requester_chest(event)
	if g_entity and g_entity.valid then
		local player = game.get_player(event.player_index)
		if player.character then
			local blueprint = get_blueprint(player.cursor_stack)
			if blueprint and blueprint.item_number ~= 0 then
				for index = 1, g_entity.request_slot_count do
					g_entity.clear_request_slot(index)
				end
				
				local index = 1
				for key, count in pairs(blueprint.cost_to_build) do
					g_entity.set_request_slot({name = key, count = count}, index)
					index = index + 1
				end

				player.cursor_stack_temporary = false
				player.cursor_stack.clear()
				player.print("Blueprint pasted!")
			end
		end
	end
end

script.on_event("BlueprintConverter_SAVE_ENTITY", 	function(event) save_entity(event) 				end)
script.on_event("BlueprintConverter_COPY_BLUEPRINT",	function(event) copy_blueprint_to_requester_chest(event) 	end)