extends Node3D

const Ink=preload("res://meshwork.gd")
const Art=preload("res://art.gd")
const Architecture=preload("res://keravel_architecture.gd")
const Civic=preload("res://keravel_civic.gd")
const START=Vector2(42,141)
const ARRIVAL=Vector2(11.5,48)
const RELAY_OFFICE=Vector2(37,144)
const BOUNDS=Rect2(-125,-240,655,525)
const TOWN=Rect2(-32,100,228,184)
const ISLAND_SOURCE=Rect2(-520,-154,388,280)
const OUTER_SHIFT=154.
const OUTER_TILT=.56
const OUTER_DEPTH=.84
const POINTS={
	"ponton-arrivee":Vector2(11.5,48), "prairie-phare":Vector2(1,32),
	"crique-baies":Vector2(18,43), "phare-keravel":Vector2(-7,15),
	"passe-courlis":Vector2(-38,24), "le-courlis":Vector2(-61,3),
	"passe-nord":Vector2(-22,-26), "corne-de-brume":Vector2(-20,-51),
	"passe-salines":Vector2(34,5), "ateliers-salines":Vector2(56,-20),
	"basse-des-dents":Vector2(86,-66), "mer-iroise":Vector2(129,159),
	"route-trois-vannes":Vector2(14,91), "tv-remparts":Vector2(30,130),
	"tv-place-cloche":START, "tv-auberge":Vector2(31,149),
	"tv-forge":Vector2(62,142), "tv-apothicaire":Vector2(28,169),
	"tv-chapelle":Vector2(63,171), "tv-caves":Vector2(68,177),
	"tv-halle":Vector2(44,163), "tv-criee":Vector2(40,196),
	"tv-port":Vector2(39,221), "tv-chantier":Vector2(66,220),
	"tv-moulin":Vector2(95,220), "tv-manoir":Vector2(96,150),
	"ea-plage-naufrages":Vector2(-193,61), "ea-sentier-embruns":Vector2(-215,75),
	"ea-camp-base":Vector2(-239,58), "ea-embouchure":Vector2(-218,46),
	"ea-gue-lavandieres":Vector2(-258,28), "ea-pont-de-corde":Vector2(-299,15),
	"ea-cascade-voile":Vector2(-341,7), "ea-grotte-voile":Vector2(-348,14),
	"ea-lac-miroir":Vector2(-378,-1), "ea-foret-coat-du":Vector2(-252,58),
	"ea-coeur-foret":Vector2(-280,59), "ea-marais-stank":Vector2(-275,-11),
	"ea-antre-serpent":Vector2(-289,-32), "ea-ker-goz":Vector2(-309,-17),
	"ea-landes-brug":Vector2(-351,-31), "ea-gorges-rochgwenn":Vector2(-369,-61),
	"ea-ruines-veilleurs":Vector2(-394,-65), "ea-camp-garde":Vector2(-396,-24),
	"ea-mines-vertes":Vector2(-417,-37), "ea-citadelle-remparts":Vector2(-423,-12),
	"ea-citadelle-cour":Vector2(-441,-14), "ea-citadelle-cryptes":Vector2(-438,-36),
	"ea-citadelle-donjon":Vector2(-457,-7), "ea-salle-verte":Vector2(-465,-23),
	"ea-crete-vents":Vector2(-415,-42), "ea-pic-braise":Vector2(-451,-53),
	"ea-antre-aerouant":Vector2(-470,-51),
}
const COAST=[Vector2(8,40),Vector2(9,62),Vector2(14,91),Vector2(23,112),Vector2(30,130),START]
const RIVER=[Vector2(-378,-1),Vector2(-357,3),Vector2(-341,7),Vector2(-318,10),
	Vector2(-299,15),Vector2(-277,16),Vector2(-258,28),Vector2(-234,33),Vector2(-216,40),Vector2(-195,45)]
