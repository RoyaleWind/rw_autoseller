ESX = nil

local announcing = false
local PlayerData = {}
local labels = {}
local rwobj = {}
local text
local zone
local closeToSellers = {}
local startedDrawLoop = {}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	
	Wait(5000)
	
	PlayerData = ESX.GetPlayerData()
	InitScript()
	while true do 
		Wait(10000)
		TriggerServerEvent("rw_autoseller:force")
	end	
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)


RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  	PlayerData = xPlayer
end)

function startDraw(seller_name,coords)
	-- print("startDraw:",seller_name)
	Rplayer = ESX.GetPlayerData().identifier
	if startedDrawLoop[seller_name] == nil then
		startedDrawLoop[seller_name] = true
		CreateThread(function()
			while closeToSellers[seller_name] and rwobj[seller_name] ~= nil do 
				local canDraw = true
	
				if canDraw then 
					local stock = sellersStock[seller_name] or 0

					if stock > #AutoSellerConfig.Stock then
						stock = #AutoSellerConfig.Stock
					elseif stock < 1 then
						stock = 1
					end
					local colour = AutoSellerConfig.Stock[stock].colour
					local top = 1.2
					local coordsz = vector3(coords.x,coords.y,coords.z + top)
					DrawMarker(20, coordsz, 0.0, 0.0, 0.0, 0, 180.0, 0.0, 0.5, 0.5, 0.5, colour.r, colour.g, colour.b, 100, true, false, 2, true, false, false, false)
					if #(GetEntityCoords(PlayerPedId()) - coords) < 1.2 then
						ESX.ShowHelpNotification('Press ~r~[E]~w~ to use the autoseller ['..seller_name..']')
						if IsControlJustReleased(0, 38) then
							if owners[seller_name] == Rplayer then
								OpenShopJobMenu(seller_name)
							else 
								OpenShopMenu(seller_name)
							end

						end
					end
				end
				Wait(0)
			end
			startedDrawLoop[seller_name] = nil
		end)
	end
end

function CreateObj(seller_name,coords)
	local space = 1
	local model = models[seller_name]
	local modelx = AutoSellerConfig.vend[model]
	coords = vector3(coords.x,coords.y,coords.z - space)
	local obj = CreateObject(modelx, coords,false,true)
	rwobj[seller_name] = obj
	local head = rotations[seller_name]
	SetEntityHeading(obj, head)
	-- x, y, z = table.unpack(GetEntityRotation(obj))
	-- print(x, y, z)
	-- SetEntityRotation(obj, x, y, 80)
	
	-- print(ESX.DumpTable(coords))
end


function InitScript()
    TriggerServerEvent("rw_autoseller:update")
end
RegisterNetEvent('rw_autoseller:getAutoSellers')
AddEventHandler('rw_autoseller:getAutoSellers', function(autosellers, stock,rot,owner,model)
	AutoSellerConfig.Shops = {}
	sellersStock = stock
	rotations = rot
	owners = owner
	models = model
		for k,v in pairs(autosellers) do
			if type(v) == "string" then
				v = load("return "..v)()
			end
			
			AutoSellerConfig.Shops[k] = v
		end
		CreateThread(function()
			for k,v in pairs(AutoSellerConfig.Shops) do
				CreateObj(k,v)
				Wait(30)
			end
			while true do 
				for k,v in pairs(AutoSellerConfig.Shops) do
					if #(GetEntityCoords(PlayerPedId()) - v) < 50.0 then
						closeToSellers[k] = true 
						startDraw(k,v)
					else
						closeToSellers[k] = nil 
					end
					Wait(30)
				end
			
				Wait(3000)
			end
		end)
	
end)

RegisterNetEvent('rw_autoseller:applychange')
AddEventHandler('rw_autoseller:applychange', function(job,coords,status)
	if status == 'create' then 

		if type(coords) == "string" then
			coords = load("return "..coords)()
		end
		
		AutoSellerConfig.Shops[job] = coords
	elseif status == 'delete' then 
		AutoSellerConfig.Shops[job] = nil
		closeToSellers[job] = nil 
	end
end)

RegisterCommand('checkstock', function(source, args)
	local job = ESX.GetPlayerData().identifier
	
	 ESX.TriggerServerCallback('rw_autoseller:requestShopItemsNew',function(result2)
	

		if result2[1] then
			local elements = {}
			
			for i=1,#result2,1 do
				if result2[i].count > 0 then
					
					local itemLabel = GetLabelOfItem(result2[i].name)
					
					table.insert(elements, {
						label = ('%s - <span style="color:green;">x%s</span> $%s'):format(itemLabel, result2[i].count,  ESX.Math.GroupDigits(result2[i].price)),
						name = result2[i].name,
						price = result2[i].price,
					})
				end
			end
			
			ESX.UI.Menu.CloseAll()
			
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop',
			{
				title    = "💲<font color = 'green'>Shop</font>💲",
				align    = 'bottom-right',
				elements = elements,
			},
			function(data, menu)
				menu.close()
			end,
			function(data, menu)
				menu.close()
			end)
		end
		
		result2 = nil
	 end, job, true)
