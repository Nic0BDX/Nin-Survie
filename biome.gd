extends Node3D
const Ink=preload("res://meshwork.gd")
const Art=preload("res://art.gd")
const GRID=2.0
const NX=121
const NZ=101
const ORIGIN=Vector2(-120,-100)
const LIGHT=Vector2(-7,15)
const SPAWN=Vector2(1,33)
const SITES=[Vector2(-61,3),Vector2(-20,-51),Vector2(56,-20)]
const TITLES=["Le Courlis","La Corne de brume","L’atelier des Salines"]
const PARTS=["Lentille de Fresnel","Réflecteur de cuivre","Dynamo marine"]
const ISLANDS=[
	[3,25,37,26,8.8],[-60,16,20,16,5.0],[-19,-50,24,18,10.8],[56,-20,22,21,7.8],
	[-65,-38,12,14,9.7],[48,43,14,10,5.8],[18,-68,10,12,7.0],[-92,1,7,9,4.0],[85,17,9,12,6.7]]
const PATHS=[
	[Vector2(-16,26),Vector2(-43,24),6.7],[Vector2(-43,24),Vector2(-55,17),6.0],
	[Vector2(-6,8),Vector2(-15,-12),6.5],[Vector2(-15,-12),Vector2(-29,-31),5.4],[Vector2(-29,-31),Vector2(-21,-44),6.4],
	[Vector2(20,15),Vector2(34,5),6.1],[Vector2(34,5),Vector2(44,-8),5.5],
	[Vector2(20,32),Vector2(44,41),4.1]]
const TRAILS=[
	[Vector2(7,44),Vector2(1,33)],[Vector2(1,33),Vector2(-1,26)],[Vector2(-1,26),Vector2(-5,19)],[Vector2(-5,19),Vector2(-7,17)],
	[Vector2(-1,26),Vector2(-14,28)],[Vector2(-14,28),Vector2(-23,25)],[Vector2(-23,25),Vector2(-34,24)],
	[Vector2(-5,19),Vector2(-4,11)],[Vector2(-4,11),Vector2(-13,-4)],
	[Vector2(-1,26),Vector2(11,23)],[Vector2(11,23),Vector2(23,14)],[Vector2(23,14),Vector2(33,6)],
	[Vector2(-43,24),Vector2(-56,18)],[Vector2(-56,18),Vector2(-58,7)],
	[Vector2(-27,-32),Vector2(-23,-40)],[Vector2(-23,-40),Vector2(-20,-48)],
	[Vector2(43,-7),Vector2(50,-10)],[Vector2(50,-10),Vector2(57,-17)]]
var heights=PackedFloat32Array()
var pigments=PackedColorArray()
var mat=Ink.palette()
var sea:MeshInstance3D
var water_mat:ShaderMaterial
var sky_mat:ShaderMaterial
var env:Environment
var sun:DirectionalLight3D
var light_base:Vector3
var spots=[]
var resources=[]
var blocks=[]
var building_footprints:Array[Rect2]=[]
var noise=FastNoiseLite.new()
var rng=RandomNumberGenerator.new()
var relief:ImageTexture
var map_tex:ImageTexture
var deposit_models={}
var marker_models={}
var vegetation={}
var cover_cells={}
var veg_meshes={}
var gulls=[]
var flag_nodes=[]
var beam:Node3D
var beacon_lens:MeshInstance3D
var bloom:Sprite3D
var current_water=0.0
var birdmesh:Mesh
var gull_left:Mesh
var gull_right:Mesh
var shore=preload("res://shore.gd").new()

func _ready():
	rng.seed=443122
	noise.seed=8361
	noise.frequency=.063
	noise.fractal_octaves=3
	environment_setup()
	terrain()
	ocean()
	landmarks()
	shore.install(self)
	nature()
	populate()
	birds()

