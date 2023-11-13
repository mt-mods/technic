
local have_ui = minetest.get_modpath("unified_inventory")
local have_cg = minetest.get_modpath("craftguide")
local have_i3 = minetest.get_modpath("i3")

technic.recipes = { cooking = { input_size = 1, output_size = 1 } }

function technic.register_recipe_type(typename, origdata)
	local data = table.copy(origdata)
	data.input_size = data.input_size or 1
	data.output_size = data.output_size or 1
	if have_ui and unified_inventory.register_craft_type then
		unified_inventory.register_craft_type(typename, {
			description = data.description,
			icon = data.icon,
			width = data.input_size,
			height = 1,
		})
	end
	if have_cg and craftguide.register_craft_type then
		craftguide.register_craft_type(typename, {
			description = data.description,
			icon = data.icon,
		})
	end
	if have_i3 then
		i3.register_craft_type(typename, {
			description = data.description,
			icon = data.icon,
		})
	end
	data.recipes = {}
	technic.recipes[typename] = data
end

local function get_recipe_index(items)
	if not items or type(items) ~= "table" then return false end
	local l = {}
	for i, stack in ipairs(items) do
		l[i] = ItemStack(stack):get_name()
	end
	table.sort(l)
	return table.concat(l, "/")
end

local function register_recipe(typename, data)
	-- Handle aliases
	for i, stack in ipairs(data.input) do
		data.input[i] = ItemStack(stack):to_string()
	end
	if type(data.output) == "table" then
		for i, v in ipairs(data.output) do
			data.output[i] = ItemStack(data.output[i]):to_string()
		end
	else
		data.output = ItemStack(data.output):to_string()
	end

	local recipe = {time = data.time, input = {}, output = data.output}
	local index = get_recipe_index(data.input)
	if not index then
		minetest.log("warning", "[Technic] ignored registration of garbage recipe!")
		return
	end
	for _, stack in ipairs(data.input) do
		recipe.input[ItemStack(stack):get_name()] = ItemStack(stack):get_count()
	end

	technic.recipes[typename].recipes[index] = recipe
	if data.hidden then return end

	local outputs = type(data.output) == "table" and data.output or {data.output}
	for _,output in ipairs(outputs) do
		if have_ui then
			unified_inventory.register_craft({
				type = typename,
				output = output,
				items = data.input,
				width = 0,
			})
		end
		if have_cg and craftguide.register_craft then
			craftguide.register_craft({
				type = typename,
				result = output,
				items = {table.concat(data.input, ", ")},
			})
		end
		if have_i3 then
			i3.register_craft({
				type = typename,
				result = output,
				items = {table.concat(data.input, ", ")},
			})
		end
	end
end

-- Checks for "zzzz_exchangeclone_crafthook" mod so that it won't crash with older versions of ExchangeClone which don't have it.
local has_exchangeclone = minetest.get_modpath("zzzz_exchangeclone_crafthook")

function technic.register_recipe(typename, data)
	if has_exchangeclone then
		exchangeclone.register_technic_recipe(typename, data)
	end
	minetest.after(0.01, register_recipe, typename, data) -- Handle aliases
end

function technic.get_recipe(typename, items)
	if typename == "cooking" then -- Already built into Minetest, so use that
		local result, new_input = minetest.get_craft_result({
			method = "cooking",
			width = 1,
			items = items,
		})
		-- Compatibility layer
		if not result or result.time == 0 then
			return
		-- Workaround for recipes with replacements
		elseif not new_input.items[1]:is_empty() and new_input.items[1]:get_name() ~= items[1]:get_name() then
			items[1]:take_item(1)
			return {
				time = result.time,
				new_input = {items[1]},
				output = {new_input.items[1], result.item}
			}
		else
			return {
				time = result.time,
				new_input = new_input.items,
				output = result.item
			}
		end
	end
	local index = get_recipe_index(items)
	if not index then return end

	local recipe = technic.recipes[typename].recipes[index]
	if recipe then
		local new_input = {}
		for i, stack in ipairs(items) do
			if stack:get_count() < recipe.input[stack:get_name()] then
				return
			else
				new_input[i] = ItemStack(stack)
				new_input[i]:take_item(recipe.input[stack:get_name()])
			end
		end
		return {
			time = recipe.time,
			new_input = new_input,
			output = recipe.output
		}
	else
		return
	end
end