end)

function OpenShopJobMenu(zone)
	local elements = {}
	local cash = 0
	table.insert(elements, {
		label = "Remove :🛍️",
		name = "remove",
	})
	table.insert(elements, {
		label = "Open restock menu",
		name = "restock",
	})
	table.insert(elements, {
		label = "Open shop menu",
		name = "shop",
	})


	ESX.TriggerServerCallback('rw_autoseller:getmoney',function(cash)
	--    print(cash)
		table.insert(elements, {
			label = "Collected:💲"..cash,
			name = "cashery",
		   })
	
	end, zone, true)


	Citizen.Wait(1000)
	ESX.UI.Menu.CloseAll()
	CreateThread(function()
		Wait(300)
		local startCoords = GetEntityCoords(PlayerPedId())
		while ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'shop') do
			if #(GetEntityCoords(PlayerPedId()) - startCoords) > 1.5 then 
				ESX.UI.Menu.CloseAll()
			end
			Wait(100)
		end
	end)
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop',
	{
		title    = "💲<font color = 'green'>Shop</font>💲",
		align    = 'bottom-right',
		elements = elements,
	},
	function(data, menu)
		if data.current.name == "shop" then
			OpenShopMenu(zone)
		elseif data.current.name == "restock" then
			OpenRestockMenu(zone)
			TriggerServerEvent("rw_autoseller:force")
		elseif data.current.name == "remove" then
			TriggerServerEvent("rw_autoseller:remove",zone)
		elseif data.current.name == "cashery" then
			TriggerServerEvent("rw_autoseller:claim",zone)
			menu.close()
		end
		menu.close()
	end,
	
	function(data, menu)
		menu.close()
	end)
end

function OpenShopMenu(job)
	ESX.TriggerServerCallback('rw_autoseller:requestShopItemsNew',function(result2)

		if result2[1] then
			local elements = {}
			for i=1,#result2,1 do
				if result2[i].count > 0 then
					local itemLabel = GetLabelOfItem(result2[i].name) or 'Invalid Item'
					table.insert(elements, {
						label = ('%s - <span style="color:green;">%s</span> (STOCK: %s)'):format(itemLabel, '$'..ESX.Math.GroupDigits(result2[i].price), result2[i].count),
						name = result2[i].name,
						price = result2[i].price,
					})
				end
			end
			if #elements > 0 then
				ESX.UI.Menu.CloseAll()
				CreateThread(function()
					Wait(300)
					local startCoords = GetEntityCoords(PlayerPedId())
					while ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'shop') do
						if #(GetEntityCoords(PlayerPedId()) - startCoords) > 1.5 then 
							ESX.UI.Menu.CloseAll()
						end
						Wait(100)
					end
				end)
				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop',
				{
					title    = "💲<font color = 'green'>Shop</font>💲",
					align    = 'bottom-right',
					elements = elements,
				},
				function(data, menu)
					local quantity = tonumber(exports['dialog']:Create('Enter quantity to buy!', 'Enter quantity').value)
					if quantity and quantity > 0 then
						local title = 'Buy x'..quantity..' '..GetLabelOfItem(data.current.name)..' for $'..ESX.Math.GroupDigits(data.current.price)
						if exports['dialog']:Decision(title, 'Are you sure?', '', 'YES', 'NO').action == 'submit' then
							TriggerServerEvent('rw_autoseller:buyItem', data.current.name, quantity, data.current.price, job)
							menu.close()
							Wait(1000)
							OpenShopMenu(job)
						end
					end
				end,
				
				function(data, menu)
					menu.close()
				end)
			else
				ESX.ShowNotification("THE AUTOSHELTER IS EMPTY ")
			end
		else
			ESX.ShowNotification('THE AUTOSHELTER IS EMPTY')
		end
		result2 = nil
	 end,job)
end