func environment_setup():
	env=Environment.new()
	env.background_mode=Environment.BG_SKY
	sky_mat=ShaderMaterial.new()
	sky_mat.shader=preload("res://sky.gdshader")
	env.sky=Sky.new()
	env.sky.radiance_size=Sky.RADIANCE_SIZE_32
	env.sky.process_mode=Sky.PROCESS_MODE_REALTIME
	env.sky.sky_material=sky_mat
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("#e8efdc")
	env.ambient_light_energy=.67
	env.reflected_light_source=Environment.REFLECTION_SOURCE_DISABLED
	env.fog_enabled=true
	env.fog_density=.0025
	env.fog_sky_affect=.08
	env.fog_light_color=Color("#b2c9c1")
	var we=WorldEnvironment.new()
	we.environment=env
	add_child(we)
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-33,0)
	sun.light_color=Color("#ffe2b2")
	sun.light_energy=1.0
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=82
	sun.shadow_bias=.1
	add_child(sun)

func field(p:Vector2)->float:
	var n=noise.get_noise_2d(p.x,p.y)
	var n2=noise.get_noise_2d(p.x*.46+81,p.y*.46-29)
	var top=-8.0
	for r in ISLANDS:
		var dx=(p.x-r[0])/r[2]
		var dz=(p.y-r[1])/r[3]
		var dist=sqrt(dx*dx+dz*dz)
		var dist2=dist+n*.075+n2*.11
		var land=(1.0-dist2)*r[4]*1.53+sin(dx*6+dz*3)*.42+n*.84
		# Gently rolling summits leave flat pockets for camps.
		if land>r[4]*.71: land=r[4]*.71+(land-r[4]*.71)*.32
		top=max(top,land)
	var channel=-8.0
	for pair in PATHS:
		var close=Geometry2D.get_closest_point_to_segment(p,pair[0],pair[1])
		var d=p.distance_to(close)
		channel=max(channel,1.02-(d/pair[2])*(d/pair[2])*1.13+n*.78+n2*.42)
	var height=max(top,channel)+.09*n
	var keel=(p-SITES[0])/Vector2(4.9,7.2)
	if keel.length()<1.65:
		var bank=smoothstep(.71,1.65,keel.length())
		height=lerpf(.14+n*.20,height,bank)
	return preload("res://marais.gd").terrain(p,height)

func tint(h:float,n:float,p:Vector2)->Color:
	var sand=Color("#d6bd8d").lerp(Color("#e2cda0"),clamp(.5+n,0,1))
	var green=Color("#658358").lerp(Color("#91a467"),clamp(.43+n*1.3,0,1))
	if p.distance_to(Vector2(-19,-50))<24: green=green.lerp(Color("#a6a38d"),.35)
	if p.distance_to(Vector2(58,-19))<25: green=green.lerp(Color("#bb9c68"),.23)
	if h<-.9: return Color("#99a99a").lerp(sand,clampf((h+3)/2.1,0.,1.))
	if h<1.22: return sand
	if h<2.00+n*.8: return sand.lerp(Color("#b6b080"),clampf((h-1.22)*1.1,0,1))
	if h<2.85+n*.9: return Color("#b6b080").lerp(green,clampf(h-1.7,0,1))
	return green

func trail(p:Vector2)->float:
	var near=99.
	for seg in TRAILS:
		var pt=Geometry2D.get_closest_point_to_segment(p,seg[0],seg[1])
		near=minf(near,p.distance_squared_to(pt))
	return sqrt(near)

