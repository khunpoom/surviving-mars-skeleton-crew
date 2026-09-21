-- Skeleton Crew
-- Surviving Mars: Relaunched 1.1.x
-- Written by Grok (xAI). MIT License.
--
-- Adds a workplace upgrade that sets automation=1 and auto_performance=N
-- (vanilla Extractor AI / Eternal Fusion properties). See Workplace.lua.
-- Infopanel shows an upgrade only if the BUILDING INSTANCE has upgradeN_id
-- and UIColony:IsUpgradeUnlocked(id) — so we patch templates, generated
-- classes, and live objects, then unlock.

local MOD_TAG = "[SkeletonCrew]"
local UPGRADE_SUFFIX = "_SkeletonCrew"
local MAX_SLOTS = 6

local DEFAULTS = {
	Enabled = true,
	AutoPerformance = 50,
	CostMetals = 50,
	CostElectronics = 20,
	CostMachineParts = 20,
}

-- Factories / grocers / stores already have Breakthrough upgrades for this.
local EXCLUDE_IDS = {
	ElectronicsFactory = true,
	ElectronicsFactory_Small = true,
	MachinePartsFactory = true,
	MachinePartsFactory_Small = true,
	PolymerPlant = true,
	FuelFactory = true,
	DroneFactory = true,
	MetalsRefinery = true,
	RareMetalsRefinery = true,
	ConcretePlant = true,
	ShopsFood = true,
	ShopsFood_Small = true,
	ShopsElectronics = true,
	ShopsJewelry = true,
	ShopsJewelry_Small = true,
	MegaMall = true,
}

local INCLUDE_IDS = {
	Infirmary = true,
	MedicalCenter = true,
	HospitalCCP1 = true,
	MedicalPostCCP1 = true,
	Sanatorium = true,
	ResearchLab = true,
	ScienceInstitute = true,
	LowGLab = true,
	SecurityStation = true,
	SecurityPostCCP1 = true,
	SecretPolice = true,
}

local INCLUDE_LABELS = {
	MedicalBuilding = true,
	ResearchBuildings = true,
	SecurityBuildings = true,
}

local INCLUDE_CATEGORIES = {
	MedicalStations = true,
	ResearchLabs = true,
	SecurityStations = true,
}

local function G(name)
	return rawget(_G, name)
end

local function Log(...)
	print(MOD_TAG, ...)
end

local function OptRaw(name)
	local opts = G("CurrentModOptions")
	if not opts then
		return nil
	end
	if opts.GetProperty then
		local ok, v = pcall(opts.GetProperty, opts, name)
		if ok then
			return v
		end
	end
	return opts[name]
end

local function OptBool(name, default)
	local v = OptRaw(name)
	if v == nil then
		return default
	end
	if v == true or v == 1 or v == "true" or v == "True" or v == "1" then
		return true
	end
	if v == false or v == 0 or v == "false" or v == "False" or v == "0" then
		return false
	end
	return not not v
end

local function OptNum(name, default)
	local v = tonumber(OptRaw(name))
	if not v then
		return default
	end
	return v
end

local function UnT(text)
	local un = G("Untranslated")
	if un then
		return un(text)
	end
	return text
end

local function ResourceScale()
	local c = G("const")
	if c and c.ResourceScale then
		return c.ResourceScale
	end
	return 1000
end

local function IsOurId(id)
	return type(id) == "string" and string.find(id, UPGRADE_SUFFIX, 1, true) and true or false
end

local function HasOtherAutomationUpgrade(template)
	for i = 1, MAX_SLOTS do
		local uid = template["upgrade" .. i .. "_id"]
		if uid and uid ~= "" and not IsOurId(uid) then
			for s = 1, 3 do
				if template["upgrade" .. i .. "_mod_prop_id_" .. s] == "automation" then
					return true
				end
			end
		end
	end
	return false
end

local function IsFactoryOrShop(id, template)
	if EXCLUDE_IDS[id] then
		return true
	end
	if type(id) == "string" then
		if string.find(id, "Factory", 1, true) or string.find(id, "Shops", 1, true) then
			return true
		end
	end
	local cat = template.build_category or ""
	if string.find(cat, "Factor", 1, true) or string.find(cat, "Shop", 1, true) then
		return true
	end
	return false
end