const OUTER_COAST_ROUTES=[
	[Vector2(-193,61),Vector2(-202,68),Vector2(-215,75),Vector2(-226,68),Vector2(-239,58)],
	[Vector2(-239,58),Vector2(-229,51),Vector2(-218,46)],
]
const WATER_LEVELS=[16.5,15.8,7.4,6.8,6.2,5.3,4.2,3.2,1.8,.68]
const STONE=Color("#a7a299")
const COBBLE=Color("#9e9783")
const DARK_STONE=Color("#4d5954")
const PLASTER=[Color("#dfc29b"),Color("#b4b3a0"),Color("#d3b593"),Color("#b78367")]
const SLATE=[Color("#3c4c57"),Color("#4b5d66"),Color("#814f41"),Color("#4a5559")]
var zones={}
var chapters=[]
var paths:Array=[]
var footprints:Array[Rect2]=[]
var outer_footprints:Array[Rect2]=[]
var points={}
var outer=Node3D.new()
var chart:ImageTexture
var world
var noise=FastNoiseLite.new()
var rng=RandomNumberGenerator.new()

func configure(owner_world):
	world=owner_world
	noise.seed=1229
	noise.frequency=.033
	rng.seed=223711
	var story=JSON.parse_string(FileAccess.get_file_as_string("res://keravel_story.json"))
	assert(story is Dictionary)
	chapters=story.chapters
	for zone in story.zones: zones[zone.id]=zone
	assert(zones.size()==POINTS.size())
	outer.transform=Transform3D(Basis(Vector3(-1,0,OUTER_TILT),Vector3.UP,Vector3(0,0,OUTER_DEPTH)),Vector3(0,0,OUTER_SHIFT))
	add_child(outer)
	for id in POINTS:
		points[id]=outer_to_world(POINTS[id]) if String(id).begins_with("ea-") else POINTS[id]
	for id in zones:
		for link in zones[id].links:
			if not POINTS.has(link) or [id,link].has("mer-iroise"): continue
			if not String(id).begins_with("ea-") or not String(link).begins_with("ea-"): continue
			if String(id)<String(link): paths.append([POINTS[id],POINTS[link]])

func inside(p:Vector2)->bool:
	return BOUNDS.has_point(p)

static func outer_to_world(p:Vector2)->Vector2:
	return Vector2(-p.x,OUTER_SHIFT+p.x*OUTER_TILT+p.y*OUTER_DEPTH)

static func world_to_outer(p:Vector2)->Vector2:
	return Vector2(-p.x,(p.y-OUTER_SHIFT+p.x*OUTER_TILT)/OUTER_DEPTH)

static func on_outer_island(p:Vector2)->bool:
	return ISLAND_SOURCE.has_point(world_to_outer(p))

func line_distance(p:Vector2,points:Array)->float:
	var d=INF
	for i in range(points.size()-1):
		d=minf(d,p.distance_squared_to(Geometry2D.get_closest_point_to_segment(p,points[i],points[i+1])))
	return sqrt(d)

func coastal_height(p:Vector2)->float:
	if p.x< -9 or p.x>44 or p.y<38 or p.y>144: return -9.
	var d=line_distance(p,COAST)
	return 3.5-pow(d/5.4,2)*1.4

func river_width_at(segment:float)->float:
	return lerpf(12.,4.65,clampf(segment*.55,0.,1.))

func river_info(p:Vector2)->Vector3:
	var result=Vector3(INF,0,0)
	for i in range(RIVER.size()-1):
		var a:Vector2=RIVER[i]
		var b:Vector2=RIVER[i+1]
		var close=Geometry2D.get_closest_point_to_segment(p,a,b)
		var d=p.distance_squared_to(close)
		if d<result.x:
			var t=a.distance_to(close)/a.distance_to(b)
			var width=river_width_at(i+t)
			if i==1: t=smoothstep(.84,.99,t)
			result=Vector3(d,lerpf(WATER_LEVELS[i],WATER_LEVELS[i+1],t),width)
	return Vector3(sqrt(result.x),result.y,result.z)

func height(p:Vector2)->float:
	var top=town_height(p) if TOWN.has_point(p) else -8.
	if on_outer_island(p):
		top=maxf(top,island_height(world_to_outer(p)))
	return top

func town_height(p:Vector2)->float:
	if TOWN.has_point(p):
		var d=((p-Vector2(63,163))/Vector2(88,70)).length()
		var top=9.2*(1.-d)+noise.get_noise_2d(p.x,p.y)*1.2
		var street=smoothstep(11.,22.,absf(p.x-44))
		var plateau=lerpf(4.4,5.05,street)
		top=lerpf(plateau,top,smoothstep(.53,.83,d))
		if p.y>205 and p.x>26 and p.x<112: top=maxf(top,3.22-(p.y-217)*.61)
		var bay=((p-Vector2(58,238))/Vector2(15.9,27.)).length()
		top=lerpf(-4.2,top,smoothstep(.53,.99,bay))
		return maxf(top,coastal_height(p))
	return -8.