func terrain():
	var hm=Image.create_empty(NX,NZ,false,Image.FORMAT_RF)
	heights.resize(NX*NZ)
	pigments.resize(NX*NZ)
	for z in NZ:
		for x in NX:
			var p=ORIGIN+Vector2(x,z)*GRID
			var h=field(p)
			var n=noise.get_noise_2d(p.x*.68+24,p.y*.68-93)
			var col=tint(h,n,p)
			if preload("res://marais.gd").extent(p)<1.1: col=Color("#947565").lerp(Color("#b0ad89"),smoothstep(.85,2.6,h))
			if h>1.30:
				var path_mix=1.-smoothstep(.7,2.25,trail(p)+n*.45)
				col=col.lerp(Color("#997c63").lerp(Color("#b19870"),n+.45),path_mix*.90)
			heights[z*NX+x]=h
			pigments[z*NX+x]=col
			hm.set_pixel(x,z,Color((h+12)/32.,0,0))
	relief=ImageTexture.create_from_image(hm)
	draw_chart()
	var m=Ink.new()
	for z in range(NZ-1):
		for x in range(NX-1):
			var i=z*NX+x
			var a=Vector3(ORIGIN.x+x*GRID,heights[i],ORIGIN.y+z*GRID)
			var b=Vector3(a.x+GRID,heights[i+1],a.z)
			var c=Vector3(a.x+GRID,heights[i+NX+1],a.z+GRID)
			var d=Vector3(a.x,heights[i+NX],a.z+GRID)
			var v=pigments[i].lerp(pigments[i+1],.42).lerp(pigments[i+NX+1],.28)
			m.face(a,b,c,v,Vector3.UP)
			m.face(a,c,d,pigments[i].lerp(pigments[i+NX],.42).lerp(pigments[i+NX+1],.28),Vector3.UP)
	var terrain_node=m.node(mat)
	terrain_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(terrain_node)

func ground(p:Vector2)->float:
	var v=(p-ORIGIN)/GRID
	var x=clampi(floori(v.x),0,NX-2)
	var z=clampi(floori(v.y),0,NZ-2)
	var a=clampf(v.x-x,0,1)
	var b=clampf(v.y-z,0,1)
	var i=z*NX+x
	if a>b: return heights[i]*(1-a)+heights[i+1]*(a-b)+heights[i+NX+1]*b
	return heights[i]*(1-b)+heights[i+NX]*(b-a)+heights[i+NX+1]*a

func draw_chart():
	var chart=Image.create_empty(540,450,false,Image.FORMAT_RGB8)
	var ocean_ink=Color("#315a62")
	var sands=Color("#d5c39c")
	for j in 450:
		for i in 540:
			var p=ORIGIN+Vector2(i/539.*240.,j/449.*200.)
			var h=ground(p)
			var paper=ocean_ink.lerp(Color("#608985"),smoothstep(-7.8,-.70,h))
			if h>-.82:
				paper=Color("#a5b49a").lerp(sands,smoothstep(-.82,1.9,h))
				if h>1.9: paper=sands.lerp(Color("#859b7f"),smoothstep(1.9,10.,h))
			var ink=0.
			if h>-.60: ink=(1.-smoothstep(.035,.16,abs(fposmod(h+.76,1.5)-.75)))*.16
			elif h>-7.75: ink=(1.-smoothstep(.04,.18,abs(fposmod(h+1.,2.)-1.)))*.14
			var grain=.013*(.5+.5*sin(i*19.06+j*53.37))
			chart.set_pixel(i,j,paper.darkened(ink+grain))
	map_tex=ImageTexture.create_from_image(chart)

func pos(p:Vector2)->Vector3:
	return Vector3(p.x,ground(p),p.y)

func on_pier(p:Vector2)->bool:
	return absf(p.x-11.5)<1.18 and p.y>=46.38 and p.y<=53.96

func ocean():
	sea=MeshInstance3D.new()
	var plane=PlaneMesh.new()
	plane.size=Vector2(1600,1600)
	plane.subdivide_width=200
	plane.subdivide_depth=200
	sea.mesh=plane
	water_mat=ShaderMaterial.new()
	water_mat.shader=preload("res://sea.gdshader")
	water_mat.set_shader_parameter("relief",relief)
	sea.material_override=water_mat
	sea.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sea)
	# Outer sea stacks break the horizon and give the archipelago a silhouette.
	var distant=Ink.new()
	for i in 42:
		var a=TAU*i/42+rng.randf_range(-.06,.06)
		var r=rng.randf_range(190,305)
		var scale3=Vector3(rng.randf_range(8,32),rng.randf_range(5,20),rng.randf_range(7,21))
		distant.blob(Vector3(cos(a)*r,-3.9,sin(a)*r),scale3,Color("#566e70"),a*2,7)
	add_child(distant.node(mat))

