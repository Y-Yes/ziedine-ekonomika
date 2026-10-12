## Pipeline
##
## Static definition of the circular-economy life-cycle stations that make up
## the ring. A token travels through every stage and each station transforms the
## token into its next form.
class_name Pipeline
extends RefCounted

# Ordered stages around the ring (clockwise, starting at the top).
# "hex" is the accent color used for the station and the token form.
const STAGES := [
	{"id": "user",    "lt": "Naudotojas",  "en": "User",       "short": "N", "hex": "e0575a"},
	{"id": "collect", "lt": "Surinkimas",  "en": "Collection", "short": "S", "hex": "e0913a"},
	{"id": "sort",    "lt": "Rūšiavimas",  "en": "Sorting",    "short": "R", "hex": "d9c94a"},
	{"id": "recycle", "lt": "Perdirbimas", "en": "Recycling",  "short": "P", "hex": "5ac26e"},
	{"id": "factory", "lt": "Gamykla",     "en": "Factory",    "short": "G", "hex": "4a90e0"},
	{"id": "shop",    "lt": "Parduotuvė",  "en": "Shop",       "short": "D", "hex": "9a6ae0"},
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
