## Learning
##
## Content of the "Mokymosi režimas" (learning mode): short economics lessons
## that pause the game at the moment the idea appears on screen, and a quiz at
## the end. Lets the game itself be the presentation.
class_name Learning
extends RefCounted

## Order in which lessons are numbered / shown at the end if they never came up.
const ORDER := ["intro", "value_added", "linear", "externality", "pigou", "scale", "growth",
	"circularity", "opportunity", "demand", "labour"]

## Each lesson: title, what it is, real-world example, where to see it in the game.
const LESSONS := {
	"intro": {
		"lt": ["Linijinė ir žiedinė ekonomika",
			"Linijinė ekonomika veikia pagal principą „paimk – pagamink – išmesk“: iškasame žaliavą, pagaminame daiktą, panaudojame ir išmetame. Žiedinė ekonomika siekia, kad daiktai ir medžiagos būtų naudojami vėl ir vėl – taisomi, perdirbami ir grąžinami į gamybą.",
			"ES 2020 m. priėmė Žiedinės ekonomikos veiksmų planą. Vis dėlto ES ekonomikoje vėl panaudojama tik apie 12 % medžiagų, o Lietuvoje – dar mažiau.",
			"Ratas aplink planetą – tai žiedinė ekonomika: daiktas iš Naudotojo keliauja per Surinkimą, Rūšiavimą, Perdirbimą, Gamyklą ir Parduotuvę atgal pas Naudotoją."],
		"en": ["Linear vs circular economy",
			"The linear economy works as \"take – make – dispose\": we extract raw materials, make a product, use it and throw it away. The circular economy keeps products and materials in use – they are repaired, recycled and returned to production.",
			"In 2020 the EU adopted the Circular Economy Action Plan. Still, only about 12 % of materials in the EU economy are reused, and in Lithuania even less.",
			"The ring around the planet is the circular economy: an item travels from the User through Collection, Sorting, Recycling, Factory and Shop back to the User."]},
	"value_added": {
		"lt": ["Pridėtinė vertė",
			"Kiekvienas gamybos etapas padidina produkto vertę. Galutinė produkto kaina – tai visų etapų pridėtinių verčių suma.",
			"Telefoną sudaro žaliavos už kelis eurus, bet po projektavimo, surinkimo ir prekybos jis kainuoja šimtus eurų. Pridėtinės vertės mokestis (PVM) skaičiuojamas būtent nuo šios vertės.",
			"Kiekviena stotis prideda vertės. Kuo daugiau etapų daiktas praeina, tuo daugiau uždirbi jį pardavęs. Patobulinimas „Vertė“ didina pridėtinę vertę."],
		"en": ["Value added",
			"Every production stage increases the value of a product. The final price is the sum of the value added at every stage.",
			"A phone contains raw materials worth a few euros, but after design, assembly and retail it costs hundreds. Value added tax (VAT) is charged on exactly this value.",
			"Each station adds value. The more stages an item passes, the more you earn when it is sold. The \"Value\" upgrade raises the value added."]},
	"linear": {
		"lt": ["Pirminė ir antrinė žaliava",
			"Pirminė žaliava – naujai iškasta ar išauginta (nafta, rūda, mediena). Antrinė žaliava – gauta perdirbus atliekas. Pirminė dažnai greitesnė ir patogesnė, bet eikvoja išteklius ir teršia.",
			"Perdirbant aliuminio skardinę sunaudojama apie 95 % mažiau energijos nei gaminant aliuminį iš rūdos.",
			"Mygtukas „Pirkti naują žaliavą“ (Tarpas) – tai linijinė ekonomika: greita, bet didina taršą ir mažina žiedinumą. Perdirbtas daiktas iš rato – antrinė žaliava."],
		"en": ["Primary vs secondary raw materials",
			"Primary raw material is newly extracted or grown (oil, ore, wood). Secondary raw material comes from recycled waste. Primary is often faster and easier, but it uses up resources and pollutes.",
			"Recycling an aluminium can uses about 95 % less energy than making aluminium from ore.",
			"The \"Buy new raw material\" button (Space) is the linear economy: fast, but it raises pollution and lowers circularity. A recycled item from the ring is secondary raw material."]},
	"externality": {
		"lt": ["Neigiamas išorinis poveikis",
			"Tai žala, kurią įmonė padaro kitiems žmonėms, bet už ją pati nemoka. Rinka tokios žalos „nemato“, todėl jos susidaro per daug – tai rinkos nepakankamumas.",
			"Gamyklos dūmai kenkia aplinkinių gyventojų sveikatai, o gydymo išlaidas apmoka žmonės ir valstybė, ne gamykla.",
			"Kai daiktai iškrenta į sąvartyną, kyla tarša. Ji mažina visų produktų kainas ir sukelia nelaimes – tai ir yra išorinis poveikis, kurį sukėlei pats."],
		"en": ["Negative externality",
			"Harm a company causes to other people without paying for it. The market does not \"see\" this harm, so too much of it is produced – a market failure.",
			"Factory smoke harms the health of people living nearby, while the medical costs are paid by those people and the state, not by the factory.",
			"When items fall into the landfill, pollution rises. It lowers the prices of all products and causes disasters – an externality you caused yourself."]},
	"pigou": {
		"lt": ["Pigou mokestis",
			"Mokestis, kuriuo valstybė apmokestina žalingą veiklą, pvz., taršą. Įmonė „sumoka“ už padarytą žalą, todėl jai pačiai apsimoka teršti mažiau.",
			"Lietuvoje nuo 2016 m. taikomas mokestis už atliekų šalinimą sąvartyne, o plastikiniai maišeliai parduotuvėse yra mokami.",
			"Už kiekvieną į sąvartyną patekusį daiktą moki baudą. Todėl verta investuoti į didesnius sandėlius ir greitesnes stotis, o ne leisti daiktams iškristi."],
		"en": ["Pigouvian tax",
			"A tax the state puts on harmful activity, like pollution. The company \"pays\" for the damage, so polluting less pays off for it.",
			"Since 2016 Lithuania has a landfill tax on waste disposal, and plastic bags in shops are charged for.",
			"You pay a fine for every item that ends up in the landfill. That is why it pays to invest in bigger storage and faster stations instead of letting items fall out."]},
	"scale": {
		"lt": ["Masto ekonomija",
			"Kai gamini daugiau, vieno produkto kaštai mažėja, nes pastovieji kaštai (pastatai, įranga) pasiskirsto per daugiau produktų.",
			"Automobilių gamykla, per metus pagaminanti milijoną automobilių, vienam automobiliui išleidžia daug mažiau nei maža dirbtuvė.",
			"Kai stoties sandėlis bent pusiau pilnas, ji dirba partijomis ir greičiau – virš stoties matysi žalią „+%“ ženkliuką."],
		"en": ["Economies of scale",
			"Producing more lowers the cost per unit, because fixed costs (buildings, equipment) are spread over more products.",
			"A car plant making a million cars a year spends far less per car than a small workshop.",
			"When a station's storage is at least half full, it works in batches and faster – you will see a green \"+%\" badge above the station."]},
	"growth": {
		"lt": ["Ekonomikos augimas",
			"Kai šalies ekonomika auga, žmonės uždirba ir perka daugiau. Įmonės turi investuoti, kad spėtų patenkinti augančią paklausą.",
			"Ekonomikos augimas matuojamas BVP (bendrojo vidaus produkto) pokyčiu. Lietuvos BVP per pastaruosius 20 metų išaugo kelis kartus.",
			"Kasmet į ratą patenka vis daugiau daiktų. Jei neinvestuosi į patobulinimus, stotys nespės ir daiktai kris į sąvartyną."],
		"en": ["Economic growth",
			"When an economy grows, people earn and buy more. Companies have to invest to keep up with growing demand.",
			"Economic growth is measured by the change in GDP (gross domestic product). Lithuania's GDP has grown several times over the last 20 years.",
			"Every year more items enter the ring. If you do not invest in upgrades, the stations cannot keep up and items fall into the landfill."]},
	"circularity": {
		"lt": ["Žiedinumo rodiklis ir ES tikslai",
			"Žiedinumo rodiklis parodo, kokia dalis medžiagų grįžta atgal į gamybą, užuot tapusi atliekomis. Valstybės nustato tikslus, kad šis rodiklis augtų.",
			"ES tikslas – iki 2035 m. perdirbti 65 % komunalinių atliekų ir į sąvartynus šalinti ne daugiau kaip 10 %. Lietuvos taros užstato sistema grąžina daugiau nei 90 % butelių ir skardinių.",
			"Metų pabaigoje ES patikrina tavo žiedinumą. Pasiekei tikslą – gauni premiją, nepasiekei – moki baudą. Tikslas kasmet griežtėja."],
		"en": ["Circularity rate and EU targets",
			"The circularity rate shows how much material returns to production instead of becoming waste. Governments set targets so that this rate grows.",
			"The EU target is to recycle 65 % of municipal waste by 2035 and landfill no more than 10 %. Lithuania's deposit return system collects more than 90 % of bottles and cans.",
			"At the end of each year the EU checks your circularity. Reach the target and you get a bonus, miss it and you pay a fine. The target gets stricter every year."]},
	"opportunity": {
		"lt": ["Alternatyvieji kaštai",
			"Tai nauda, kurios atsisakai rinkdamasis vieną variantą vietoje kito. Ištekliai riboti, todėl kiekvienas pasirinkimas kainuoja kitas galimybes.",
			"Studentas, kuris vakarą mokosi, atsisako tą vakarą uždirbti pinigų darbe. Tie neuždirbti pinigai – jo mokymosi alternatyvieji kaštai.",
			"Metų pabaigoje gali pasirinkti tik vieną investiciją iš trijų. Kitų dviejų nauda – tavo alternatyvieji kaštai."],
		"en": ["Opportunity cost",
			"The benefit you give up when you choose one option instead of another. Resources are limited, so every choice costs other opportunities.",
			"A student who studies in the evening gives up the money they could have earned at work that evening. That lost income is the opportunity cost of studying.",
			"At the end of each year you can pick only one investment out of three. The benefits of the other two are your opportunity cost."]},
	"demand": {
		"lt": ["Paklausa ir pasiūla",
			"Kaina susidaro ten, kur susitinka paklausa (kiek pirkėjai nori pirkti) ir pasiūla (kiek pardavėjai nori parduoti). Kai paklausa auga, kainos kyla, kai mažėja – krenta.",
			"Per Juodąjį penktadienį pirkėjų daug, o per ekonomikos nuosmukį (recesiją) žmonės perka mažiau ir parduotuvės mažina kainas.",
			"Rinkos įvykiai keičia pardavimo kainas: kartais produktai brangsta, kartais pinga. Stebėk viršuje pasirodančias žinias."],
		"en": ["Supply and demand",
			"Price is set where demand (how much buyers want to buy) meets supply (how much sellers want to sell). When demand rises, prices go up; when it falls, they go down.",
			"On Black Friday there are many buyers, while in a recession people buy less and shops cut prices.",
			"Market events change selling prices: sometimes products get more expensive, sometimes cheaper. Watch the news banner at the top."]},
	"labour": {
		"lt": ["Darbo rinka",
			"Darbo rinkoje darbuotojai siūlo savo darbą, o įmonės jį perka už atlyginimą. Darbuotojai gali derėtis dėl atlyginimo, pvz., streikuodami.",
			"Lietuvoje minimalią mėnesio algą kasmet nustato Vyriausybė, o profesinės sąjungos derasi dėl atlyginimų įmonėse.",
			"Kartais stotis sustreikuoja. Gali sumokėti darbuotojams ir tęsti darbą arba laukti ir prarasti gamybą."],
		"en": ["Labour market",
			"In the labour market workers offer their work and companies pay wages for it. Workers can bargain over wages, for example by going on strike.",
			"In Lithuania the government sets the minimum monthly wage every year, and trade unions bargain over wages in companies.",
			"Sometimes a station goes on strike. You can pay the workers and continue or wait and lose production."]},
}