func flag_at(p:Vector3,size:float,col:Color):
	var k=Ink.new()
	k.column(Vector3.ZERO,size*2.8,.05*size,.03*size,Art.WOOD,6)
	var pole=k.node(mat)
	pole.position=p
	add_child(pole)
	var cloth=Ink.new()
	cloth.quad(Vector3.ZERO,Vector3(1.14,-.05,.11)*size,Vector3(1.20,-.52,.09)*size,Vector3(0,-.49,0)*size,col,Vector3.BACK)
	cloth.face(Vector3(1.14,-.05,.11)*size,Vector3(1.70,-.31,-.07)*size,Vector3(1.20,-.52,.09)*size,col.darkened(.08),Vector3.BACK)
	var f=cloth.node(mat)
	f.position=p+Vector3.UP*size*2.7
	add_child(f)
	flag_nodes.append(f)

func landmarks():
	var m=Ink.new()
	light_base=pos(LIGHT)
	Art.lighthouse(m,light_base)
	blocks.append([LIGHT,2.50])
	var cottage=LIGHT+Vector2(-5.2,-2.1)
	Art.hut(m,pos(cottage),.83,true)
	building_footprints.append(Rect2(cottage-Vector2(2.25,2.8)*.83,Vector2(4.5,5.6)*.83))
	Art.signpost(m,pos(Vector2(.6,26.7)),.35)
	flag_at(light_base+Vector3(2.6,0,1.45),1.35,Art.RED)
	Art.wreck(m,pos(SITES[0]))
	Art.ruin(m,pos(SITES[1]))
	var hutp=SITES[2]+Vector2(0,-2.9)
	Art.hut(m,pos(hutp),1.12,true)
	building_footprints.append(Rect2(hutp-Vector2(2.25,2.8)*1.12,Vector2(4.5,5.6)*1.12))
	for i in 4:
		var q=SITES[2]+Vector2(3.9+i*.75,1.15+.32*sin(i))
		Art.marine(m,pos(q))
	for i in 4:
		var q=Vector2(2.3+i*1.9,35.8+.49*i)
		m.column(pos(q),1.14,.115,.10,Art.WOOD,6)
		if i>0:
			var prev=Vector2(2.3+(i-1)*1.9,35.8+.49*(i-1))
			var a=pos(prev)+Vector3.UP
			var b=pos(q)+Vector3.UP
			var c=a.lerp(b,.5)-Vector3.UP*.19
			m.rod(a,c,.039,.039,Art.CREAM,4)
			m.rod(c,b,.039,.039,Art.CREAM,4)
	for i in 3:
		var q=SITES[i]+[Vector2(2.7,3.0),Vector2(-.3,2.7),Vector2(1,2.8)][i]
		spots.append(q)
		Art.chest(m,pos(q))
		flag_at(pos(q+Vector2(1.2,-.15)),.88,Art.GOLD)
	for pair in PATHS:
		var q=pair[0].lerp(pair[1],.56)+Vector2(2.2,0)
		Art.marine(m,pos(q))
	# An abandoned dinghy near the landing point.
	var ding=pos(Vector2(8,43))
	for side in [-1,1]:
		m.rod(ding+Vector3(0,.2,-2.4),ding+Vector3(side*.95,.4,0),.18,.21,Art.RED,5)
		m.rod(ding+Vector3(side*.95,.4,0),ding+Vector3(side*.56,.35,2.0),.21,.18,Art.RED,5)
	m.box(ding+Vector3(0,.27,0),Vector3(1.5,.2,2.7),Art.WOOD)
	m.box(ding+Vector3(0,.53,.3),Vector3(1.73,.15,.43),Art.LWOOD)
	add_child(m.node(mat))
	beam=Node3D.new()
	beam.position=light_base+Vector3.UP*13.44
	add_child(beam)
	var lightmat=StandardMaterial3D.new()
	lightmat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	lightmat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	lightmat.cull_mode=BaseMaterial3D.CULL_DISABLED
	lightmat.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
	lightmat.albedo_color=Color(1,.88,.54,.16)
	var mb=Ink.new()
	mb.rod(Vector3(.1,0,0),Vector3(82,-2.5,0),.42,4.7,Color.WHITE,16)
	var cone=mb.node(lightmat)
	cone.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.add_child(cone)
	var lensmat=StandardMaterial3D.new()
	lensmat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	lensmat.albedo_color=Color("#fff4b8")
	var lensgeo=Ink.new()
	lensgeo.blob(Vector3.ZERO,Vector3(.79,.62,.79),Color.WHITE,.3,12)
	beacon_lens=lensgeo.node(lensmat);beam.add_child(beacon_lens)
	var halo=Image.create_empty(96,96,false,Image.FORMAT_RGBA8)
	for y in 96:
		for x in 96:
			var d=Vector2(x-47.5,y-47.5).length()/47.5
			var strength=pow(maxf(0.,1.-d),3.)*.68
			halo.set_pixel(x,y,Color(1.,.86,.49,strength))
	bloom=Sprite3D.new()
	bloom.texture=ImageTexture.create_from_image(halo)
	bloom.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	bloom.pixel_size=.086
	bloom.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.add_child(bloom)
	beam.visible=false