func island_height(p:Vector2)->float:
	if not ISLAND_SOURCE.has_point(p): return -8.
	var n=noise.get_noise_2d(p.x,p.y)
	var coast=((p-Vector2(-329,-5))/Vector2(163,104)).length()
	var top=15.*(1.-coast)+2.6*n
	top+=33.*exp(-p.distance_squared_to(POINTS["ea-pic-braise"])/1850.)
	top-=10.4*exp(-p.distance_squared_to(POINTS["ea-pic-braise"])/53.)
	top+=8.*exp(-p.distance_squared_to(Vector2(-367,-60))/780.)
	if p.x> -222 and p.y>25: top=lerpf(top,2.55,smoothstep(-222.,-190.,p.x))
	if p.distance_to(POINTS["ea-marais-stank"])<26: top=lerpf(top,3.1+n*.66,1.-smoothstep(16.,27.,p.distance_to(POINTS["ea-marais-stank"])))
	var r=river_info(p)
	var river_width=r.z
	var at_ford=p.distance_to(POINTS["ea-gue-lavandieres"])<7.
	var bed=r.y-(.29 if at_ford else 1.35)
	top=lerpf(bed,top,smoothstep(river_width*.68,river_width+7.,r.x))
	if p.x> -245. and p.y>40.:
		for route in OUTER_COAST_ROUTES:
			var verge=1.-smoothstep(2.3,7.,line_distance(p,route))
			var bank=smoothstep(river_width,river_width+1.4,r.x)
			top=lerpf(top,maxf(top,3.35),verge*bank)
	return top

func tint(p:Vector2,h:float)->Color:
	var n=noise.get_noise_2d(p.x*2.5,p.y*2.5)
	if h<1.95: return Color("#bdb292").lerp(Color("#8c917d"),clampf((2.-h)*.16,0.,1.))
	if TOWN.has_point(p): return Color("#839365").lerp(Color("#b2a67f"),clampf(.42+n,0,1))
	if p.x> -219 and p.y>28: return Color("#605e59").lerp(Color("#929084"),n+.5)
	if p.distance_to(POINTS["ea-gorges-rochgwenn"])<37: return Color("#c1bfb4").lerp(Color("#a3a29c"),n+.5)
	if p.distance_to(POINTS["ea-pic-braise"])<40: return Color("#6b5750").lerp(Color("#8d6c56"),n+.5)
	if p.y< -12 and p.x> -400: return Color("#80778b").lerp(Color("#969076"),n+.5)
	return Color("#577358").lerp(Color("#8a956c"),n+.5)

func add_terrain(area:Rect2,step:float,parent:Node3D):
	var nx=ceili(area.size.x/step)+1
	var nz=ceili(area.size.y/step)+1
	var values=PackedFloat32Array()
	values.resize(nx*nz)
	for z in nz:
		for x in nx:
			var p=area.position+Vector2(x,z)*step
			values[z*nx+x]=island_height(p) if parent==outer else town_height(p)
	var mesh=Ink.new()
	for z in range(nz-1):
		for x in range(nx-1):
			var i=z*nx+x
			var high=maxf(maxf(values[i],values[i+1]),maxf(values[i+nx],values[i+nx+1]))
			if high< -2.: continue
			var p=area.position+Vector2(x,z)*step
			var a=Vector3(p.x,values[i],p.y)
			var b=Vector3(p.x+step,values[i+1],p.y)
			var c=Vector3(p.x+step,values[i+nx+1],p.y+step)
			var d=Vector3(p.x,values[i+nx],p.y+step)
			mesh.quad(a,b,c,d,tint(p,(a.y+b.y+c.y+d.y)*.25),Vector3.UP)
	var node=mesh.node(world.mat)
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)

