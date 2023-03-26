ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

    for k,v in pairs(AutoSellerConfig.vend) do
        ESX.RegisterUsableItem(""..k.."", function(source)
            local src = source
            local xPlayer = ESX.GetPlayerFromId(src)
            TriggerClientEvent("rw_autoseller:bulder",src,k)
        end)
    end

end)


RegisterServerEvent('rw_autoseller:removeitem')
AddEventHandler('rw_autoseller:removeitem', function(src,item)
	 xPlayer = ESX.GetPlayerFromId(src)
     xPlayer.removeInventoryItem(item, 1)
end)
RegisterServerEvent('rw_autoseller:additem')
AddEventHandler('rw_autoseller:additem', function(src,item)
    -- print(src,item)
	 xPlayer = ESX.GetPlayerFromId(src)
     xPlayer.addInventoryItem(item, 1)
end)