func blocked(p:Vector2,extra:float=0.0)->bool:
	for footprint in building_footprints:
		if footprint.grow(extra).has_point(p): return true
	for b in blocks:
		if p.distance_to(b[0])<b[1]+extra: return true
	return false

func make_veg(key:String,builder):
	veg_meshes[key]=builder.mesh(mat)
	vegetation[key]=[]

func scatter(key:String,p:Vector2,scale3:Vector3,yaw:float=0):
	var basis=Basis(Vector3.UP,yaw).scaled(scale3)
	vegetation[key].append(Transform3D(basis,pos(p)-Vector3.UP*.045))

func nature():
	for i in 6:
		var m=Ink.new()
		Art.tree(m,Vector3.ZERO,1.0,1 if i>=4 else 0,i*1.73)
		make_veg("tree"+str(i),m)
	for i in 4:
		var m=Ink.new()
		m.blob(Vector3(0,.17,0),Vector3(1.12,.79,.88),[Color("#8d9997"),Color("#a4aaa1"),Color("#7b8688"),Color("#b6b5a3")][i],i*1.41)
		make_veg("rock"+str(i),m)
		m=Ink.new()
		Art.flowers(m,Vector3.ZERO,1,i)
		make_veg("flower"+str(i),m)
		m=Ink.new()
		Art.grass(m,Vector3.ZERO,1,i)
		make_veg("grass"+str(i),m)
	for i in 32000:
		var p=Vector2(rng.randf_range(-105,97),rng.randf_range(-83,64))
		var h=ground(p)
		if h<-.75 or preload("res://marais.gd").extent(p)<1.12: continue
		var tp=trail(p)
		if tp<1.35: continue
		var protected=tp<2.5 or p.distance_to(SPAWN)<6.5 or p.distance_to(LIGHT)<6 or p.distance_to(SITES[0])<6 or p.distance_to(SITES[1])<5.4 or p.distance_to(SITES[2])<6.5
		var variant=rng.randi()%4
		var angle=rng.randf()*TAU
		var s=rng.randf_range(.7,1.52)
		var grove=noise.get_noise_2d(p.x*.67+10,p.y*.67+30)
		if i<5200 and h>2.6 and grove>.14 and not protected:
			if blocked(p,1.6): continue
			var kind=rng.randi_range(0,5)
			scatter("tree"+str(kind),p,Vector3.ONE*s,angle)
			blocks.append([p,.33*s])
		elif i<6300 and (h<2.6 or grove<-.31) and not protected:
			var rock_scale=s*(1.55 if h<1.1 and i%4==0 else .53)
			scatter("rock"+str(variant),p,Vector3.ONE*rock_scale,angle)
		elif h>2.05 and i%5==0 and grove<.08:
			var patch_type=clampi(floori((noise.get_noise_2d(p.x*.22-29,p.y*.22+50)+.52)*4),0,3)
			scatter("flower"+str(patch_type),p,Vector3.ONE*s*.78,angle)
		elif h>1.6 and i%2==0:
			scatter("grass"+str(variant),p,Vector3.ONE*s*.79,angle)
	for key in vegetation:
		var matrices=vegetation[key]
		if matrices.is_empty(): continue
		var mm=MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=veg_meshes[key]
		mm.instance_count=matrices.size()
		for i in matrices.size():
			var tr:Transform3D=matrices[i]
			mm.set_instance_transform(i,tr)
			if not key.begins_with("tree"):
				var pt=Vector2(tr.origin.x,tr.origin.z)
				var cell=Vector2i((pt/4.).floor())
				if not cover_cells.has(cell): cover_cells[cell]=[]
				cover_cells[cell].append([mm,i,tr,pt])
		var node=MultiMeshInstance3D.new()
		node.multimesh=mm
		if key.begins_with("grass") or key.begins_with("flower"): node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
	vegetation.clear()

