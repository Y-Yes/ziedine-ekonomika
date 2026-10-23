# 02B žaidimo grafika

Septynios atskiros permatomos PNG tekstūros, sukurtos su integruotu `image_gen` pagal patvirtintą 02B vizualizaciją. Originali moneta, planeta ir fonas išsaugoti. Ankstesni stočių animacijų lapai lieka `art/` aplanke, bet žaidimas ir stočių lentelė naudoja šio aplanko grafiką.

Žaidimas rodo vieną tekstūrą kiekvienai stočiai; plūduriavimas, paspaudimo atsakas, darbo indikatorius, gaisrai ir gamyklos garai piešiami vykdymo metu. Ankstesni 24 kadrų pastatų animacijų lapai čia nenaudojami.

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
