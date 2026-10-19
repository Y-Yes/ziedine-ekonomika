3D grafikos generatoriai (Blender per Python).

Reikia: Python 3.13 + "pip install bpy numpy pillow".

  python stations.py 1_naudotojas full     -> stociu kadrai (24 kadrai kiekvienai)
  python planet.py ok|bad|fire full        -> planetos kadrai (48)
  python small.py tokens|hud|sort|perks    -> zetonai, ikonos, rusiavimas, kortos
  python background.py ../../art/fonas.png -> fonas
  python assemble.py ../../art             -> sudeda kadrus i sprite sheet'us

Kadrai saugomi aplanke frames/ (keliai skriptuose nurodyti absoliuciai - pakeisk pagal save).

v2 (kvadratines salos + tikra Zeme):
  python tiles.py 1_naudotojas full        -> miesto saleles (frames2/)
  python make_tex.py                       -> Zemes tekstūros (reikia three.js
      examples/textures/planets/earth_*.jpg/png, ziur. skripto virsu)
  python planet2.py ok|bad|fire full       -> Zeme su tikrais zemynais
  python assemble.py ../../art tiles planets
