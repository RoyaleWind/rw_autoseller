AutoSellerConfig = {}

--  set it to true if you have ESX.GetItemLabel(item) in your esx
AutoSellerConfig.label = false

AutoSellerConfig.Stock = {
	{stock = 0, colour = {r = 250, g = 0, b = 0}},
	{stock = 4, colour = {r = 235, g = 103, b = 2}},
	{stock = 1000, colour = {r = 10, g = 235, b = 2}},
}
-----------------------------------------------------

-- ['itemname'] = "propname",
AutoSellerConfig.vend = {
	['vend_cola'] = "prop_vend_soda_01",
	['vend_sprite'] = "prop_vend_soda_02",
	['vend_coffe'] = "prop_vend_coffe_01",
	['vend_snak'] = "prop_vend_snak_01",
	['vend_water'] = "prop_vend_water_01",
}