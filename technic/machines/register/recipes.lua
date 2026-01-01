
local have_ui = core.get_modpath("unified_inventory")
local have_cg = core.get_modpath("craftguide")
local have_mcl_cg = core.get_modpath("mcl_craftguide")
local have_i3 = core.get_modpath("i3")

technic.recipes = {
	cooking = {input_size = 1, output_size = 1, recipes = {}},
}

local temp_recipes = {}  -- Used to store recipes before caching
local recipe_cache = {}  -- Cache used by technic.get_recipe

function technic.register_recipe_type(method, data)
	data = table.copy(data)
	data.input_size = data.input_size or 1
	data.output_size = data.output_size or 1
	data.recipes = {}
	if have_ui then
		unified_inventory.register_craft_type(method, {
			description = data.description,
			icon = data.icon,
			width = data.input_size,
			height = 1,
		})
	end
	if have_cg then
		craftguide.register_craft_type(method, {
			description = data.description,
			icon = data.icon,
		})
	end
	if have_mcl_cg then
		mcl_craftguide.register_craft_type(method, {
			description = data.description,
			icon = data.icon,
		})
	end
	if have_i3 then
		i3.register_craft_type(method, {
			description = data.description,
			icon = data.icon,
		})
	end
	technic.recipes[method] = data
end

function technic.register_recipe(method, data)
	data.time = data.time or 1
	data.method = method
	if type(data.input) == "string" then
		data.input = {data.input}
	end
	if type(data.output) == "string" then
		data.output = {data.output}
	end
	table.insert(temp_recipes, data)
end

local function get_recipe_key(method, items)
	local t = {}
	for i, stack in ipairs(items) do
		t[i] = ItemStack(stack):get_name()
	end
	table.sort(t)
	return method.."/"..table.concat(t, "/")
end

function technic.get_recipe(method, items)
	local key = get_recipe_key(method, items)
	local recipe = recipe_cache[key]
	if not recipe then
		return
	end
	local new_input = {}
	for i, stack in ipairs(items) do
		local amount = recipe.input[stack:get_name()]
		if stack:get_count() < amount then
			return
		else
			new_input[i] = ItemStack(stack)
			new_input[i]:take_item(amount)
		end
	end
	return {
		time = recipe.time,
		new_input = new_input,
		output = recipe.output
	}
end

local function add_to_craftguides(recipe)
	for _, output in ipairs(recipe.output) do
		if have_ui then
			unified_inventory.register_craft({
				type = recipe.method,
				output = output,
				items = table.copy(recipe.input),
				width = 0,
			})
		end
		if have_cg and craftguide.register_craft then
			craftguide.register_craft({
				type = recipe.method,
				result = output,
				items = {table.concat(recipe.input, ", ")},
			})
		end
		if have_mcl_cg then
			mcl_craftguide.register_craft({
				type = recipe.method,
				output = output,
				items = table.copy(recipe.input),
				width = 0,
			})
		end
		if have_i3 then
			i3.register_craft({
				type = recipe.method,
				result = output,
				items = {table.concat(recipe.input, ", ")},
			})
		end
	end
end

local function get_items_in_group(group)
	local items = {}
	local groups = group:split(",")
	for name, def in pairs(core.registered_items) do
		local match = true
		for _,g in pairs(groups) do
			if not def.groups[g] then
				match = false
				break
			end
		end
		if match then
			items[#items+1] = name
		end
	end
	return items
end

local function get_recipe_variants(items, index)
	index = index or 1
	if not items[index] then
		return
	end
	local list = {}
	local variants = get_recipe_variants(items, index + 1)
	if variants then
		for _,a in pairs(items[index]) do
			for _,b in pairs(variants) do
				list[#list+1] = a..","..b
			end
		end
	else
		for _,a in pairs(items[index]) do
			list[#list+1] = a
		end
	end
	if index == 1 then
		for i, str in pairs(list) do
			list[i] = str:split(",")
		end
	end
	return list
end

local function cache_recipe(data)
	-- Create the basic recipe
	local recipe = {time = data.time, input = {}, output = {}}
	for _, item in ipairs(data.input) do
		if item:match("^group:") then
			local split = item:split(" ")
			recipe.input[split[1]] = tonumber(split[2]) or 1
		else
			local stack = ItemStack(item)
			recipe.input[stack:get_name()] = stack:get_count()
		end
	end
	for i, item in ipairs(data.output) do
		recipe.output[i] = ItemStack(item):to_string()
	end
	if data.method ~= "cooking" then
		table.insert(technic.recipes[data.method].recipes, recipe)
	end
	-- Find all unique variants of the recipe and cache them
	-- If there are no group items, there will only be one
	local all_items, item_counts = {}, {}
	local has_group_item = false
	for item, count in pairs(recipe.input) do
		local group = item:match("^group:(.+)$")
		if group then
			table.insert(all_items, get_items_in_group(group))
			has_group_item = true
		else
			table.insert(all_items, {ItemStack(item):get_name()})
		end
		table.insert(item_counts, count)
	end
	if not has_group_item then
		local key = get_recipe_key(data.method, data.input)
		recipe_cache[key] = table.copy(recipe)
		return
	end
	for _,items in pairs(get_recipe_variants(all_items)) do
		local key = get_recipe_key(data.method, items)
		-- Non-group recipes take priority over group recipes
		if not has_group_item or not recipe_cache[key] then
			local input = {}
			for i, item in ipairs(items) do
				input[item] = item_counts[i]
			end
			recipe_cache[key] = {
				time = data.time,
				input = input,
				output = table.copy(recipe.output),
			}
		end
	end
end

local function cache_all_recipes()
	-- Cache built in cooking recipes
	for item in pairs(core.registered_items) do
		local recipes = core.get_all_craft_recipes(item)
		for _,recipe in ipairs(recipes or {}) do
			if recipe.method == "cooking" then
				local result, new_input = core.get_craft_result(recipe)
				if result and result.time > 0 then
					local data = {
						method = "cooking",
						time = result.time,
						input = recipe.items,
						output = {result.item:to_string()},
					}
					local replacement = new_input.items[1]
					if not replacement:is_empty() then
						data.output[2] = replacement:to_string()
					end
					cache_recipe(data)
				end
			end
		end
	end
	-- Cache custom recipes
	for _, data in pairs(temp_recipes) do
		if not data.hidden then
			add_to_craftguides(data)
		end
		cache_recipe(data)
	end
	temp_recipes = nil
end

-- Slightly hacky way to be the first function called
table.insert(core.registered_on_mods_loaded, 1, cache_all_recipes)
core.callback_origins[cache_all_recipes] = {
	mod = "technic",
	name = "register_on_mods_loaded",
}
