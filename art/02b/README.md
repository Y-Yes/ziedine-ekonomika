# 02B žaidimo grafika

Aktyvios šešių salų animacijos yra `approved_loops/` aplanke: kiekviename PNG atlase yra 96 kadrai, išdėstyti 12 × 8 tinkleliu (6144 × 4096, vienas kadras 512 × 512). Keturių sekundžių ciklas atkuriamas 24 kadr./s. Kadrai renderinami 1024 × 1024 raiška ir mažinami su Lanczos filtru iki 512 × 512, kad judančios briaunos būtų glotnesnės. Visi kadrai apskaičiuojami tolydžiai iš judesio fazės; ankstesni šešių pozų atlasai nebenaudojami. Darbo greitis integruojamas į animacijos laikrodį, todėl pasikeitus apkrovai fazė neperšoka.

Salų pagrindai, kamera ir mastelis fiksuoti. Pastatai ir medžiai nesideformuoja: bendras UV lapijos siūbavimo efektas pašalintas. Durys animuojamos išmatuotose visos angos keturkampėse plokštumose; gamyklos vartų lamelės slenka, o ne tempiasi. Pašalintas visos salos kilnojimas ir susitraukimas paspaudus. Paspaudimo grįžtamasis ryšys rodomas kontūre.

- Naudotojas: namo durys lieka uždarytos, iš kamino kyla aiškiai matomi minkšti garai.
- Surinkimas: 02B sunkvežimis trumpai važiuoja aikštelės plokštuma už nejudančių dviračių konteinerių, toliau nuo medžių. Abiejuose maršruto galuose greitis tolygiai sumažėja iki nulio.
- Rūšiavimas: didelė 02B ranka sukasi apie jungtį ant nejudančio stovo, juda konvejerių paviršiai.
- Perdirbimas: žaliu konvejeriu iš smulkintuvo angos juda pačios iliustruotos atliekų dalelės ir juostos rievės; konvejerio plokštuma apibrėžta keturiais kampais, korpusas ir kraštai nesideformuoja.
- Gamykla: keliami pakrovimo vartai, kyla dūmai.
- Parduotuvė: abi įėjimo durų pusės slenka į šonus ir dingsta už staktų, matomas įgilintas praėjimas su laisvomis grindimis; lentyna į angą nekopijuojama.

Surinkimo ir rūšiavimo sluoksniai sujungiami generavimo metu į vientisus visos salos kadrus. Vykdomas žaidimas naudoja tik galutinius PNG atlasus. Originali moneta, planeta ir fonas išsaugoti.

`landfill_ground_v3.png` yra tuščia sąvartyno bazė: atliekos pridedamos tik didėjant sąvartyno skaitikliui. `tokens.png`, `sorting_items.png`, `bins.png` ir `perks.png` yra atnaujinti objektų atlasai. Kortelių ir konteinerių regionai apibrėžti `scripts/game_art.gd`, kad nesimatytų gretimų objektų fragmentų. Metų ataskaitos piktogramos naudoja `perk_loops/`: 96 pilni 256 × 256 kadrai (12 × 8 atlasas), 24 kadr./s. `tools/render_perk_loops.gd` renderina sujungtus 3D objektus: juda robotinės rankos petys, alkūnė ir griebtuvas, vartomi knygos lapai, atsidaro portfelis ir t. t. Iškirptų rastrinių dalių ir visos piktogramos levitavimo nebenaudojama. Statinis `perks.png` išsaugotas kaip ankstesnės išvaizdos etalonas ir atsarginis variantas. Gaisras naudoja naują glotnintą `fire_loop.png` atlasą; ankstesnis `fire.png` bandymas nenaudojamas.

Statinės 02B salų iliustracijos išsaugotos kaip kokybės etalonas. `loops/` aplanke esančios supaprastintos 3D animacijų peržiūros vykdomame žaidime nenaudojamos. Kokybiški atskiri sunkvežimio, konteinerių ir robotinės rankos piešiniai naudojami tik galutiniams kadrams generuoti.