func add_resource(p:Vector2,kind:String):
	var n=MeshInstance3D.new()
	n.mesh=deposit_models[kind]
	n.position=pos(p)
	var yaw=rng.randf()*TAU
	var up=Vector3(ground(p-Vector2(.35,0))-ground(p+Vector2(.35,0)),.70,ground(p-Vector2(0,.35))-ground(p+Vector2(0,.35))).normalized()
	var right=Vector3(cos(yaw),0,-sin(yaw))
	var front=right.cross(up).normalized()
	n.basis=Basis(up.cross(front).normalized(),up,front)
	add_child(n)
	resources.append({"at":p,"kind":kind,"node":n,"ready":0.0,"covered":false})

func covered(p:Vector2,items:Array)->bool:
	for it in items:
		var diff=p-it.at
		if it.kind in ["floor","bridge"] and absf(diff.x)<1.92 and absf(diff.y)<1.92: return true
		if it.kind=="shelter" and absf(diff.x)<1.78 and absf(diff.y)<1.78: return true
		if it.kind in ["fire","trap"] and diff.length_squared()<.85: return true
	return false

func cover_terrain(p:Vector2,items:Array,time:float):
	var center=Vector2i((p/4.).floor())
	for j in range(-1,2):
		for i in range(-1,2):
			for bit in cover_cells.get(center+Vector2i(i,j),[]):
				var tr:Transform3D=bit[2]
				if covered(bit[3],items): tr.origin.y-=32.
				bit[0].set_instance_transform(bit[1],tr)
	for res in resources:
		if res.at.distance_squared_to(p)<16.:
			res.covered=covered(res.at,items)
			res.node.visible=not res.covered and res.ready<=time

func populate():
	for k in ["wood","stone","food"]:
		var m=Ink.new()
		Art.resource(m,k)
		deposit_models[k]=m.mesh(mat)
	for e in [[Vector2(2.0,30.3),"wood"],[Vector2(-1.4,32.6),"stone"],[Vector2(4.6,33.5),"food"],[Vector2(6.5,28.6),"wood"],[Vector2(-3.2,28.3),"stone"],[Vector2(-.8,24.7),"wood"]]:
		add_resource(e[0],e[1])
	for i in 2200:
		if resources.size()>=200: break
		var p=Vector2(rng.randf_range(-85,85),rng.randf_range(-73,59))
		var h=ground(p)
		if h<-.45 or blocked(p,.50) or p.distance_to(LIGHT)<4.0: continue
		var close=false
		for q in resources:
			if p.distance_squared_to(q.at)<19.: close=true; break
		if close: continue
		for q in spots:
			if p.distance_to(q)<3.5: close=true
		if close: continue
		var kind=["wood","stone","food","wood"][rng.randi()%4]
		if h<1.5 and kind=="food": kind="wood"
		add_resource(p,kind)

