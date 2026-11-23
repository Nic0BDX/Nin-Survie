extends RefCounted

const Ink=preload("res://meshwork.gd")
const Arch=preload("res://keravel_architecture.gd")
const ENTRY=Vector2(0,6.8)
const EXIT=Vector2(0,7.4)
const FRESCO=Vector2(0,-5.6)
const INSCRIPTION=Vector2(2.8,-4.7)
const STONE=Color("#716e63")
const MORTAR=Color("#474740")
const PAINT=Color("#6f9671")
const OCHRE=Color("#b2895f")

static func blocked(p:Vector2,margin:float=.2)->bool:
	return absf(p.x)>4.1-margin or p.y< -6.9+margin or p.y>7.95-margin

static func silhouette(m,center:Vector3,i:int):
	var p=center+Vector3.BACK*.067
	var ink=Color("#343f39")
	var body=[Vector2(-1.05,-.27),Vector2(-.53,.26),Vector2(.1,.12),Vector2(.55,.46),Vector2(.70,.22),Vector2(.98,.30),Vector2(.90,.03),Vector2(.49,-.22),Vector2(-.15,-.46)]
	var wing=[Vector2(-.63,.04),Vector2(-.68,.86),Vector2(-.18,.65),Vector2(.22,.83),Vector2(.10,.27)]
	for poly in [body,wing]:
		for j in range(1,poly.size()-1):
			var a:Vector2=poly[0]
			var b:Vector2=poly[j]
			var c:Vector2=poly[j+1]
			m.face(p+Vector3(a.x,a.y,0),p+Vector3(b.x,b.y,0),p+Vector3(c.x,c.y,0),ink,Vector3.BACK)
	if i>0:
		var gem=p+Vector3(.60 if i==1 else 1.03,-.02,.023)
		m.quad(gem+Vector3.UP*.18,gem+Vector3.RIGHT*.13,gem+Vector3.DOWN*.18,gem+Vector3.LEFT*.13,PAINT,Vector3.BACK)
	if i==2:
		m.rod(p+Vector3(.26,.12,.018),p+Vector3(.88,-.17,.018),.025,.014,OCHRE,5)

static func create(origin:Vector3,material:Material,lights:bool)->Node3D:
	var room=Node3D.new()
	room.position=origin
	var mesh=Ink.new()
	mesh.box(Vector3(0,-.16,0),Vector3(9.5,.32,17.4),MORTAR)
	mesh.box(Vector3(0,3.8,0),Vector3(9.5,.48,17.4),MORTAR)
	mesh.box(Vector3(0,1.8,-7.4),Vector3(9.5,3.8,.53),STONE)
	mesh.box(Vector3(0,1.8,8.3),Vector3(9.5,3.8,.53),STONE)
	for z in 19:
		for x in 10:
			var p=Vector3(x-4.5+(z%2)*.12,.013,z*.86-7.5)
			mesh.box(p,Vector3(.955,.034,.816),STONE.lightened(float((x*13+z*7)%9)*.012))
	for side in [-1.,1.]:
		mesh.box(Vector3(side*4.38,1.8,.49),Vector3(.55,3.8,16.1),MORTAR)
		for row in 5:
			for stone in 13:
				var p=Vector3(side*4.07,row*.67+.36,stone*1.20-6.87+(row%2)*.11)
				mesh.box(p,Vector3(.21,.60,1.13),STONE.lightened(float((row*17+stone*5)%10)*.016))
		for z in [-5.2,-.5,4.1]:
			mesh.box(Vector3(side*3.95,1.48,z),Vector3(.38,3.05,.45),STONE.darkened(.07))
			mesh.box(Vector3(side*3.78,1.92,z+.73),Vector3(.34,.09,.42),OCHRE.darkened(.27))
			mesh.column(Vector3(side*3.68,1.97,z+.73),.35,.086,.076,Color("#cab689"),6)
			mesh.blob(Vector3(side*3.68,2.36,z+.73),Vector3(.079,.15,.061),Color("#edb36f"),0.,5)
			if lights:
				var candle=OmniLight3D.new()
				candle.position=Vector3(side*3.64,2.3,z+.73)
				candle.light_color=Color("#ffbb76")
				candle.light_energy=.8
				candle.omni_range=5.0
				room.add_child(candle)
	for z in [-5.2,-.5,4.1]:
		Arch.arch_ring(mesh,Vector3(0,0,z),7.6,3.47,.64,STONE.lightened(.09))
	for i in 3:
		var p=Vector3((i-1)*2.58,1.8,-6.99)
		mesh.box(p,Vector3(2.43,2.11,.12),Color("#b09268").darkened(float(i)*.05))
		Arch.arch_ring(mesh,p-Vector3.UP*1.0,2.42,2.12,.14,OCHRE)
		silhouette(mesh,p,i)
		for mark in 5:
			mesh.box(p+Vector3((mark-2)*.33,-.76,.084),Vector3(.19,.028,.013),MORTAR)
	mesh.box(Vector3(2.87,.91,-5.31),Vector3(.82,1.36,.36),STONE.lightened(.17))
	mesh.box(Vector3(2.87,1.63,-5.30),Vector3(.93,.11,.44),OCHRE)
	Arch.arch_ring(mesh,Vector3(0,0,7.88),2.3,2.7,.42,STONE.lightened(.12))
	mesh.box(Vector3(0,1.2,8.02),Vector3(2.26,2.39,.12),Color("#624936"))
	if lights:
		var guide=OmniLight3D.new()
		guide.position=Vector3(0,2.63,-4.1)
		guide.light_color=Color("#d7b08d")
		guide.light_energy=.82
		guide.omni_range=7.
		room.add_child(guide)
	room.add_child(mesh.node(material))
	return room
