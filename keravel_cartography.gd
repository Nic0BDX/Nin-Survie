extends RefCounted

## Supplied illustration, 1672 × 941. Pins are authored in image pixels.
const SIZE=Vector2(1672,941)
const PINS={
	"ponton-arrivee":Vector2(180,608),"prairie-phare":Vector2(353,408),
	"crique-baies":Vector2(221,485),"phare-keravel":Vector2(292,324),
	"passe-courlis":Vector2(192,351),"le-courlis":Vector2(89,293),
	"passe-nord":Vector2(250,232),"corne-de-brume":Vector2(193,135),
	"passe-salines":Vector2(419,309),"ateliers-salines":Vector2(543,216),
	"basse-des-dents":Vector2(789,223),"mer-iroise":Vector2(938,687),
	"route-trois-vannes":Vector2(416,466),"tv-remparts":Vector2(464,423),
	"tv-place-cloche":Vector2(674,491),"tv-auberge":Vector2(610,461),
	"tv-forge":Vector2(744,467),"tv-apothicaire":Vector2(590,503),
	"tv-chapelle":Vector2(693,422),"tv-caves":Vector2(709,432),
	"tv-halle":Vector2(732,527),"tv-criee":Vector2(620,608),
	"tv-port":Vector2(663,685),"tv-chantier":Vector2(778,734),
	"tv-moulin":Vector2(860,678),"tv-manoir":Vector2(825,493),
	"ea-plage-naufrages":Vector2(1130,841),"ea-sentier-embruns":Vector2(1378,780),
	"ea-camp-base":Vector2(1527,765),"ea-embouchure":Vector2(1247,862),
	"ea-gue-lavandieres":Vector2(1317,641),"ea-pont-de-corde":Vector2(1321,552),
	"ea-cascade-voile":Vector2(1350,363),"ea-grotte-voile":Vector2(1381,399),
	"ea-lac-miroir":Vector2(1372,302),"ea-foret-coat-du":Vector2(1151,329),
	"ea-coeur-foret":Vector2(1212,364),"ea-marais-stank":Vector2(1532,502),
	"ea-antre-serpent":Vector2(1568,565),"ea-ker-goz":Vector2(1143,549),
	"ea-landes-brug":Vector2(1117,703),"ea-gorges-rochgwenn":Vector2(1515,656),
	"ea-ruines-veilleurs":Vector2(1144,161),"ea-camp-garde":Vector2(1281,219),
	"ea-mines-vertes":Vector2(1370,261),"ea-citadelle-remparts":Vector2(1410,276),
	"ea-citadelle-cour":Vector2(1465,244),"ea-citadelle-cryptes":Vector2(1420,284),
	"ea-citadelle-donjon":Vector2(1488,209),"ea-salle-verte":Vector2(1507,232),
	"ea-crete-vents":Vector2(1476,155),"ea-pic-braise":Vector2(1425,71),
	"ea-antre-aerouant":Vector2(1500,122),
}

static func locate(p:Vector2,points:Dictionary)->Vector2:
	var best=[]
	for id in PINS:
		var distance=p.distance_squared_to(points[id])
		if distance<.018: return PINS[id]
		best.append([distance,PINS[id]])
	best.sort_custom(func(a,b):return a[0]<b[0])
	var weighted=Vector2.ZERO
	var total=0.
	for i in 4:
		var weight=1./float(best[i][0])
		weighted+=best[i][1]*weight
		total+=weight
	return weighted/total
