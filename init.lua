xp = {}
xp.lvl = 2
xp.xp_hud = {}
xp.level_hud = {}
xp.custom_level_system = false
xp.optDependencies={}
function xp.set_level_hud_text(player, str)
	player:hud_change(xp.level_hud[player:get_player_name()], "text", str)
end

function xp.getXp(player)
	return tonumber(player:get_attribute('xp'))
end

function xp.getXpPoints(player)
	return tonumber(player:get_attribute('xpPoints'))
end

function xp.getLvl(player)
	return tonumber(player:get_attribute('lvl'))
end

function xp.get_xp(lvl, x)
	return (xp.lvl * lvl) / x
end

function xp.updHudbars(player)
	if xp.optDependencies["hudbars"] then 
		hb.change_hudbar(player,'xp',xp.getXp(player),xp.lvl^(xp.getLvl(player)))
		print(tostring(xp.getXp(player) ..' / '..xp.lvl^(xp.getLvl(player)+1)))
	end
end

function xp.add_xp(player, num)
	player:set_attribute('xp',xp.getXp(player) + num)
	if xp.getXp(player) > xp.lvl ^ xp.getLvl(player) then
		player:set_attribute('xp', xp.getXp(player) - (xp.lvl ^ xp.getLvl(player)))
		xp.add_lvl(player)
	end
	print("[info] xp for player ".. player:get_player_name() .. " " .. xp.getXp(player).."/".. xp.lvl ^ xp.getLvl(player).." = " .. xp.getXp(player) / ( xp.lvl * xp.getLvl(player)))
	player:hud_change(xp.xp_hud[player:get_player_name()], "number", 20 * ((xp.getXp(player)) / (xp.lvl ^ xp.getLvl(player))))
end

function xp.add_xpPoints(player)
	player:set_attribute('xpPoints',xp.getXpPoints(player) + 1)
	

end

function xp.add_lvl(player)
	player:set_attribute('lvl',xp.getLvl(player) + 1)
	
	if not(xp.custom_level_system) then
		player:hud_change(xp.level_hud[player:get_player_name()], "text", xp.getLvl(player))
	end
end
function xp.optionalDependencies()
	local mods=minetest.get_modnames()
	print(dump(mods))
	local optionalDependencies = {}
	for index, value in pairs(mods) do
		if value == "hudbars" then 
			--print(true)
			optionalDependencies["hudbars"]=true
		end
	end
	xp.optDependencies = optionalDependencies
end
function xp.JoinPlayer()

	minetest.register_on_joinplayer(function(player)
		if not player then
			return
		end
		
		if not player:get_attribute('lvl')then
			player:set_attribute('xp', 0)
			player:set_attribute('lvl', 1)
			player:set_attribute('xpPoints', 1)
		end
		
		if xp.getXp(player) and xp.getLvl(player) then
			
			if xp.optDependencies["hudbars"] then
				hb.register_hudbar("xp", 0xFFFFFF, ("xp"), { bar = "xp.png", icon = "xp_icon.png", bgicon = "xp_bg_icon.png" }, xp.getXp(player), xp.lvl^(xp.getLvl(player)+1), false)
				hb.init_hudbar(player, "xp", xp.getXp(player), nil)
				print('hudbarsenabled')
			else
				xp.xp_hud[player:get_player_name()] = player:hud_add({
					hud_elem_type = "statbar",
					position = {x=0.5,y=1.0},
					size = {x=16, y=16},
					offset = {x=-(32*8+16), y=-(48*2+16)},
					text = "xp.png",
					number = 20*((xp.getXp(player))/(xp.lvl * xp.getLvl(player))),
				})
				xp.level_hud[player:get_player_name()] = player:hud_add({
					hud_elem_type = "text",
					position = {x=0.5,y=1},
					text = xp.getLvl(player),
					number = 0xFFFFFF,
					alignment = {x=0.5,y=1},
					offset = {x=0, y=-(48*2+16)},
				})
			end
		else
			print(tostring('something, somewhere is going wrong'))
		end
	end)
end

function xp.NewPlayer()
	minetest.register_on_newplayer(function(ObjectRef)
		ObjectRef:set_attribute('xp', 0)
		ObjectRef:set_attribute('lvl', 1)
		ObjectRef:set_attribute('xpPoints',1)
	end)
end

function xp.explorer_xp()
	minetest.register_on_generated(function(minp, maxp, blockseed)
		local center={x=minp.x+math.abs(minp.x-maxp.x),y=minp.y+math.abs(minp.y-maxp.y),z=minp.z+math.abs(minp.z-maxp.z)}
		local player=nil
		local top = nil
		for i,v in pairs(minetest.get_connected_players()) do
			local pos =v:getpos()
			local dist=vector.distance(center, pos)
			if player==nil then
				player = v
				top = dist
				
			elseif dist  < top then  
				top = dist
				player = v
			end
		end
		xp.add_xp(player, 1)
		xp.updHudbars(player)
	end) 
end

function xp.crafter_xp()
	minetest.register_on_craft(function(itemstack, player)
		local craft_xp = itemstack:get_definition().craft_xp
		if craft_xp then
			xp.add_xp(player, craft_xp)
			xp.updHudbars(player)
		end
	end)
end

function xp.miner_xp()
	minetest.register_on_dignode(function(pos, oldnode, digger)
		local miner_xp = minetest.registered_nodes[oldnode.name].miner_xp
		local player = digger:get_player_name()
		if miner_xp then 
			xp.add_xp(digger, miner_xp)
			xp.updHudbars(digger)
		end
	end)
end

function xp.builder_xp()
	minetest.register_on_placenode(function(pos, newnode, placer)
		local builder_xp = minetest.registered_nodes[newnode.name].builder_xp
		if builder_xp then
			xp.add_xp(placer, builder_xp)
			xp.updHudbars(placer)
		end
	end)
end

xp.optionalDependencies()

xp.NewPlayer()
xp.JoinPlayer()

xp.miner_xp()
xp.crafter_xp()
xp.explorer_xp()
xp.builder_xp()




