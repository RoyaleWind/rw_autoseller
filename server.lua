ESX = nil
max = 20

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('rw_autoseller:force')
AddEventHandler('rw_autoseller:force', function()
	src = source
    stock = {}
	MySQL.Async.fetchAll('SELECT * FROM rw_autoseller ', {}, function(result)
		oldautosellers = result
		stock = {}
		for k,v in pairs(oldautosellers) do
			stock[v.id] = tablelength(json.decode(v.items))
		end	
		TriggerClientEvent("rw_autoseller:forceupdae",src,stock)
	end)
end)


RegisterServerEvent('rw_autoseller:update')
AddEventHandler('rw_autoseller:update', function()
	src = source
    stock = {}
	MySQL.Async.fetchAll('SELECT * FROM rw_autoseller ', {}, function(result)
		oldautosellers = result

		autosellers = {}
		stock = {}
		info = {}
		rot = {}
		owner = {}
		model = {}

		for k,v in pairs(oldautosellers) do
            autosellers[v.id] = vector3(v.x,v.y,v.z)
			stock[v.id] = tablelength(json.decode(v.items))
			rot[v.id] = v.r
			owner[v.id] = v.owner
			model[v.id] = v.model
		end	


		TriggerClientEvent("rw_autoseller:getAutoSellers",src,autosellers,stock,rot,owner,model)
	end)
end)

ESX.RegisterServerCallback('rw_autoseller:requestShopItemsNew', function(source, cb, job)
	MySQL.Async.fetchAll('SELECT * FROM rw_autoseller WHERE id = @id', { ['@id'] = job }, function(result)
		local old = result[1].items
		local items = {}
		items = json.decode(old)
		cb(items)
	end)
end)

ESX.RegisterServerCallback('rw_autoseller:CanPut', function(source, cb, job)

	MySQL.Async.fetchAll('SELECT * FROM rw_autoseller WHERE id = @id', { ['@id'] = job }, function(result)
		local old = result[1].items
		local items = {}
		items = json.decode(old)
		local live = tablelength(items)
		lib = {}
		lib.canPut = true
		lib.quantity = max - live
	
		cb(lib)
	end)


end)	


RegisterServerEvent('rw_autoseller:putStockItems')
AddEventHandler('rw_autoseller:putStockItems', function(itemName, count,job,price)
	src = source
	xPlayer = ESX.GetPlayerFromId(src)

	MySQL.Async.fetchAll('SELECT * FROM rw_autoseller WHERE id = @id', { ['@id'] = job }, function(result)
	  if result[1].items ~= "no" then
		local old = result[1].items
		local items = {}
		items = json.decode(old)
		local live = tablelength(items)

		if Check_item(items,itemName) == "EROR" then
		 items[live+1] = {}
		 items[live+1].count = count
		 items[live+1].name = itemName
		 items[live+1].price = price
		 newitems = json.encode(items)
		else 
		 	local pointer = Check_item(items,itemName)
		 	items[pointer].count = count + items[pointer].count  
			items[pointer].price = price
		 	newitems = json.encode(items)
		end	
        
		MySQL.Async.execute('UPDATE rw_autoseller SET items = @items WHERE id = @id',
		{ 
			['@items'] = newitems,
			['@id'] = job,
		})
		xPlayer.removeInventoryItem(itemName, count)
	  else
			local items = {}
			items[1] = {}
			items[1].count = count
			items[1].name = itemName
			items[1].price = price
			newitems = json.encode(items)
		MySQL.Async.execute('UPDATE rw_autoseller SET items = @items WHERE id = @id',
		{ 
			['@items'] = newitems,
			['@id'] = job,
		})
		xPlayer.removeInventoryItem(itemName, count)
	  end	
	end)

end)
function Check_item(T,name)
	for k,v in pairs(T) do
		if name == v.name then 
			return k
		end	
    end
	return "EROR"
end	
function tablelength(T)
	if T ~= nil then
	local count = 0
	for k,v in pairs(T) do
		 count = count + 1
	end
	return count
	else
		return 0
	end	
