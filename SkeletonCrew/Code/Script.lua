-- Skeleton Crew
-- Surviving Mars: Relaunched 1.1.x
-- Written by Grok (xAI). MIT License.
--
-- Adds a workplace upgrade that sets automation=1 and auto_performance=N
-- (vanilla Extractor AI / Eternal Fusion properties). See Workplace.lua.

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

local function IsWorkplaceTemplate(template)
	local mw = template.max_workers
	if type(mw) ~= "number" or mw < 1 then
		return false
	end
	local oc = template.object_class
	local classes = G("g_Classes")
	local IsKindOf = G("IsKindOf")
	if classes and oc and classes[oc] and IsKindOf then
		local ok, yes = pcall(IsKindOf, classes[oc], "Workplace")
		if ok then
			return yes
		end
	end
	return template.specialist ~= nil or (template.work_type or "") ~= ""
end

local function FindSlot(obj)
	local existing
	for i = 1, MAX_SLOTS do
		local id = obj["upgrade" .. i .. "_id"]
		if type(id) == "string" and id:find(UPGRADE_SUFFIX, 1, true) then
			existing = i
			break
		end
	end
	if existing then
		return existing
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
	obj[p .. "icon"] = "UI/IconsRemaster/Upgrades/automation_01.png"
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
	if not obj then
		return nil
	end
	local slot = FindSlot(obj)
	if not slot then
		return nil
	end
	local upgrade_id = (template_id or obj.template_name or obj.id or "Building") .. UPGRADE_SUFFIX
	WriteUpgrade(obj, slot, upgrade_id, perf, metals, electronics, parts)
	return upgrade_id
end

local function PatchAll()
	if not OptBool("Enabled", DEFAULTS.Enabled) then
		Log("disabled")
		return {}
	end
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

	local ids = {}
	local n = 0
	EachBuildingTemplate(function(id, template)
		if not IsWorkplaceTemplate(template) then
			return
		end
		local upgrade_id = PatchObj(template, id, perf, metals, electronics, parts)
		if upgrade_id then
			ids[#ids + 1] = upgrade_id
			n = n + 1
		end
	end)

	local maps = G("LoadedMaps")
	if type(maps) == "table" then
		for _, map in ipairs(maps) do
			if map and map.MapForEach then
				pcall(map.MapForEach, map, true, "Workplace", function(bld)
					local tid = bld.template_name or bld.entity
					PatchObj(bld, tid, perf, metals, electronics, parts)
				end)
			end
		end
	end

	Log("patched", n, "workplace templates, perf", perf)
	return ids
end

local function UnlockIds(ids)
	local Unlock = G("UnlockUpgrade")
	local colony = G("UIColony")
	for i = 1, #(ids or {}) do
		local id = ids[i]
		if Unlock then
			pcall(Unlock, id)
		elseif colony and colony.UnlockUpgrade then
			pcall(colony.UnlockUpgrade, colony, id)
		end
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

Log("loaded")
