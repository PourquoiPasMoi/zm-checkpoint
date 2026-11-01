-- Starting loadout lobby options: up to two starting weapons and random perks.
-- Weapon lists come from each stock map's include_weapon calls (wall buys and
-- Mystery Box guns). Upgraded versions, melee, grenades, equipment, buildables
-- and map-quest weapons are left out. GSC validates every choice again.
local C = CoD.ZMCheckpointMenu

local names = {
	python = "PYTHON", judge = "EXECUTIONER", kard = "KAP-40", fiveseven = "FIVE-SEVEN",
	beretta93r = "B23R", fivesevendw = "FIVE-SEVEN DW", ak74u = "AK74U", mp5k = "MP5",
	qcw05 = "CHICOM CQB", ["870mcs"] = "REMINGTON 870", rottweil72 = "OLYMPIA", saiga12 = "S12",
	srm1216 = "M1216", m14 = "M14", saritch = "SMR", m16 = "M16", xm8 = "XM8", type95 = "TYPE 25",
	tar21 = "MTAR", galil = "GALIL", fnfal = "FAL", dsr50 = "DSR 50", barretm82 = "BARRETT M82A1",
	rpd = "RPD", hamr = "HAMR", usrpg = "RPG", m32 = "WAR MACHINE", hk416 = "M27", lsat = "LSAT",
	ray_gun = "RAY GUN", raygun_mark2 = "RAY GUN MK II", svu = "SVU-AS", pdw57 = "PDW-57",
	an94 = "AN-94", rnma = "REMINGTON NMA", uzi = "UZI", thompson = "THOMPSON", ak47 = "AK-47",
	blundergat = "BLUNDERGAT", mg08 = "MG08/15", mp44 = "STG-44", scar = "SCAR-H", ksg = "KSG",
	ak74u_extclip = "AK74U EXT CLIP", mp40 = "MP40", mp40_stalker = "MP40 STALKER",
	evoskorpion = "SKORPION EVO", ballista = "BALLISTA", beretta93r_extclip = "B23R EXT CLIP", c96 = "MAUSER C96"
}

local core = { "python", "judge", "kard", "fiveseven", "beretta93r", "fivesevendw", "ak74u", "mp5k", "qcw05",
	"870mcs", "rottweil72", "saiga12", "srm1216", "m14", "saritch", "m16", "xm8", "type95", "tar21", "galil",
	"fnfal", "dsr50", "barretm82", "rpd", "hamr", "usrpg", "m32", "ray_gun", "raygun_mark2" }

local function without( list, drop )
	local out = {}
	for _, key in ipairs( list ) do
		if not drop[key] then out[#out + 1] = key end
	end
	return out
end

local function with( list, add )
	local out = {}
	for _, key in ipairs( list ) do out[#out + 1] = key end
	for _, key in ipairs( add ) do out[#out + 1] = key end
	return out
end

C.LoadoutMaps = {
	zm_nuked = with( core, { "hk416", "lsat" } ),
	zm_transit = core,
	zm_highrise = with( without( core, {} ), { "svu", "pdw57", "an94" } ),
	zm_buried = with( without( core, { xm8 = true, type95 = true, rpd = true } ), { "rnma", "svu", "lsat", "pdw57", "an94" } ),
	zm_prison = { "judge", "beretta93r", "fivesevendw", "uzi", "thompson", "870mcs", "mp5k", "pdw57", "saiga12",
		"rottweil72", "m14", "ak47", "tar21", "galil", "fnfal", "dsr50", "barretm82", "lsat", "usrpg",
		"ray_gun", "raygun_mark2", "blundergat" },
	zm_tomb = { "hamr", "mg08", "type95", "galil", "fnfal", "m14", "mp44", "scar", "870mcs", "ksg", "srm1216",
		"ak74u", "ak74u_extclip", "pdw57", "thompson", "qcw05", "mp40", "mp40_stalker", "evoskorpion",
		"ballista", "dsr50", "beretta93r", "beretta93r_extclip", "kard", "fiveseven", "python", "c96",
		"fivesevendw", "m32", "ray_gun", "raygun_mark2" }
}

C.LoadoutNone = "none"
C.LoadoutPerkMax = 4

-- Choices for the current map: { { value = "python_zm", label = "PYTHON" }, ... }
C.LoadoutWeapons = function ( map )
	local out = { { value = C.LoadoutNone, label = "NONE" } }
	for _, key in ipairs( C.LoadoutMaps[map] or {} ) do
		out[#out + 1] = { value = key .. "_zm", label = names[key] or string.upper( key ) }
	end
	return out
end

C.LoadoutWeaponDvars = { "zmcp_start_weapon1", "zmcp_start_weapon2" }

-- Rebuilds the weapon rows for the map being shown and clears a stored choice
-- that does not exist on it, so the row and the dvar never disagree.
C.RefreshLoadoutOptions = function ( map )
	local choices = C.LoadoutWeapons( map )
	local valid = {}
	for _, choice in ipairs( choices ) do valid[choice.value] = true end
	for _, option in ipairs( CoD.PrivateGameLobby.Dvars ) do
		for _, dvar in ipairs( C.LoadoutWeaponDvars ) do
			if option.id == dvar then
				option.labels, option.values = {}, {}
				for i, choice in ipairs( choices ) do
					option.labels[i], option.values[i] = choice.label, choice.value
				end
			end
		end
	end
	for _, dvar in ipairs( C.LoadoutWeaponDvars ) do
		local current = C.DvarString( dvar )
		if current == "" or not valid[current] then Engine.SetDvar( dvar, C.LoadoutNone ) end
	end
	local perks = tonumber( C.DvarString( "zmcp_start_perks" ) )
	if perks == nil or perks < 0 or perks > C.LoadoutPerkMax or perks ~= math.floor( perks ) then
		Engine.SetDvar( "zmcp_start_perks", 0 )
	end
end