func build():
	add_terrain(TOWN,2.,self)
	for x in 2:
		for z in 2:
			add_terrain(Rect2(ISLAND_SOURCE.position+Vector2(x,z)*Vector2(194,140),Vector2(194,140)),2.,outer)
	build_town()
	build_island()
	for id in ["ea-camp-base","ea-coeur-foret","ea-ker-goz","ea-landes-brug","ea-ruines-veilleurs","ea-camp-garde","ea-crete-vents"]:
		var p:Vector2=points[id]
		for i in 6:
			var place=p+Vector2.from_angle(i*TAU/6.)*(4.8+float(i%2)*1.7)
			if world.ground(place)>2.2 and not world.blocked(place,.35) and water_at(place,0.)<world.ground(place):
				world.add_resource(place,["wood","food","stone"][i%3])

func placed(p:Vector2)->Vector3:
	var h:float=island_height(p) if ISLAND_SOURCE.has_point(p) else world.ground(p)
	return Vector3(p.x,h,p.y)

func road(m,a:Vector2,b:Vector2,width:float,color:Color):
	var side=(b-a).normalized().orthogonal()*width*.5
	var count=maxi(1,ceili(a.distance_to(b)/2.))
	for i in count:
		var p=a.lerp(b,float(i)/count)
		var q=a.lerp(b,float(i+1)/count)
		m.quad(placed(p-side)+Vector3.UP*.075,placed(p+side)+Vector3.UP*.075,
			placed(q+side)+Vector3.UP*.075,placed(q-side)+Vector3.UP*.075,color,Vector3.UP)

func house(m,p:Vector2,s:float,variant:int,chapel:bool=false):
	var v=placed(p)
	var w=(5.2+float(variant%3)*.35)*s
	var d=(6.1+float(variant%2)*.55)*s
	var h=(3.85+float(variant%4)*.46)*s
	var detail=not world.mobile_detail or p.distance_to(START)<32. or s>=1.2
	Architecture.house(m,v,w,d,h,PLASTER[variant%4],SLATE[variant%4],variant,detail,chapel)
	if chapel: Civic.chapel_details(m,v,w,d,h)
	add_footprint(Rect2(p-Vector2(w,d)*.5,Vector2(w,d)))

func wall(m,a:Vector2,b:Vector2,h:float):
	var mid=(a+b)*.5
	var p=placed(mid)
	var delta=b-a
	m.box(p+Vector3.UP*(h*.5-.25),Vector3(delta.length()+.1,h,1.4),STONE,-delta.angle())
	for i in maxi(1,floori(delta.length()/3.2)):
		var q=a.lerp(b,(i+.5)/maxi(1,floori(delta.length()/3.2)))
		m.box(Vector3(q.x,p.y+h-.1,q.y),Vector3(1.15,.8,1.45),DARK_STONE)
	add_footprint(Rect2(a.min(b)-Vector2.ONE*.65,(b-a).abs()+Vector2.ONE*1.3))

func add_footprint(shape:Rect2):
	if ISLAND_SOURCE.has_point(shape.get_center()): outer_footprints.append(shape)
	else: footprints.append(shape)

func sign_at(m,p:Vector2,title:String):
	var pos3=placed(p)
	m.box(pos3+Vector3.UP*.95,Vector3(.18,2.,.18),Art.WOOD)
	m.box(pos3+Vector3.UP*1.84,Vector3(2.1,.54,.19),Art.LWOOD)
	var label=Label3D.new()
	label.text=title
	label.font_size=32
	label.pixel_size=.017
	label.position=pos3+Vector3.UP*2.38
	if ISLAND_SOURCE.has_point(p): label.position=outer.transform*label.position
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=Color("#fff1c9")
	label.outline_modulate=Color("#1b2b29")
	label.visibility_range_end=37.
	add_child(label)

