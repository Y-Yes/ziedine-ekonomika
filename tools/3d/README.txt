3D grafikos generatoriai (Blender per Python).

Reikia: Python 3.13 + "pip install bpy numpy pillow".

  python stations.py 1_naudotojas full     -> stociu kadrai (24 kadrai kiekvienai)
  python planet.py ok|bad|fire full        -> planetos kadrai (48)
  python small.py tokens|hud|sort|perks    -> zetonai, ikonos, rusiavimas, kortos
  python background.py ../../art/fonas.png -> fonas
  python assemble.py ../../art             -> sudeda kadrus i sprite sheet'us

Kadrai saugomi aplanke frames/ (keliai skriptuose nurodyti absoliuciai - pakeisk pagal save).