local function ShouldInclude(id, template)
	if type(template) ~= "table" or type(id) ~= "string" then
		return false
	end
	if IsFactoryOrShop(id, template) then
		return false
	end
	if HasOtherAutomationUpgrade(template) then
		return false
	end
	local mw = template.max_workers
	if type(mw) ~= "number" or mw < 1 then
		return false
	end
	if INCLUDE_IDS[id] then
		return true
	end
	if INCLUDE_CATEGORIES[template.build_category or ""] then
		return true
	end
	for _, key in ipairs({ "label1", "label2", "label3", "label4", "label5" }) do
		if INCLUDE_LABELS[template[key]] then
			return true
		end
	end
	return false
end

local function FindSlot(obj)
	for i = 1, MAX_SLOTS do
		if IsOurId(obj["upgrade" .. i .. "_id"]) then
			return i
		end
	end
	for i = 1, MAX_SLOTS do
		local id = obj["upgrade" .. i .. "_id"]
		if not id or id == "" then
			return i
		end
	end
	return nil
end

local function WriteUpgrade(obj, slot, upgrade_id, perf, metals, electronics, parts)
	local p = "upgrade" .. slot .. "_"
	obj[p .. "id"] = upgrade_id
	obj[p .. "display_name"] = UnT("Skeleton Crew")
	obj[p .. "description"] = UnT("This building can operate without Colonists at " .. tostring(perf) .. " Performance. Occupied shifts still use worker performance if it is higher.")
	obj[p .. "icon"] = "UI/IconsRemaster/Upgrades/autoregulator_01.png"
	obj[p .. "can_disable"] = true
	obj[p .. "mod_target_1"] = "self"
	obj[p .. "mod_label_1"] = ""
	obj[p .. "mod_prop_id_1"] = "automation"
	obj[p .. "add_value_1"] = 1
	obj[p .. "mul_value_1"] = 0
	obj[p .. "mod_target_2"] = "self"
	obj[p .. "mod_label_2"] = ""
	obj[p .. "mod_prop_id_2"] = "auto_performance"
	obj[p .. "add_value_2"] = perf
	obj[p .. "mul_value_2"] = 0
	local scale = ResourceScale()
	obj[p .. "upgrade_cost_Metals"] = metals * scale
	obj[p .. "upgrade_cost_Electronics"] = electronics * scale
	obj[p .. "upgrade_cost_MachineParts"] = parts * scale
	obj[p .. "upgrade_cost_PreciousMinerals"] = 0
end

local function ClearOurUpgrade(obj)
	if type(obj) ~= "table" then
		return
	end
	for i = 1, MAX_SLOTS do
		local p = "upgrade" .. i .. "_"
		if IsOurId(obj[p .. "id"]) then
			obj[p .. "id"] = ""
			obj[p .. "display_name"] = UnT("")
			obj[p .. "description"] = UnT("")
			obj[p .. "icon"] = ""
			obj[p .. "mod_prop_id_1"] = ""
			obj[p .. "mod_prop_id_2"] = ""
			obj[p .. "add_value_1"] = 0
			obj[p .. "add_value_2"] = 0
			obj[p .. "upgrade_cost_Metals"] = 0
			obj[p .. "upgrade_cost_Electronics"] = 0
			obj[p .. "upgrade_cost_MachineParts"] = 0
		end
	end
end

local function EachBuildingTemplate(fn)
	local seen = {}
	local function hit(id, template)
		if type(id) == "string" and type(template) == "table" and not seen[id] then
			seen[id] = true
			fn(id, template)
		end
	end
	local bt = G("BuildingTemplates")
	if type(bt) == "table" then
		for id, template in pairs(bt) do
			hit(id, template)
		end
	end
	local ct = G("ClassTemplates")
	if type(ct) == "table" and type(ct.Building) == "table" then
		for id, template in pairs(ct.Building) do
			hit(id, template)
		end
	end
end

local function PatchObj(obj, template_id, perf, metals, electronics, parts)
	if type(obj) ~= "table" then
		return nil
	end
	local slot = FindSlot(obj)
	if not slot then
		return nil
	end
	local upgrade_id = (template_id or obj.template_name or obj.id or "Building") .. UPGRADE_SUFFIX
	WriteUpgrade(obj, slot, upgrade_id, perf, metals, electronics, parts)
	return upgrade_id, slot
end

