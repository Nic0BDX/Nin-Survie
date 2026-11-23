extends RefCounted

const Ink=preload("res://meshwork.gd")
const Civic=preload("res://keravel_civic.gd")
const ENTRY=Vector2(0.,7.35)
const EXIT=Vector2(0.,8.35)
const HATCH=Vector2(3.,-6.2)
const WALKABLE=Rect2(-4.65,-8.65,9.3,17.3)
const BENCH_ROWS=[-4.6,-2.98,-1.36,.26,1.88,3.5,5.12]
const BENCH_DEPTH=.76
const BENCH_CENTERS=[-2.91,2.91]
const BENCH_WIDTH=2.55
const ALTAR=Rect2(-1.48,-7.60,2.96,1.13)
const STONE=Color("#908579")
const LIME=Color("#b6a990")
const MORTAR=Color("#5e5953")
const RIB=Color("#a99b85")
const OAK=Color("#574136")
const WORN_OAK=Color("#826450")
const IRON=Color("#343737")
const BRASS=Color("#ab8348")

static func create(origin:Vector3,material:Material,lights:bool=true)->Node3D:
	var room=Node3D.new()
	room.name="ChapelleInterieur"
	room.position=origin
	var shell=Ink.new()
	shell_geometry(shell,Vector3.ZERO)
	var shell_node=shell.node(material)
	shell_node.name="Enveloppe"
	room.add_child(shell_node)
	var furnishings=Ink.new()
	furnishing_geometry(furnishings,Vector3.ZERO)
	var detail_node=furnishings.node(material)
	detail_node.name="Mobilier"
	room.add_child(detail_node)
	if lights:
		for spec in [[Vector3(0,3.5,3.6),Color("#f3dbb5"),.85,8.4],
			[Vector3(0,3.9,-1.9),Color("#d5d9db"),.86,8.4],
			[Vector3(0,3.46,-6.8),Color("#ecd3a2"),1.12,6.5],
			[Vector3(3.98,1.89,-6.2),Color("#ffd398"),.62,3.5]]:
			var light=OmniLight3D.new()
			light.position=spec[0]
			light.light_color=spec[1]
			light.light_energy=spec[2]
			light.omni_range=spec[3]
			room.add_child(light)
	return room

static func build(m,p:Vector3=Vector3.ZERO):
	shell_geometry(m,p)
	furnishing_geometry(m,p)

static func navigation_blocked(local:Vector2,margin:float=.2)->bool:
	if not WALKABLE.grow(-margin).has_point(local): return true
	if ALTAR.grow(margin).has_point(local): return true
	for cx in BENCH_CENTERS:
		for z in BENCH_ROWS:
			var bench=Rect2(cx-BENCH_WIDTH*.5,z-BENCH_DEPTH*.5,BENCH_WIDTH,BENCH_DEPTH)
			if bench.grow(margin).has_point(local): return true
	return false