func build_town():
	var m=Ink.new()
	for i in range(COAST.size()-1): road(m,COAST[i],COAST[i+1],4.3,COBBLE)
	for x in [12.,26.,44.,61.,81.,101.]:
		road(m,Vector2(x,133),Vector2(x,208),3.2 if x!=44. else 5.3,COBBLE)
	for z in [140.,157.,176.,194.,207.]:
		road(m,Vector2(8,z),Vector2(105,z),4.,COBBLE)
	var civic=["tv-auberge","tv-forge","tv-apothicaire","tv-chapelle","tv-halle","tv-criee","tv-chantier","tv-moulin","tv-manoir"]
	for row in 7:
		for column in 11:
			var p=Vector2(7+column*9.1,147+row*8.8)
			if p.distance_to(START)<13 or [26.,44.,61.,81.,101.].any(func(x):return absf(x-p.x)<3.5): continue
			if [157.,176.,194.].any(func(z):return absf(z-p.y)<3.1): continue
			if civic.any(func(id):return p.distance_to(POINTS[id])<7.5): continue
			house(m,p,rng.randf_range(.74,1.06),rng.randi_range(0,3))
	for x in [-13.,-4.,117.,127.,137.]:
		for z in [142.,154.,166.,178.,190.,202.]:
			var p=Vector2(x,z)
			if world.ground(p)>2.4:
				house(m,p,rng.randf_range(.8,1.15),rng.randi_range(0,3))
		if world.ground(Vector2(x,162))>2.4:
			road(m,Vector2(x+4.8,135),Vector2(x+4.8,202),2.5,COBBLE)
	for i in civic.size():
		var id:String=civic[i]
		var p:Vector2=POINTS[id]
		sign_at(m,p,zones[id].name)
		var hpos=p+Vector2(0,-5)
		if id=="tv-halle":
			var v=placed(hpos)
			for x in [-4.,4.]:
				for z in [-2.8,2.8]: m.box(v+Vector3(x,1.75,z),Vector3(.37,3.5,.37),Art.WOOD)
			Art.roof(m,v+Vector3.UP*3.5,9.6,1.8,7.5,SLATE[0])
			for stall in [-1.,1.]:
				Architecture.canopy(m,v+Vector3(stall*2.4,0,1.),Color("#8d5c48"))
		else:
			house(m,hpos,1.25 if id in ["tv-chapelle","tv-manoir"] else 1.,i,id=="tv-chapelle")
			if id in ["tv-chapelle","tv-moulin"]:
				var tower=placed(hpos+Vector2(2,-2))
				Architecture.tower(m,tower,1.65,10.8 if id=="tv-chapelle" else 7.7,true)
			if id=="tv-manoir":
				for offset in [Vector2(-4,-3),Vector2(4,-3)]:
					Architecture.tower(m,placed(hpos+offset),1.35,7.4,true)
	var square=placed(START)
	for row in 12:
		for column in 17:
			var x=-8.+column+(row%2)*.22
			var z=-5.6+row
			var surface=placed(START+Vector2(x,z))
			m.box(surface+Vector3.UP*.045,Vector3(.959,.08,.948),COBBLE.lightened(rng.randf_range(-.07,.08)))
	var fountain=square+Vector3(4,0,2)
	m.column(fountain,.65,2.1,2.1,STONE,12)
	m.column(fountain+Vector3.UP*.62,.065,1.7,1.7,Color("#477c7d"),12)
	m.column(fountain,.95,.43,.28,STONE)
	m.column(fountain+Vector3.UP*.94,.11,.82,.75,STONE)
	m.column(fountain+Vector3.UP*1.35,.16,.34,.04,Color("#aaccae"))
	footprints.append(Rect2(START+Vector2(2,0),Vector2(4,4)))
	var bell=square+Vector3(-5,0,0)
	for x in [-1.25,1.25]: m.box(bell+Vector3(x,1.95,0),Vector3(.28,3.9,.28),Art.WOOD)
	m.box(bell+Vector3.UP*3.68,Vector3(2.9,.28,.38),Art.WOOD)
	m.column(bell+Vector3.UP*2.34,1.1,.73,.26,Color("#ac7e37"),12)
	var register_base=placed(RELAY_OFFICE)
	m.box(register_base+Vector3.UP*.54,Vector3(.87,1.07,.78),Art.WOOD)
	m.box(register_base+Vector3.UP*1.09,Vector3(1.23,.12,1.),Art.LWOOD)
	m.box(register_base+Vector3(.10,1.17,.06),Vector3(.64,.033,.45),Color("#e6d0a3"))
	for pair in [[Vector2(36,149),Color("#8b5946")],[Vector2(47,152),Color("#536d70")],[Vector2(53,149),Color("#76774d")]]:
		Architecture.canopy(m,placed(pair[0]),pair[1])
	for x in [3.,56.,91.]:
		if x==3.: wall(m,Vector2(x,133),Vector2(26,133),3.8)
		else: wall(m,Vector2(x-22,133),Vector2(x,133),3.8)
	for x in [23.,37.,90.]:
		var v=placed(Vector2(x,133))
		Architecture.tower(m,v,2.3,7.8,true)
		footprints.append(Rect2(Vector2(x-2,131),Vector2(4,4)))
	var gate=placed(Vector2(30,133))
	Architecture.arch_ring(m,gate,5.1,5.3,2.4,STONE)
	m.box(gate+Vector3.UP*5.82,Vector3(8.4,1.08,2.52),STONE)
	Art.roof(m,gate+Vector3.UP*6.3,8.7,2.4,3.,SLATE[0])
	wall(m,Vector2(4,134),Vector2(4,198),3.45)
	wall(m,Vector2(108,134),Vector2(108,195),3.45)
	for p in [Vector2(4,139),Vector2(4,174),Vector2(4,198),Vector2(108,139),Vector2(108,177),Vector2(108,194)]:
		Architecture.tower(m,placed(p),2.0,5.8,p.y<190)
		footprints.append(Rect2(p-Vector2.ONE*1.7,Vector2.ONE*3.4))
	wall(m,Vector2(6,201),Vector2(36,201),3.3)
	wall(m,Vector2(43,201),Vector2(99,201),3.3)
	var seagate=placed(Vector2(39.5,201))
	Architecture.arch_ring(m,seagate,5.6,4.4,2.,STONE)
	m.box(seagate+Vector3.UP*4.93,Vector3(7.7,1.0,2.3),STONE)
	road(m,Vector2(39,196),Vector2(39,219),4.,COBBLE)
	for x in [39.,49.,65.,88.]:
		for j in 8:
			var z=216.+j*2.1
			m.box(Vector3(x,2.9,z),Vector3(3.6,.24,2.08),Art.LWOOD)
			for dx in [-1.48,1.48]: m.column(Vector3(x+dx,-1.,z),3.8,.19,.15,Art.WOOD,5)
			if j%3==1: Architecture.pier_prop(m,Vector3(x+1.18,3.06,z))
	for p in [Vector3(44,.6,230),Vector3(55,.6,237),Vector3(81,.6,232)]:
		var vessel=Ink.new()
		Art.vessel(vessel)
		var model=vessel.node(world.mat)
		model.position=p
		model.rotation.y=.12 if p.x<50. else -.37
		model.scale=Vector3.ONE*(1.63 if p.x<50. else 1.13)
		add_child(model)
	sign_at(m,Vector2(29,135),"Trois-Vannes")
	sign_at(m,Vector2(14,90),"Phare de Keravel • Route côtière")
	sign_at(m,Vector2(37,220),"Port de Trois-Vannes")
	add_child(m.node(world.mat))