Aktyvias kadrų juostas galima atkurti: `Godot --path <projekto aplankas> --script res://tools/bake_02b_illustrated_loops.gd`. Žaidimas toliau naudoja tik PNG kadrus.

### Ankstesni pilnų salų pozų atlasai (neaktyvūs)

`quality_collection.png` ir `quality_sorting.png` sukurti integruotu `image_gen`, naudojant atitinkamą patvirtintą statinę 02B salą kaip išvaizdos etaloną, su `transparent_background=true`. Bendras aprašymas: six complete copies of the same polished 02B island, exact 3-column by 2-row atlas, identical camera, tile registration, lighting, materials and detail; each whole island stays within its cell; no UI or lettering; genuine transparency; change only the specified mechanical activity, no crude primitive replacement and no separate floating cutouts. Poses play forward and backward with easing, without a disappearing vehicle at the loop boundary.

Surinkimo aprašymas: the white-green truck makes a short slow drive along the paved rear lane, all wheels stay on pavement and behind the three fixed yellow, green and blue bins; six small successive offsets along that same lane; ordinary two-wheel bins; identical vehicle dimensions and perspective.

Rūšiavimo aprašymas: six successive poses of the large yellow robot picking arm moving from left toward right, physically connected to its gray pedestal in every whole-island frame; maintain original large proportions and polished detail; conveyors, rails, bins and ground retained; cardboard remains on the belt or in the gripper.

## Generavimo užduotys

Visiems failams naudotas vienodas bendras aprašymas ir po vieną objekto aprašymą. Generuota atskirais integruoto įrankio kvietimais su `transparent_background=true`; CLI nenaudotas.

### Bendras aprašymas

Use case: stylized-concept. Asset type: production TRANSPARENT PNG game sprite, one isolated isometric diorama for actual Godot game. The reference image is approved 02B art direction ONLY. Extract and recreate ONLY the specified subject as a separate clean high-quality sprite.

ONE island only, square canvas, genuinely transparent background; no UI, no text labels, no stars, no Earth, no ring, no other stations, no panels, no ground outside island, no cast shadow outside island. Match reference's polished restrained low-poly 3D game artwork, clear silhouettes, smooth beveled edges, matte materials, gentle ambient occlusion, consistent warm upper-left lighting.

Camera: orthographic isometric, see front and right faces, same elevated camera and same diamond shaped shallow square island as reference. Ground tile is a shallow thin grass-top square with neat beige stone/brown soil sides, no hanging rock or fantasy cliff. Fit entire diorama in square with 7% safe padding left/right. Tile diamond left/right points at x=7%/93%, tile back point at y=44%, tile left/right corners y=65%, tile front point y=88%. Buildings/equipment occupy above the tile, highest point around y=10%-18%, entirely within canvas. Consistent scale: station fits one 86%-width diamond tile. Fine details readable at 150px wide; prioritize broad clean shapes. No words, no numbers, no currency symbols. Deliver just isolated transparent asset.

### Objektų aprašymai

- `1_naudotojas.png`: consumer household: compact white two-storey European detached house with steep terracotta red tiled gable roof, small chimney, front door and windows, small white picket fence around garden, a few round leafy green trees. Match the TOP house in reference exactly.
- `2_surinkimas.png`: waste collection yard: THREE medium sized wheeled recycling bins in foreground colored yellow, green and blue left to right, simple white recycle pictograms, a SMALL white and green garbage collection truck parked behind bins facing right, tiny shrubs. No building. Match the UPPER RIGHT collection station in reference.
- `3_rusiavimas.png`: waste sorting line: long exposed dark gray conveyor with a few distinct cardboard boxes, blue plastic bottle, yellow material, ONE yellow industrial robotic sorting arm in center, three small colored receiving bins at front right, yellow safety rails at back. No enclosed building. Match LOWER RIGHT station in reference.
- `4_perdirbimas.png`: recycling machinery yard: open gray metal shredder with square hopper containing plastic fragments at rear left, short GREEN conveyor from shredder toward front right, neatly stacked rectangular compressed recycling bales with white and multicolor speckled surfaces at front right, two plain white pellet sacks at front left, a small simple green recycle pictogram on machine. No huge green tank, no dome, no nuclear reactor. Match BOTTOM recycling station in reference.
- `5_gamykla.png`: manufacturing factory: compact white industrial factory with THREE blue sawtooth roof ridges, a single tall white chimney with two red bands at rear right, small loading door, neat wooden pallets and gray steel barrels in front. No baked-in smoke. Match LOWER LEFT factory in reference.
- `6_parduotuve.png`: modern small Lithuanian grocery store: cream rectangular one-storey building, flat dark gray roof with one small vent, broad glass shopfront revealing warm-lit simple shelves, green square sign with white shopping basket PICTOGRAM, one shopping trolley outside left and two colorful fruit crates outside right, few small round trees. No lettering, no striped awning. Match UPPER LEFT shop in reference.
- `7_savartynas.png`: small landfill diorama: low brown dirt mound with a modest scattering of gray and colored litter, a SMALL yellow bulldozer parked at right, mostly bare earth with a few stones. Match lower right landfill in reference, keep pile small so game can add waste dynamically.