static func shell_geometry(m,p:Vector3):
	m.box(p+Vector3.DOWN*.105,Vector3(10.,.20,18.),MORTAR)
	for row in 27:
		for col in 16:
			var x=-5.+col*.625
			var z=-9.+row*(18./27.)
			var variation=.037*float(posmod(row*31+col*13,7)-3)
			var tint=LIME if z< -5.05 else STONE
			m.quad(p+Vector3(x+.012,0,z+.013),p+Vector3(x+.613,0,z+.013),
				p+Vector3(x+.613,0,z+.652),p+Vector3(x+.012,0,z+.652),tint.lightened(variation),Vector3.UP)
	for side in [-1.,1.]:
		m.box(p+Vector3(side*4.89,1.60,0),Vector3(.32,3.20,18.),STONE)
		m.box(p+Vector3(side*4.71,.20,0),Vector3(.128,.40,17.77),MORTAR)
		m.box(p+Vector3(side*4.70,3.05,0),Vector3(.16,.23,17.85),RIB)
		for z in [-7.42,-4.92,-2.42,.08,2.58,5.08,7.58]:
			m.box(p+Vector3(side*4.67,1.57,z),Vector3(.25,3.14,.44),RIB)
			m.box(p+Vector3(side*4.62,.13,z),Vector3(.36,.24,.58),LIME)
			m.box(p+Vector3(side*4.62,2.99,z),Vector3(.39,.19,.59),LIME)
	m.box(p+Vector3(0,1.60,-8.88),Vector3(10.,3.2,.29),STONE)
	m.box(p+Vector3(0,1.60,8.88),Vector3(10.,3.2,.29),STONE)
	var contour=Civic.pointed_outline(4.85,5.94,3.13)
	for i in range(1,contour.size()-2):
		var a=contour[i]
		var b=contour[i+1]
		var a_here=Vector3(a.x,a.y,-8.87)
		var b_here=Vector3(b.x,b.y,-8.87)
		m.quad(p+a_here,p+b_here,p+b_here+Vector3.BACK*17.74,
			p+a_here+Vector3.BACK*17.74,LIME.darkened(.018*float(i%4)),Vector3.DOWN)
	for side in [-1.,1.]:
		for i in range(1,contour.size()-2):
			var a=contour[i]
			var b=contour[i+1]
			var z=side*8.87
			m.quad(p+Vector3(a.x,3.10,z),p+Vector3(b.x,3.10,z),
				p+Vector3(b.x,b.y,z),p+Vector3(a.x,a.y,z),STONE,Vector3.FORWARD*side)
	for z in [-7.42,-4.92,-2.42,.08,2.58,5.08,7.58]:
		for i in range(1,contour.size()-2):
			var a=contour[i]
			var b=contour[i+1]
			var start=Vector3(a.x*.976,a.y-.060,z)
			var end=Vector3(b.x*.976,b.y-.060,z)
			m.rod(p+start,p+end,.100,.100,RIB,5)
		m.box(p+Vector3(0,5.81,z),Vector3(.25,.15,.28),BRASS.darkened(.28))

static func furnishing_geometry(m,p:Vector3):
	for cx in BENCH_CENTERS:
		for z in BENCH_ROWS:
			bench(m,p+Vector3(cx,0,z))
	for side in [-1.,1.]:
		for z in [-6.13,-3.63,-1.13,1.37,3.87,6.37]:
			side_window(m,p,side,z)
		for z in [-7.04,-2.84,1.33,5.5]:
			sconce(m,p+Vector3(side*4.76,1.98,z),side)
	Civic.stone_bay(m,p+Vector3(0,1.47,-8.72),1.03,2.79,true)
	Civic.rose_window(m,p+Vector3(0,4.92,-8.708),.44)
	altar(m,p+Vector3(0.,0.,-7.04))
	exit_doors(m,p+Vector3(0,0,8.708))
	crypt_hatch(m,p+Vector3(HATCH.x,0,HATCH.y))

static func bench(m,p:Vector3):
	m.box(p+Vector3(0,.46,-.025),Vector3(BENCH_WIDTH,.125,.42),WORN_OAK)
	m.box(p+Vector3(0,.80,.264),Vector3(BENCH_WIDTH,.55,.126),OAK)
	m.box(p+Vector3(0,1.072,.258),Vector3(BENCH_WIDTH,.098,.151),WORN_OAK)
	m.box(p+Vector3(0,.337,-.163),Vector3(BENCH_WIDTH,.103,.105),OAK)
	for side in [-1.,1.]:
		var x=side*(BENCH_WIDTH*.5-.086)
		m.box(p+Vector3(x,.265,-.028),Vector3(.168,.53,.54),OAK.darkened(.13))
		m.box(p+Vector3(x,.67,.094),Vector3(.185,.73,.108),OAK)
		m.box(p+Vector3(x,.945,-.008),Vector3(.202,.094,.34),WORN_OAK)

static func side_arch_position(p:Vector3,side:float,z:float,local:Vector2,reveal:float)->Vector3:
	return p+Vector3(side*(4.719-reveal),local.y+1.39,z+local.x)