func build_island():
	var m=Ink.new()
	for route in OUTER_COAST_ROUTES:
		for i in range(route.size()-1): road(m,route[i],route[i+1],2.5,Color("#a89270"))
	for pair in paths:
		if pair[0].distance_to(pair[1])<74 and line_distance(pair[0].lerp(pair[1],.5),RIVER)>6:
			road(m,pair[0],pair[1],2.3,Color("#a38e73"))
	var water=Ink.new()
	for i in range(RIVER.size()-1):
		var a:Vector2=RIVER[i]
		var b:Vector2=RIVER[i+1]
		var side=(b-a).normalized().orthogonal()
		for j in 12:
			var p=a.lerp(b,j/12.)
			var q=a.lerp(b,(j+1)/12.)
			var t=j/12.
			var u=(j+1)/12.
			if i==1: t=smoothstep(.84,.99,t);u=smoothstep(.84,.99,u)
			var y=lerpf(WATER_LEVELS[i],WATER_LEVELS[i+1],t)
			var yy=lerpf(WATER_LEVELS[i],WATER_LEVELS[i+1],u)
			var width=river_width_at(i+j/12.)
			var next_width=river_width_at(i+(j+1)/12.)
			var v=Vector3(p.x,y,p.y)
			var w=Vector3(q.x,yy,q.y)
			var o=Vector3(side.x,0,side.y)*width
			var end_offset=Vector3(side.x,0,side.y)*next_width
			water.quad(v-o,v+o,w+end_offset,w-end_offset,Color("#467f72"),Vector3.UP)
			if j%3==0: water.rod(v+Vector3.UP*.06,w+Vector3.UP*.06,.082,.027,Color("#b6d6bc"),4)
	var river_material=ShaderMaterial.new()
	river_material.shader=preload("res://ster_glas.gdshader")
	outer.add_child(water.node(river_material))
	var bridge:Vector2=POINTS["ea-pont-de-corde"]
	for i in 18:
		var z=bridge.y-8.5+i
		m.box(Vector3(bridge.x,7.05,z),Vector3(3.2,.21,1.),Art.LWOOD)
		for dx in [-1.52,1.52]:
			m.rod(Vector3(bridge.x+dx,8.1,z-.5),Vector3(bridge.x+dx,8.1,z+.5),.06,.06,Art.WOOD,4)
			if i%4==0: m.box(Vector3(bridge.x+dx,7.57,z),Vector3(.13,1.12,.13),Art.WOOD)
	var ford:Vector2=POINTS["ea-gue-lavandieres"]
	for i in 8:
		m.blob(Vector3(ford.x,4.21,ford.y-5.2+i*1.48),Vector3(1.65,.27,.91),STONE,i,6)
	for id in ["ea-ker-goz","ea-camp-garde","ea-ruines-veilleurs"]:
		var p:Vector2=POINTS[id]
		for i in 6:
			var q=p+Vector2.from_angle(TAU*i/6.)*rng.randf_range(6.6,9.3)
			if id=="ea-ker-goz": house(m,q,.72,i)
			elif id=="ea-camp-garde":
				var v=placed(q)
				Art.roof(m,v,5.1,2.65,5.,Color("#6f825d"))
			else: m.column(placed(q),rng.randf_range(1.6,4.8),.66,.57,STONE)
	var keep:Vector2=POINTS["ea-citadelle-donjon"]-Vector2(0,7)
	var base=placed(keep)
	for storey in 6:
		var center=base+Vector3.UP*(1.6+3.2*storey)
		var width=11.-storey*.49
		m.box(center,Vector3(width,3.2,width),Color("#697a68").lightened(storey*.016))
		m.box(center+Vector3.UP*1.45,Vector3(width+.48,.29,width+.48),DARK_STONE)
		m.box(center+Vector3(0,.25,width*.5+.12),Vector3(1.04,1.45,.12),Color("#b8e095"))
	add_footprint(Rect2(keep-Vector2.ONE*5.5,Vector2.ONE*11.))
	for z in [-29.,2.]:
		wall(m,Vector2(-469,z),Vector2(-424,z),5.8)
	wall(m,Vector2(-424,-29),Vector2(-424,-17),5.8)
	wall(m,Vector2(-424,-7),Vector2(-424,2),5.8)
	for p in [Vector2(-424,-28),Vector2(-424,1),Vector2(-468,-28),Vector2(-468,1)]:
		Architecture.tower(m,placed(p),2.85,10.8,true)
	var main_gate=placed(Vector2(-425,-11))
	for side in [-1.,1.]:
		Architecture.tower(m,main_gate+Vector3.BACK*(side*4.3),2.0,8.4,false)
	for p in [Vector2(-449,-2),Vector2(-450,-27)]:
		Architecture.tower(m,placed(p),1.8,12.7,true)
	for id in ["ea-mines-vertes","ea-grotte-voile","ea-antre-serpent","ea-antre-aerouant"]:
		var p:Vector2=POINTS[id]
		var v=placed(p)
		for x in [-2.5,2.5]: m.blob(v+Vector3(x,1.9,-1.),Vector3(1.5,2.8,1.8),DARK_STONE,x,6)
		m.blob(v+Vector3(0,4.4,-1.3),Vector3(4.2,1.25,2.3),DARK_STONE,1.,7)
	for i in 18:
		var p=POINTS["ea-landes-brug"]+Vector2.from_angle(TAU*i/18.)*rng.randf_range(10.,18.)
		m.blob(placed(p)+Vector3.UP*1.1,Vector3(.7,rng.randf_range(1.4,3.0),.58),STONE,i,5)
	var crater=placed(POINTS["ea-pic-braise"])
	m.column(crater+Vector3.UP*.38,.16,3.65,3.65,Color("#c55e37"),16)
	m.column(crater+Vector3.UP*.54,.065,2.70,2.7,Color("#e19753"),16)
	for i in 9:
		var p=POINTS["ea-pic-braise"]+Vector2.from_angle(TAU*i/9.)*rng.randf_range(5.4,8.2)
		m.blob(placed(p)+Vector3.UP*.7,Vector3(1.7,1.75,1.43),Color("#5f4a40"),i,7)
	for id in POINTS:
		if String(id).begins_with("ea-"): sign_at(m,POINTS[id]+Vector2(1.8,1.2),zones[id].name)
	outer.add_child(m.node(world.mat))
	var forest=Ink.new()
	var focus:Vector2=POINTS["ea-foret-coat-du"]
	for i in (150 if world.mobile_detail else 275):
		var p=focus+Vector2(rng.randf_range(-55,29),rng.randf_range(-28,33))
		if island_height(p)<2.7 or river_info(p).x<9. or p.distance_to(POINTS["ea-coeur-foret"])<8.: continue
		if paths.any(func(pair): return p.distance_to(Geometry2D.get_closest_point_to_segment(p,pair[0],pair[1]))<3.8): continue
		Art.tree(forest,placed(p),rng.randf_range(.65,1.2),1,float(i))
	outer.add_child(forest.node(world.mat))