func birds():
	var m=Ink.new()
	m.blob(Vector3.ZERO,Vector3(.18,.13,.48),Art.CREAM,2,6)
	m.rod(Vector3(0,0,-.35),Vector3(0,-.03,-.67),.09,.009,Art.GOLD,5)
	birdmesh=m.mesh(mat)
	for side in [-1,1]:
		var wing=Ink.new()
		var elbow=Vector3(side*.71,.16,.06)
		wing.face(Vector3(side*.05,.04,-.25),elbow,Vector3(side*.14,0,.34),Art.CREAM,Vector3.UP)
		wing.face(elbow,Vector3(side*.14,0,.34),Vector3(side*.77,.13,.26),Art.CREAM,Vector3.UP)
		wing.face(elbow,Vector3(side*.77,.13,.26),Vector3(side*1.34,-.06,.45),Art.DARK,Vector3.UP)
		if side==-1: gull_left=wing.mesh(mat)
		else: gull_right=wing.mesh(mat)
	for i in 13:
		var bird=MeshInstance3D.new()
		bird.mesh=birdmesh
		for w in [gull_left,gull_right]:
			var wing=MeshInstance3D.new()
			wing.mesh=w
			bird.add_child(wing)
		add_child(bird)
		gulls.append(bird)

func atmosphere(time:float,tide:float,night:float,storm:float,lit:bool):
	current_water=tide
	sea.position.y=tide
	water_mat.set_shader_parameter("darkness",night)
	water_mat.set_shader_parameter("squall",storm)
	sky_mat.set_shader_parameter("darkness",night)
	sky_mat.set_shader_parameter("squall",storm)
	env.ambient_light_color=Color("#d9e2e7").lerp(Color("#7995ac"),night*.94)
	env.ambient_light_energy=.48-night*.13
	env.fog_light_color=Color("#b9ccbf").lerp(Color("#63768d"),night*.92).lerp(Color("#849d9a"),storm*.57)
	env.fog_density=.0031+night*.0009+storm*.007
	sun.light_color=Color("#ffe9cf").lerp(Color("#f3a888"),sin(night*PI)*.7).lerp(Color("#9ab6d9"),night)
	sun.light_energy=.59-night*.40-storm*.12
	sun.rotation_degrees=Vector3(-43+night*19,-38+sin(time*.008)*24,0)
	for i in gulls.size():
		var t=time*(.13+i*.003)+i*2.39
		var p=Vector3(-10+cos(t)*(16.0+i*2.5),13+i*.55+sin(t*2.1),13+sin(t)*(9.0+i*2.7))
		gulls[i].position=p
		gulls[i].rotation.y=atan2(sin(t)*(16.+i*2.5),-cos(t)*(9.+i*2.7))
		var flap=sin(time*4+i)*.21+sin(t)*.12
		gulls[i].get_child(0).rotation.z=-flap
		gulls[i].get_child(1).rotation.z=flap
	for i in flag_nodes.size(): flag_nodes[i].rotation.y=.25*sin(time*2.4+i)+.11*sin(time*5+i)
	beam.visible=lit
	beam.rotation.y=time*.64
	bloom.modulate.a=.76+.22*sin(time*2.)
	shore.animate(self,time,tide)

func region(p:Vector2)->String:
	if preload("res://marais.gd").extent(p)<1.2: return "Marais des Trois-Vannes"
	if p.distance_to(SITES[0])<25: return "Les Bancs du Courlis"
	if p.distance_to(SITES[1])<27: return "Îlot de la Corne"
	if p.distance_to(SITES[2])<25: return "Les Salines"
	if p.distance_to(Vector2(-65,-38))<15: return "Les Dents de granit"
	if p.distance_to(Vector2(48,43))<14: return "Île de la Veuve"
	if p.distance_to(Vector2(4,26))<31: return "Pointe de Keravel"
	return "Le Grand Estran"
