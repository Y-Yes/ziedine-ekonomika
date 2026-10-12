## Pipeline
##
## Static definition of the circular-economy life-cycle stations that make up
## the ring. A token travels through every stage and each station transforms the
## token into its next form and adds value to it (value chain).
class_name Pipeline
extends RefCounted

# Ordered stages around the ring (clockwise, starting at the top).
# "hex"   – accent color used for the station and the token form
# "value" – € of added value per item at upgrade level 1
# "up_*"  – names of the three purchasable upgrades
# "fact"  – short educational fact shown in the upgrade panel
const STAGES := [
	{"id": "user", "lt": "Naudotojas", "en": "User", "short": "N", "hex": "e0575a", "value": 1.0,
		"up_speed": "Taromatai", "up_cap": "Rūšiavimo dėžės namuose", "up_value": "Užstato premija",
		"fact": "Žiedinė ekonomika prasideda nuo vartotojo: kuo geriau atliekos atskiriamos namuose, tuo jos vertingesnės."},
	{"id": "collect", "lt": "Surinkimas", "en": "Collection", "short": "S", "hex": "e0913a", "value": 1.0,
		"up_speed": "Naujas šiukšliavežis", "up_cap": "Didesni konteineriai", "up_value": "Atskiras surinkimas",
		"fact": "Lietuvoje nuo 2016 m. veikia taros užstato sistema – grąžinus butelį ar skardinę, atgaunamas užstatas."},
	{"id": "sort", "lt": "Rūšiavimas", "en": "Sorting", "short": "R", "hex": "d9c94a", "value": 1.0,
		"up_speed": "Rūšiavimo robotas", "up_cap": "Buferinė aikštelė", "up_value": "Tikslesnis rūšiavimas",
		"fact": "Švariai išrūšiuota žaliava parduodama brangiau – užteršta medžiaga praranda vertę."},
	{"id": "recycle", "lt": "Perdirbimas", "en": "Recycling", "short": "P", "hex": "5ac26e", "value": 2.0,
		"up_speed": "Granuliatorius", "up_cap": "Žaliavų silosas", "up_value": "Aukštesnė kokybė",
		"fact": "Antrinė žaliava pakeičia pirminę: reikia mažiau iškasenų, energijos ir išmetama mažiau CO2."},
	{"id": "factory", "lt": "Gamykla", "en": "Factory", "short": "G", "hex": "4a90e0", "value": 2.0,
		"up_speed": "Gamybos linija", "up_cap": "Žaliavų sandėlis", "up_value": "Eko dizainas",
		"fact": "Eko dizainas – produktas kuriamas taip, kad jį būtų lengva taisyti, naudoti ilgiau ir perdirbti."},
	{"id": "shop", "lt": "Parduotuvė", "en": "Shop", "short": "D", "hex": "9a6ae0", "value": 3.0,
		"up_speed": "Savitarnos kasos", "up_cap": "Prekių sandėlis", "up_value": "Rinkodara",
		"fact": "Pardavus produktą sukurta vertė virsta pajamomis, o daiktas vėl keliauja pas naudotoją."},
]

## Number of stages on the ring.
static func count() -> int:
	return STAGES.size()

## Wrap an arbitrary stage index into the valid range.
static func norm(i: int) -> int:
	var n := count()
	return ((i % n) + n) % n

## Stage dictionary for a (possibly out-of-range) index.
static func stage(i: int) -> Dictionary:
	return STAGES[norm(i)]

## Accent color for a stage index.
static func color_of(i: int) -> Color:
	return Color(STAGES[norm(i)]["hex"])

## Localized (Lithuanian by default) display name for a stage index.
static func name_of(i: int, lithuanian: bool = true) -> String:
	var s: Dictionary = STAGES[norm(i)]
	return s["lt"] if lithuanian else s["en"]

## Short single-letter tag for a stage index.
static func short_of(i: int) -> String:
	return STAGES[norm(i)]["short"]

## Base value (€) a stage adds to an item.
static func base_value(i: int) -> float:
	return float(STAGES[norm(i)]["value"])

## Name of upgrade `kind` ("speed" | "cap" | "value") at stage i.
static func upgrade_name(i: int, kind: String) -> String:
	return str(STAGES[norm(i)]["up_" + kind])

static func fact_of(i: int) -> String:
	return str(STAGES[norm(i)]["fact"])
