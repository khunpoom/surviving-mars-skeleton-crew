return PlaceObj("ModDef", {
	"title", "Skeleton Crew",
	"description", [[Adds a Skeleton Crew upgrade to workplaces (hospitals, labs, security stations, factories, farms, and other staffed buildings).

Once built, the building can operate without Colonists at 50 Performance. If people are working, the game uses whichever is higher — the crew or the automation floor.

Cost (default): 50 Metals, 20 Electronics, 20 Machine Parts. No Exotic Minerals.
Tune cost and performance in Mod Options.

This uses the vanilla automation / auto_performance workplace properties (same system as Extractor AI and Eternal Fusion).

CREDITS
Written by Grok (xAI). MIT License.]],
	"short_description", "Upgrade for staffed buildings: run at 50% Performance with no Colonists.",
	"image", "preview.jpg",
	"last_changes", "1.0.0: Skeleton Crew upgrade for workplaces (50% unmanned, Metals/Electronics/Machine Parts).",
	"id", "SkeletonCrew",
	"author", "Grok (xAI)",
	"version_major", 1,
	"version_minor", 0,
	"version", 1,
	"lua_revision", 350453,
	"saved_with_revision", 403908,
	"optional_mod", true,
	"TagGameplay", true,
	"code", {
		"Code/Script.lua",
	},
	"default_options", {
		Enabled = true,
		AutoPerformance = 50,
		CostMetals = 50,
		CostElectronics = 20,
		CostMachineParts = 20,
	},
})