func deck_height(p:Vector2,ground:float)->float:
	var river_point=world_to_outer(p)
	var bridge:Vector2=POINTS["ea-pont-de-corde"]
	if absf(river_point.x-bridge.x)<=1.6 and absf(river_point.y-bridge.y)<=9.: return maxf(ground,7.155)
	var ford:Vector2=POINTS["ea-gue-lavandieres"]
	if absf(river_point.x-ford.x)<1.7 and absf(river_point.y-ford.y)<6.5: return maxf(ground,4.26)
	if p.y>=216. and p.y<232.8:
		for x in [39.,49.,65.,88.]:
			if absf(p.x-x)<1.8: return maxf(ground,3.02)
	return ground

func water_at(p:Vector2,sea_level:float)->float:
	var local=world_to_outer(p)
	if not ISLAND_SOURCE.has_point(local): return sea_level
	var river=river_info(local)
	return maxf(sea_level,river.y) if river.x<river.z else sea_level

func chapter_for(id:String)->Dictionary:
	for chapter in chapters:
		for part in chapter.parts:
			if part.zone==id: return chapter
	return {}

func blocked(p:Vector2,margin:float)->bool:
	if TOWN.has_point(p):
		for shape in footprints:
			if shape.grow(margin).has_point(p): return true
	var local=world_to_outer(p)
	if ISLAND_SOURCE.has_point(local):
		for shape in outer_footprints:
			if shape.grow(margin).has_point(local): return true
	return false