function OpenRestockMenu(job)
	ClearPedTasksImmediately(PlayerPedId())
	ESX.TriggerServerCallback('rw_autoseller:CanPut', function(result)
		if result.canPut then
			
			PlayerData = ESX.GetPlayerData()
			local elements = {}
	
			for k,item in pairs(PlayerData.inventory) do

				if item.count > 0 then
					table.insert(elements, {
						label = item.label .. ' x' .. item.count,
						type = 'item_standard',
						value = item.name
					})
				end
			end
	
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu',
			{
				title    = 'Inventory: Slots left: '..result.quantity,
				align    = 'bottom-right',
				elements = elements
			}, function(data, menu)
	
				local itemName = data.current.value
	
				ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
					title = 'Quantity'
				}, function(data2, menu2)
	
					local count = tonumber(data2.value)
	
					if count == nil  then
						ESX.ShowNotification('Invalid Quantity')
					elseif count > 0 then
						ESX.UI.Menu.CloseAll()
						local minprice = 1
			
						ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_price_one', {
							title = 'Price per Item ('..minprice..'$ Minimum price)'
						}, function(data3, menu3)
							local price = tonumber(data3.value)
							if price == nil or price <= 0 then
								ESX.ShowNotification('Invalid Price')
								ESX.UI.Menu.CloseAll()
							elseif price ~= nil and price >= minprice then
								TriggerServerEvent('rw_autoseller:putStockItems', itemName, count,job,price)
								ESX.UI.Menu.CloseAll()
							else
								ESX.ShowNotification('Invalid Price')
								ESX.UI.Menu.CloseAll()
							end
						end, function(data3, menu3)
							ESX.UI.Menu.CloseAll()
						end)
						Citizen.Wait(300)
						OpenRestockMenu(job)
					end
	
				end, function(data2, menu2)
					ESX.UI.Menu.CloseAll()
				end)
	
			end, function(data, menu)
				ESX.UI.Menu.CloseAll()
			end)
			
		else
			ESX.ShowNotification('Seller full. (1200 items limit)')
		end
	end, job)
end
-------------------------------------------


RegisterNetEvent('rw_autoseller:removeobj')
AddEventHandler('rw_autoseller:removeobj', function(id)
	-- print("remove"..id)
	DeleteObject(rwobj[id])
	rwobj[id] = nil
end)
RegisterNetEvent('rw_autoseller:addobj')
AddEventHandler('rw_autoseller:addobj', function(autosellers, stock,rot,owner,model)
	AutoSellerConfig.Shops = {}
	sellersStock = stock
	rotations = rot
	owners = owner
	models = model
	local new = nil
		for k,v in pairs(autosellers) do
			if type(v) == "string" then
				v = load("return "..v)()
			end
			
			AutoSellerConfig.Shops[k] = v
		end
	

		CreateThread(function()
			for k,v in pairs(AutoSellerConfig.Shops) do
				if rwobj[k] == nil then
					new = k
				 CreateObj(k,v)
				end
				Wait(30)
			end
            local cords = AutoSellerConfig.Shops[new]
			while true do 
					if #(GetEntityCoords(PlayerPedId()) - cords) < 50.0 then
						closeToSellers[new] = true 
						startDraw(new,cords)
					else
						closeToSellers[new] = nil 
					end
					Wait(30)

			
				Wait(3000)
			end
		end)
end)

RegisterNetEvent('rw_autoseller:bulder')
AddEventHandler('rw_autoseller:bulder', function(item)
	local selecting = true
	local noextrat = item
	local model = AutoSellerConfig.vend[noextrat]
	local loc = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 1.0, 0.0)
	local previw = CreateObject(model,loc,false,true)
	SetEntityAlpha(previw,100,true)
	SetEntityCompletelyDisableCollision(previw,false,false)
	while selecting do 
		Wait(0)
		
		local x,y,z = table.unpack(GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 1.0, 0.0))
		local rotate = GetEntityHeading(PlayerPedId())
		SetEntityCoords(previw,x,y,z)
		SetEntityHeading(previw, rotate)

		if IsPointOnRoad(x,y,z)then
			ESX.ShowHelpNotification('YOU CAN NOT PLACE IT HERE')
			DrawMarker(20, x,y,z+2, 0.0, 0.0, 0.0, 0, 180.0, 0.0, 0.5, 0.5, 0.5, 235, 12, 2, 100, true, false, 2, true, false, false, false)
		else	
			ESX.ShowHelpNotification('Press ~r~[ENTER]~w~ to secure the location ~g~[AT THE GREEN MARKER] ~w~ PRESS TO ~r~[X] ~w~ EXIT')
			DrawMarker(20, x,y,z+2, 0.0, 0.0, 0.0, 0, 180.0, 0.0, 0.5, 0.5, 0.5, 10, 235, 2, 100, true, false, 2, true, false, false, false)
		end	

		if IsControlJustReleased(0, 215) then ---endter
			if IsPointOnRoad(x,y,z) then
				ESX.ShowNotification("YOU CAN NOT PLACE IT HERE ")
			else	
			 selecting = false
			 TriggerServerEvent("rw_autoseller:make",rotate,noextrat,x,y,z)
			 DeleteObject(previw)
			end
		end
		if IsControlJustReleased(0, 154) then  --- X
			selecting = false
			DeleteObject(previw)
		end
	end	
end)


RegisterNetEvent('rw_autoseller:forceupdae')
AddEventHandler('rw_autoseller:forceupdae', function(stock)
	sellersStock = stock
end)
--------------------------------------------------------------------------------------
function GetLabelOfItem(item)

if AutoSellerConfig.label then
	local x = ESX.GetItemLabel(item)
else	
	local x = item
end	

return(x) 
end