end
-------------------------------------------------------------------------------
RegisterServerEvent('rw_autoseller:buyItem')
AddEventHandler('rw_autoseller:buyItem', function(itemName, count,price,job)
	src = source 
	xPlayer = ESX.GetPlayerFromId(src)
	pay = price * count
	if xPlayer.getAccount('money').money >= pay then 
		xPlayer.removeAccountMoney('money', pay)
		xPlayer.addInventoryItem(itemName, count)
		buyitem(job,pay)
	MySQL.Async.fetchAll('SELECT * FROM rw_autoseller WHERE id = @id', { ['@id'] = job }, function(result)
		local old = result[1].items
		local items = {}
		items = json.decode(old)
		local pointer = Check_item(items,itemName)
		items[pointer].count = items[pointer].count - count
		newitems = json.encode(items)
		MySQL.Async.execute('UPDATE rw_autoseller SET items = @items WHERE id = @id',
		{ 
			['@items'] = newitems,
			['@id'] = job,
		})
	end)

	else 
		xPlayer.showNotification("YOU DO NOT HAVE THE MONEY")
	end		 
end)
----------------------------------------------------------------------

ESX.RegisterServerCallback('rw_autoseller:getmoney', function(source, cb, job)
	MySQL.Async.fetchAll('SELECT * FROM rw_autoseller WHERE id = @id', { ['@id'] = job }, function(result)
		old = result[1].cashery
		-- print(old)
		cb(old)
	end)
end)	
--------------------------------------
RegisterServerEvent('rw_autoseller:claim')
AddEventHandler('rw_autoseller:claim', function(job)
	src = source 
	xPlayer = ESX.GetPlayerFromId(src)

	MySQL.Async.fetchAll('SELECT * FROM rw_autoseller WHERE id = @id', { ['@id'] = job }, function(result)
		moneycolect = result[1].cashery
		MySQL.Async.execute('UPDATE rw_autoseller SET cashery = @cashery WHERE id = @id',
		{ 
			['@cashery'] = 0,
			['@id'] = job,
		})
		xPlayer.showNotification("YOU GOT [+"..moneycolect.."] TO YOUR BANK")
		xPlayer.addAccountMoney('bank', moneycolect)
	end)

 end)
 ------------------------------------------------------------------------
 function buyitem(job,money) 
	MySQL.Async.fetchAll('SELECT * FROM rw_autoseller WHERE id = @id', { ['@id'] = job }, function(result)
		moneycolect = result[1].cashery
		MySQL.Async.execute('UPDATE rw_autoseller SET cashery = @cashery WHERE id = @id',
		{ 
			['@cashery'] = moneycolect + money,
			['@id'] = job,
		})
	end)
end	
------------------------------------------------------------------------


RegisterServerEvent('rw_autoseller:make')
AddEventHandler('rw_autoseller:make', function(rota,model,x,y,z)
	local src = source
	local xplayer = ESX.GetPlayerFromId(src)
	-- local pos = xplayer.getCoords(true)

    TriggerEvent('rw_autoseller:removeitem',src,model)
	-- local model = AutoSellerConfig.vend[model]
	local model = model
    if xplayer ~= nil then 
	
		MySQL.Async.execute('INSERT INTO rw_autoseller (x,y,z,r,owner,model) VALUES (@x,@y,@z,@r,@owner,@model)',
		{
			['@x'] = x,
			['@y'] = y,
			['@z'] = z,
			['@r'] = rota,
			['@owner'] = xplayer.getIdentifier(),
			['@model'] = model,
		})
	
	else 
		
	end	
    Citizen.Wait(1000)
 -----------------------------
    
    stock = {}
	MySQL.Async.fetchAll('SELECT * FROM rw_autoseller ', {}, function(result)
		oldautosellers = result

		autosellers = {}
		stock = {}
		info = {}
		rot = {}
		owner = {}
		model = {}

		for k,v in pairs(oldautosellers) do
            autosellers[v.id] = vector3(v.x,v.y,v.z)
			stock[v.id] = tablelength(json.decode(v.items))
			rot[v.id] = v.r
			owner[v.id] = v.owner
			model[v.id] = v.model
		end	


		TriggerClientEvent("rw_autoseller:addobj",src,autosellers,stock,rot,owner,model)
	end)



end)

RegisterServerEvent('rw_autoseller:remove')
AddEventHandler('rw_autoseller:remove', function(job)
	local src = source
	modeldel = nil
	MySQL.Async.fetchAll('SELECT * FROM rw_autoseller WHERE id = @id', { ['@id'] = job }, function(result)
		modeldel = result[1].model
	end)
	Citizen.Wait(1000)

	TriggerEvent('rw_autoseller:additem',src,modeldel)

	MySQL.Async.execute('DELETE FROM rw_autoseller WHERE id = @id',
	{ 
			['@id'] = job,
	})
	for k,v in ipairs(ESX.GetPlayers()) do
        TriggerClientEvent('rw_autoseller:removeobj',v,job)
    end    


end)