Perspėjimo, pilno sandėlio ir mišrių atliekų kontūrai piešiami prieš salos kadrą, todėl nebeuždengia įrangos. Sandėlio pusės užpildymo žalia linija pašalinta; greičio bonuso taisyklė nepakeista. Planetos atmosferos alfa tęsiama po planetos kraštu, kad antialiasingas nepaliktų tamsaus tarpo.


## Kortelių ir rūšiavimo daiktų pataisos

- Žaliosios obligacijos: žalio investavimo sertifikatas su euro antspaudu.
- Logistikos centras: sandėlis su atviromis pakrovimo angomis, ritininiu taku ir siunta; siunta juda tik laisva anga ir sustoja iki galinės sienos.
- Valymo technologijos: upės teršalų surinkimo užtvara, vandens filtravimo įrenginys ir žali krantai.
- Taromatas turi tikrą CSG išpjautą angą; butelio ašis sutampa su anga, butelis telpa ertmėje.
- Knygos lapo kraštas pritvirtintas prie matomo įrišimo, ties puslapių viršumi; portfelis turi sieneles ir dugną, moneta kyla tik dangčiui atsidarius; priekinės monetos atitrauktos nuo krūvos.
- Kortelių korpusai turi užapvalintus paviršius su tolydžiais normalės vektoriais.
- Liepsna kortelėje modeliuojama iš lenkto paviršiaus su šviesiu vidumi; stoties gaisras naudoja iš anksto renderintus 3D liepsnos kadrus su glotnintais kraštais (`fire_loop.png`, 96 kadrai, 24 kadr./s). Juos galima atkurti per `tools/render_perk_loops.gd -- --icon=fire_effect`.

`sorting_pet_v2.png` ir `sorting_can_v2.png` sukurti integruotu `image_gen`, permatomame fone: įprastų proporcijų skaidrus PET butelis su mėlynu kamšteliu ir penkių atramų dugnu; nežymiai įlenkta aliuminio skardinė su aiškiu atidarymo žiedeliu. Be neoninio švytėjimo, logotipų ar stiprių suspaudimų. `GameArt.frame` pakeičia tik rūšiavimo atlaso indeksus 0 ir 1; likę keturi daiktai nekeičiami.


## Galutinės pataisos: sąvartynas, sodri ugnis ir iliustruoti daiktai