local function PatchClass(id, perf, metals, electronics, parts)
	local classes = G("g_Classes")
	local cls = classes and classes[id]
	if type(cls) == "table" then
		return PatchObj(cls, id, perf, metals, electronics, parts)
	end
end

local function ForEachLiveWorkplace(fn)
	local maps = G("LoadedMaps")
	if type(maps) == "table" then
		for _, map in ipairs(maps) do
			if map and map.MapForEach then
				pcall(function()
					map:MapForEach(true, "Workplace", fn)
				end)
			end
		end
	end
	local cities = G("Cities")
	if type(cities) == "table" then
		for _, city in ipairs(cities) do
			local list = city and city.labels and city.labels.Workplace
			if type(list) == "table" then
				for _, bld in ipairs(list) do
					fn(bld)
				end
			end
		end
	end
end

local function GetCosts()
	local perf = math.floor(OptNum("AutoPerformance", DEFAULTS.AutoPerformance) + 0.5)
	if perf < 1 then
		perf = 1
	end
	local metals = math.floor(OptNum("CostMetals", DEFAULTS.CostMetals) + 0.5)
	local electronics = math.floor(OptNum("CostElectronics", DEFAULTS.CostElectronics) + 0.5)
	local parts = math.floor(OptNum("CostMachineParts", DEFAULTS.CostMachineParts) + 0.5)
	if metals < 0 then metals = 0 end
	if electronics < 0 then electronics = 0 end
	if parts < 0 then parts = 0 end
	return perf, metals, electronics, parts
end

local function PatchAll()
	if not OptBool("Enabled", DEFAULTS.Enabled) then
		Log("disabled")
		EachBuildingTemplate(function(_, template)
			ClearOurUpgrade(template)
		end)
		local classes = G("g_Classes")
		if type(classes) == "table" then
			for id in pairs(INCLUDE_IDS) do
				ClearOurUpgrade(classes[id])
			end
		end
		ForEachLiveWorkplace(ClearOurUpgrade)
		return {}
	end

	local perf, metals, electronics, parts = GetCosts()
	local ids = {}
	local names = {}

	EachBuildingTemplate(function(id, template)
		if ShouldInclude(id, template) then
			local upgrade_id, slot = PatchObj(template, id, perf, metals, electronics, parts)
			PatchClass(id, perf, metals, electronics, parts)
			if upgrade_id then
				ids[#ids + 1] = upgrade_id
				names[#names + 1] = id .. "#" .. tostring(slot)
			end
		else
			ClearOurUpgrade(template)
			local classes = G("g_Classes")
			if classes then
				ClearOurUpgrade(classes[id])
			end
		end
	end)

	ForEachLiveWorkplace(function(bld)
		local tid = bld.template_name or bld.class
		local bt = G("BuildingTemplates")
		local template = bt and bt[tid]
		if template and ShouldInclude(tid, template) then
			PatchObj(bld, tid, perf, metals, electronics, parts)
		else
			ClearOurUpgrade(bld)
		end
	end)

	Log("patched", table.concat(names, ", "), "perf", perf)
	return ids
end

local function UnlockIds(ids)
	local Unlock = G("UnlockUpgrade")
	local colony = G("UIColony")
	local n = 0
	for i = 1, #(ids or {}) do
		local id = ids[i]
		local ok = false
		if Unlock then
			ok = pcall(Unlock, id)
		end
		if (not ok) and colony and colony.UnlockUpgrade then
			pcall(colony.UnlockUpgrade, colony, id)
		end
		n = n + 1
	end
	if n > 0 then
		Log("unlocked", n, "upgrades")
	end
	local Rebuild = G("RebuildInfopanel")
	local sel = G("SelectedObj")
	if Rebuild and sel then
		pcall(Rebuild, sel)
	end
end

local last_ids = {}

local function Apply()
	last_ids = PatchAll()
	UnlockIds(last_ids)
end

function OnMsg.ClassesPostprocess()
	Apply()
end

function OnMsg.ModsReloaded()
	Apply()
end

function OnMsg.ApplyModOptions()
	Apply()
end

function OnMsg.NewMapLoaded()
	Apply()
end

function OnMsg.LoadGame()
	Apply()
end

function OnMsg.CityStart()
	Apply()
end

function OnMsg.InGameInterfaceCreated()
	Apply()
end

Log("loaded")