func nearest_zone(p:Vector2,radius:float=INF)->String:
	var id=""
	var best=radius*radius
	for zone in points:
		var distance=p.distance_squared_to(points[zone])
		if distance<best:
			best=distance
			id=zone
	return id

func make_chart():
	var size=Vector2i(480,293)
	var image=Image.create_empty(size.x,size.y,false,Image.FORMAT_RGB8)
	for y in size.y:
		for x in size.x:
			var p=BOUNDS.position+Vector2(float(x)/(size.x-1),float(y)/(size.y-1))*BOUNDS.size
			var h:float=world.ground(p)
			var color=Color("#294f5b").lerp(Color("#65928b"),smoothstep(-8.,-.7,h))
			if h>-.7: color=Color("#d3bd90").lerp(Color("#65856a"),smoothstep(1.,15.,h))
			image.set_pixel(x,y,color)
	chart=ImageTexture.create_from_image(image)

func update_ocean_relief(material:ShaderMaterial):
	var size=Vector2i(217,174)
	var image=Image.create_empty(size.x,size.y,false,Image.FORMAT_RF)
	for y in size.y:
		for x in size.x:
			var uv=Vector2(float(x)/(size.x-1),float(y)/(size.y-1))
			var altitude:float=world.ground(BOUNDS.position+BOUNDS.size*uv)
			image.set_pixel(x,y,Color(clampf((altitude+12.)/32.,0.,1.),0,0))
	material.set_shader_parameter("relief",ImageTexture.create_from_image(image))
	material.set_shader_parameter("atlas_origin",BOUNDS.position)
	material.set_shader_parameter("atlas_size",BOUNDS.size)

func story_part(chapter_index:int,part_index:int)->Dictionary:
	return chapters[chapter_index].parts[part_index]