static func side_window(m,p:Vector3,side:float,z:float):
	var inner=Civic.pointed_outline(.43,1.53,1.06)
	var outer=Civic.pointed_outline(.54,1.64,1.06)
	var center=side_arch_position(p,side,z,Vector2(0,.61),.007)
	var normal=Vector3(-side,0,0)
	for i in inner.size():
		var j=(i+1)%inner.size()
		var a=side_arch_position(p,side,z,inner[i],.007)
		var b=side_arch_position(p,side,z,inner[j],.007)
		m.face(center,a,b,Civic.GLASS[i%Civic.GLASS.size()],normal)
		if i<inner.size()-1:
			var c=side_arch_position(p,side,z,outer[i],.075)
			var d=side_arch_position(p,side,z,outer[j],.075)
			m.quad(a,b,d,c,RIB.lightened(float(i%3)*.04),normal)
		if i%3==0:
			m.rod(center+normal*.012,a+normal*.012,.018,.018,IRON,4)
	m.box(p+Vector3(side*4.66,1.33,z),Vector3(.18,.13,1.16),LIME)

static func sconce(m,p:Vector3,side:float):
	m.box(p,Vector3(.076,.34,.204),IRON)
	var tip=p-Vector3(side*.235,-.06,0)
	m.rod(p,tip,.033,.039,IRON,5)
	m.column(tip,.085,.114,.085,BRASS,8)
	m.column(tip+Vector3.UP*.085,.17,.049,.043,Color("#dec09a"),6)
	m.column(tip+Vector3.UP*.245,.108,.045,.004,Color("#ffbd57"),7)

static func altar(m,p:Vector3):
	m.box(p+Vector3.UP*.085,Vector3(2.94,.17,1.12),MORTAR)
	m.box(p+Vector3.UP*.57,Vector3(2.49,.97,.83),LIME)
	m.box(p+Vector3.UP*1.09,Vector3(2.87,.20,1.08),RIB.lightened(.07))
	m.box(p+Vector3(0,.62,.431),Vector3(.65,.646,.049),RIB.darkened(.12))
	m.box(p+Vector3(0,.64,.482),Vector3(.083,.42,.037),BRASS)
	m.box(p+Vector3(0,.708,.482),Vector3(.29,.084,.037),BRASS)
	m.box(p+Vector3.UP*1.198,Vector3(1.20,.034,.84),Color("#d7c4a5"))
	m.box(p+Vector3(0,1.199,.20),Vector3(.49,.027,.34),OAK.darkened(.08))
	for side in [-1.,1.]:
		var candle=p+Vector3(side*1.08,1.19,-.02)
		m.column(candle,.058,.115,.082,BRASS,8)
		m.column(candle+Vector3.UP*.058,.32,.048,.045,Color("#e1c4a0"),7)
		m.column(candle+Vector3.UP*.373,.135,.043,.005,Color("#ffb759"),7)

static func exit_doors(m,p:Vector3):
	var contour=Civic.pointed_outline(.91,2.74,1.67)
	var center=p+Vector3.UP*1.05
	for i in contour.size():
		var a=contour[i]
		var b=contour[(i+1)%contour.size()]
		m.face(center,p+Vector3(a.x,a.y,-.019),p+Vector3(b.x,b.y,-.019),OAK.darkened(.19),Vector3.FORWARD)
	for plank in range(-4,5):
		var x=plank*.184
		var height=1.67+(2.74-1.67)*(1.-absf(x)/.91)*.82
		m.box(p+Vector3(x,height*.5,-.036),Vector3(.018,height,.023),OAK.lightened(.12))
	for y in [.47,1.36]:
		m.box(p+Vector3(0,y,-.053),Vector3(1.62,.067,.033),IRON)
	m.box(p+Vector3(.13,1.036,-.097),Vector3(.105,.102,.095),BRASS)

static func crypt_hatch(m,p:Vector3):
	m.box(p+Vector3.UP*.041,Vector3(1.21,.084,1.39),MORTAR)
	m.box(p+Vector3.UP*.070,Vector3(1.03,.052,1.19),WORN_OAK.darkened(.30))
	for plank in range(-2,3):
		m.box(p+Vector3(plank*.192,.101,0),Vector3(.021,.015,1.13),OAK.lightened(.10))
	for z in [-.39,.39]:
		m.box(p+Vector3(0,.111,z),Vector3(1.03,.038,.075),IRON)
	m.rod(p+Vector3(-.11,.121,.254),p+Vector3(-.11,.18,.254),.022,.022,BRASS,5)
	m.rod(p+Vector3(-.11,.18,.254),p+Vector3(.11,.18,.254),.022,.022,BRASS,5)
	m.rod(p+Vector3(.11,.18,.254),p+Vector3(.11,.121,.254),.022,.022,BRASS,5)
