return {
	PlaceObj("ModItemOptionToggle", {
		"name", "Enabled",
		"DisplayName", Untranslated("Enable Skeleton Crew"),
		"Help", Untranslated("Master switch. Off = no upgrade is added."),
		"DefaultValue", true,
	}),
	PlaceObj("ModItemOptionNumber", {
		"name", "AutoPerformance",
		"DisplayName", Untranslated("Unmanned performance"),
		"Help", Untranslated("Performance while running with no Colonists. Default 50. Crewed shifts still use worker performance if it is higher."),
		"DefaultValue", 50,
		"MinValue", 10,
		"MaxValue", 100,
	}),
	PlaceObj("ModItemOptionNumber", {
		"name", "CostMetals",
		"DisplayName", Untranslated("Upgrade cost: Metals"),
		"Help", Untranslated("Metals required to build the upgrade. Default 50. Exotic Minerals are never used."),
		"DefaultValue", 50,
		"MinValue", 0,
		"MaxValue", 200,
	}),
	PlaceObj("ModItemOptionNumber", {
		"name", "CostElectronics",
		"DisplayName", Untranslated("Upgrade cost: Electronics"),
		"Help", Untranslated("Electronics required to build the upgrade. Default 20."),
		"DefaultValue", 20,
		"MinValue", 0,
		"MaxValue", 200,
	}),
	PlaceObj("ModItemOptionNumber", {
		"name", "CostMachineParts",
		"DisplayName", Untranslated("Upgrade cost: Machine Parts"),
		"Help", Untranslated("Machine Parts required to build the upgrade. Default 20."),
		"DefaultValue", 20,
		"MinValue", 0,
		"MaxValue", 200,
	}),
	PlaceObj("ModItemCode", {
		"name", "Script",
		"CodeFileName", "Code/Script.lua",
	}),
}