- `landfill_ground_v3.png`: atskiras detalus gruntas su vėžėmis; `landfill_loader_v3.png`: aukštos raiškos krautuvas, važiuojantis trumpu ciklu dešine juosta. Sala ir mastelis nejuda.
- `landfill_litter_v3.png`: šeši pavieniai atliekų objektai 3 × 2 atlase. Nė viename langelyje nėra kelių daiktų ar presuotų kubų. Vienas `add` padidina skaitiklį vienetu ir prideda vieną krintantį objektą. Pirmi 18 išsidėsto žemėje, toliau kyla kiti sluoksniai. Matoma iki 240 objektų.
- Aktyvūs rūšiavimo daiktai: `sorting_pet_v3.png`, `sorting_can_v3.png`. Ankstesni fotorealistiškesni v2 nebevartojami. Nauji daiktai turi supaprastintus apvalius paviršius, derančius prie konteinerių.
- Mokesčių lengvata rodoma dokumentu su reljefiniu procento antspaudu ir ant pagrindo sudėtomis monetomis; dydis nurodytas kortelės aprašyme. Metų ataskaitos mygtukų aukštis matuojamas pagal jau sulaužytą tekstą; piktogramos padidintos iki 84 loginių pikselių.
- Kortelės renderinamos 1024 × 1024 su 4× MSAA ir mažinamos Lanczos iki 256 × 256. Išlieka 96 kadrai ir 24 kadr./s. Naujos rastrinės tekstūros importuojamos be nuostolingo glaudinimo, su mipmaps.
- Stoties ugnis: sodri oranžinė išorė, geltonas ir šviesus vidus, emisija, didesnės liepsnos, kylančios žiežirbos; generavimas `--icon=fire_effect`.

Nauji rastriniai šaltiniai sukurti integruotu `image_gen` su tikru permatomumu. Aprašymai: (1) preserve exact approved isometric diamond island, remove loader, add dirt tire tracks and pebbles, no baked garbage; (2) isolate matching polished yellow wheel loader, full vehicle, same perspective, no ground; (3) registered 3×2 atlas, exactly one tied gray bag, lying crushed PET, lying dented can, crumpled paper, lying green bottle, tied blue bag per cell, no groups/cubes; (4) stylized rounded toy-like PET and teal-band can matching bins, no photorealistic microtexture. Kortelių ir liepsnų tekstūros generuojamos iš Godot modelių, nenaudojant iškirptų judančių paveikslėlių.


## Kortelių patobulinimas v4

Bendras apšvietimas sumažintas, kad paviršiai nebūtų išbalę; perrenderintos visos 12 kortelių. Saulės elektrinė turi tamsius elementus su smulkiu tinkleliu ir kontaktais, tvirtinimo varžtus, atramas ir smailėjančius saulės spindulius vietoje rutuliukų. Procento antspaudas sudarytas iš tikrų reljefinių žiedų bei įstrižos juostelės, be „−20 %“ užrašo. Knygos tekstas juda kartu su išlenktu puslapiu; lapų simboliai turi lenktus paviršius ir gyslą. Sandėliui pridėtos stogo briaunos ir šviestuvai; portfeliui spynelės ir kniedės; gesintuvui manometras bei etiketė.

Taromato butelio eiga vienkryptė: `z` nuo 0.74 iki 0.14, galas telpa korpuse. Butelis visiškai pasislepia prieš ciklo pabaigą, o naujas palaipsniui pasirodo išorėje. Įsiurbimo anga turi tamsią atvirą movą. Stoties liepsnos 32 % aukštesnės, išlaikant tą patį pagrindo tašką.


## Vedlys ir Web vaizdo kokybė

Vedlio ir įvykių patarimų apskritimų centras bei spindulys apskaičiuojami iš kiekvienos salos nepermatomų pikselių, o ne iš seno 52/70 px dydžio. Skaičiavimas išsaugomas po pradinio kadro matavimo; keičiant mastelį taikomas dabartinis `ART_SCALE`. Taip apimamas pastatas ir visas salos pagrindas, rodyklė remiasi į apskritimo kraštą.

Planetos šešėliuoklyje tekstūrų išvestinės skaičiuojamos ir disko išorėje, kad WebGL krašte neliktų neapibrėžtų mėginių. Planetos ir atmosferos spalvos sujungiamos premultiplied erdvėje ir grąžinamos su straight alpha. Visų septynių planetos žemėlapių importas dabar be papildomo nuostolingo glaudinimo; HiDPI įjungtas aiškiai. Salų ir kortelių atlasai jau anksčiau buvo eksportuojami lossless, su mipmaps ir be dydžio ribojimo. `canvas_items` leidžia piešti tikslinio lango raiška; naršyklės Web šablonas atsižvelgia į `devicePixelRatio`.