## Quiz shown at the end of learning mode: question, 3 answers, index of correct, explanation.
const QUIZ := {
	"lt": [
		["Kuo žiedinė ekonomika skiriasi nuo linijinės?",
			["Daiktai gaminami tik iš naujų žaliavų", "Medžiagos naudojamos vėl ir vėl", "Atliekos vežamos į sąvartyną"], 1,
			"Žiedinėje ekonomikoje medžiagos grąžinamos į gamybą, o linijinė veikia „paimk – pagamink – išmesk“."],
		["Kas yra neigiamas išorinis poveikis?",
			["Žala kitiems, už kurią įmonė nemoka", "Įmonės pelnas iš eksporto", "Mokestis už sąvartyną"], 0,
			"Pvz., tarša: ji kenkia visiems, bet teršėjas už ją nemoka."],
		["Kodėl valstybė apmokestina atliekų šalinimą sąvartyne?",
			["Kad uždirbtų daugiau pinigų", "Kad sąvartynai būtų didesni", "Kad perdirbti apsimokėtų labiau nei išmesti"], 2,
			"Tai Pigou mokestis: žala „įkainojama“, todėl įmonėms apsimoka teršti mažiau."],
		["Iš trijų investicijų pasirinkai vieną. Kaip vadinama kitų dviejų nauda?",
			["Alternatyvieji kaštai", "Pridėtinė vertė", "Masto ekonomija"], 0,
			"Alternatyvieji kaštai – tai, ko atsisakai rinkdamasis."],
		["Kas paprastai nutinka kainoms, kai paklausa sparčiai auga?",
			["Kainos krenta", "Kainos kyla", "Kainos nesikeičia"], 1,
			"Kai pirkėjų daugiau nei prekių, kainos kyla."],
		["Kiek komunalinių atliekų ES siekia perdirbti iki 2035 m.?",
			["15 %", "40 %", "65 %"], 2,
			"ES tikslas – 65 % perdirbti ir ne daugiau kaip 10 % šalinti sąvartynuose."],
	],
	"en": [
		["How does the circular economy differ from the linear one?",
			["Products are made only from new raw materials", "Materials are used again and again", "Waste is taken to the landfill"], 1,
			"In the circular economy materials return to production, while the linear one is \"take – make – dispose\"."],
		["What is a negative externality?",
			["Harm to others that the company does not pay for", "A company's profit from exports", "A landfill tax"], 0,
			"For example pollution: it harms everyone, but the polluter does not pay for it."],
		["Why does the state tax landfill disposal?",
			["To earn more money", "To make landfills bigger", "So that recycling pays off more than dumping"], 2,
			"It is a Pigouvian tax: the harm gets a price, so polluting less pays off."],
		["You picked one of three investments. What is the benefit of the other two called?",
			["Opportunity cost", "Value added", "Economies of scale"], 0,
			"Opportunity cost is what you give up when you choose."],
		["What usually happens to prices when demand grows fast?",
			["Prices fall", "Prices rise", "Prices stay the same"], 1,
			"When there are more buyers than goods, prices rise."],
		["What share of municipal waste does the EU aim to recycle by 2035?",
			["15 %", "40 %", "65 %"], 2,
			"The EU target is to recycle 65 % and landfill no more than 10 %."],
	],
}

static func lesson(id: String) -> Array:
	if not LESSONS.has(id):
		return []
	var l: Dictionary = LESSONS[id]
	return l[Loc.lang] if l.has(Loc.lang) else l["lt"]

static func quiz() -> Array:
	return QUIZ[Loc.lang] if QUIZ.has(Loc.lang) else QUIZ["lt"]
