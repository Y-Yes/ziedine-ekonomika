## Glossary
##
## Economics terms that pop up the first time the matching thing happens in
## the game, and are listed in the pause menu.
class_name Glossary
extends RefCounted

const TERMS := [
	{"id": "value_added",
		"lt": ["Pridėtinė vertė", "Vertė, kurią kiekvienas gamybos etapas prideda produktui. Galutinė kaina – tai visų etapų pridėtinių verčių suma."],
		"en": ["Value added", "The value each production stage adds to a product. The final price is the sum of the value added at every stage."]},
	{"id": "pigou",
		"lt": ["Pigou mokestis", "Mokestis už veiklą, kuri kenkia kitiems, pvz., taršą. Įmonė „sumoka“ už padarytą žalą, todėl jai apsimoka teršti mažiau. Žaidime – sąvartyno mokestis."],
		"en": ["Pigouvian tax", "A tax on activities that harm others, like pollution. The company pays for the damage, so polluting less pays off. In the game – the landfill tax."]},
	{"id": "externality",
		"lt": ["Neigiamas išorinis poveikis", "Žala, kurią įmonė padaro kitiems, bet už ją pati nemoka, pvz., užterštas oras. Žaidime tarša mažina kainas ir sukelia nelaimes visiems."],
		"en": ["Negative externality", "Harm a company causes to others without paying for it, e.g. polluted air. In the game pollution lowers prices and causes disasters for everyone."]},
	{"id": "linear",
		"lt": ["Linijinė ekonomika", "Modelis „paimk – pagamink – išmesk“. Nauja žaliava greita, bet eikvoja išteklius ir teršia. Žiedinė ekonomika stengiasi medžiagas naudoti vėl ir vėl."],
		"en": ["Linear economy", "The \"take – make – dispose\" model. New raw material is fast but uses up resources and pollutes. A circular economy reuses materials again and again."]},
	{"id": "scale",
		"lt": ["Masto ekonomija", "Kai gamini daugiau, vieno vieneto kaštai mažėja, nes pastovieji kaštai pasidalina per daugiau produktų. Žaidime pilnas sandėlis leidžia dirbti partijomis."],
		"en": ["Economies of scale", "Producing more lowers the cost per unit, because fixed costs are spread over more products. In the game a well-stocked storage lets a station work in batches."]},
	{"id": "opportunity",
		"lt": ["Alternatyvieji kaštai", "Tai, ko atsisakai rinkdamasis vieną variantą. Pasirinkęs vieną investiciją, prarandi kitų dviejų naudą."],
		"en": ["Opportunity cost", "What you give up by choosing one option. Picking one investment means losing the benefits of the other two."]},
	{"id": "demand",
		"lt": ["Paklausa ir pasiūla", "Kai pirkėjų daugiau (Juodasis penktadienis), kainos kyla, o kai mažiau (recesija) – krenta. Kaina priklauso nuo to, kiek žmonės nori pirkti."],
		"en": ["Supply and demand", "More buyers (Black Friday) push prices up, fewer buyers (recession) push them down. Prices depend on how much people want to buy."]},
	{"id": "labour",
		"lt": ["Darbo rinka", "Darbuotojai irgi gali derėtis dėl atlyginimo. Įmonė renkasi: mokėti daugiau ar prarasti gamybą per streiką."],
		"en": ["Labour market", "Workers can bargain over wages too. The company chooses: pay more or lose production during a strike."]},
	{"id": "growth",
		"lt": ["Ekonomikos augimas", "Kasmet žmonės perka vis daugiau, todėl įmonė turi investuoti, kad spėtų patenkinti augančią paklausą."],
		"en": ["Economic growth", "Every year people buy more, so the company has to invest to keep up with growing demand."]},
	{"id": "circularity",
		"lt": ["Žiedinumo rodiklis", "Kokia dalis medžiagų grįžta atgal į gamybą, užuot tapusi atliekomis. ES siekia, kad šis rodiklis kasmet augtų."],
		"en": ["Circularity rate", "The share of materials that return to production instead of becoming waste. The EU wants this rate to grow every year."]},
]

static var seen: Dictionary = {}

static func term(id: String) -> Array:
	for t in TERMS:
		if str(t["id"]) == id:
			return t[Loc.lang] if t.has(Loc.lang) else t["lt"]
	return ["", ""]

## Returns true the first time a term is triggered in this session.
static func first(id: String) -> bool:
	if seen.has(id):
		return false
	seen[id] = true
	return true
