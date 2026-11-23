extends Node3D
const Ink=preload("res://meshwork.gd")
const Art=preload("res://art.gd")
const KINDS=["fire","bridge","shelter","trap","skiff","floor","wall","door","roof"]
const FITTINGS=["wall","door","roof"]
const NAMES={"fire":"Feu de camp","bridge":"Passerelle","shelter":"Abri de toile","trap":"Casier à marée","skiff":"Yole à voile","floor":"Plancher sur pilotis","wall":"Mur de planches","door":"Encadrement","roof":"Toit à deux pans"}
const COST={"fire":[3,2],"bridge":[2,0],"shelter":[6,2],"trap":[3,1],"skiff":[10,3],"floor":[3,1],"wall":[2,0],"door":[2,0],"roof":[4,0]}
const DESCRIPTIONS={"fire":"Sa chaleur répare les forces et tient les noyés à distance.","bridge":"Un tablier sur pilotis pour franchir les passes même à pleine mer.","shelter":"Un camp de repli. Une ration permet d’y dormir jusqu’à l’aube.","trap":"Pose-le dans l’estran. La marée le remplit de poisson.","skiff":"Mets-la à flot pour gagner les îlots du large. Le vent gonfle sa voile.","floor":"La base de ta cabane. Assemble plusieurs planchers pour agrandir sa surface.","wall":"Ferme un côté du plancher. Utilise R pour sélectionner le bord à équiper.","door":"Un panneau ouvert pour entrer et sortir. Il se fixe en bord de plancher.","roof":"Coiffe une travée et protège du grain. Une ration permet d’y dormir."}
const CELL=3.6
const DECK=2.76
var items=[]
var models={}
var ghost:MeshInstance3D
var good=StandardMaterial3D.new()
var bad=StandardMaterial3D.new()
var kind=""
var rot=0
var spot=Vector2.ZERO
var level=0.0
var reason=""
var affordable=true
var pulse=0.0
var aim_from_mouse=false
var fire_mesh:Mesh
var smoke_mesh:Mesh
var smoke_mat:StandardMaterial3D
var ring_mesh:Mesh
var burst_models={}
var motes=[]
var rings=[]
var world
var game

func setup(g,w):
	game=g
	world=w
	for k in KINDS:
		var m=Ink.new()
		if k=="skiff": preload("res://yole.gd").draw(m)
		elif k=="floor" or k in FITTINGS: preload("res://joinery.gd").draw(m,k)
		else: Art.build(m,k)
		models[k]=m.mesh(w.mat)
	for entry in [[good,Color(.48,1.,.76,.67)],[bad,Color(1.,.35,.23,.62)]]:
		var material=entry[0]
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		material.albedo_color=entry[1]
	ghost=MeshInstance3D.new()
	ghost.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ghost.visible=false
	add_child(ghost)
	var fm=Ink.new()
	for i in 5:
		var a=TAU*i/5
		var p=Vector3(cos(a)*.25,.19,sin(a)*.25)
		fm.rod(p,p+Vector3(.09,.71+.18*cos(i*2),-.08),.25,.009,Color("#f69949"),5)
	fm.rod(Vector3(0,.15,0),Vector3(.03,1.22,0),.26,.012,Color("#ffe79a"),6)
	var flame_mat=Ink.palette()
	flame_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	fire_mesh=fm.mesh(flame_mat)
	var sm=Ink.new()
	sm.blob(Vector3.ZERO,Vector3.ONE,Color.WHITE,2,6)
	smoke_mat=StandardMaterial3D.new()
	smoke_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.albedo_color=Color(.72,.73,.67,.21)
	smoke_mesh=sm.mesh(smoke_mat)
	var ring=Ink.new()
	for i in 40:
		var a=TAU*i/40
		var b=TAU*(i+1)/40
		var va=Vector3(cos(a),0,sin(a))
		var vb=Vector3(cos(b),0,sin(b))
		ring.quad(va*.975,vb*.975,vb,va,Color.WHITE,Vector3.UP)
	ring_mesh=ring.mesh()
	for k in ["wood","stone","food","gold","water"]:
		var m=Ink.new()
		m.blob(Vector3.ZERO,Vector3(.11,.085,.10),{"wood":Art.LWOOD,"stone":Art.STONE,"food":Color("#d78970"),"gold":Art.GOLD,"water":Color("#c6ded0")}[k],.6,5)
		burst_models[k]=m.mesh(w.mat)

func clear_world():
	var places=[]
	for it in items: places.append(it.at)
	for it in items: it.node.queue_free()
	items.clear()
	for p in places: world.cover_terrain(p,items,game.age)
	for mot in motes: mot.node.queue_free()
	for r in rings: r.node.queue_free()
	motes.clear()
	rings.clear()
	cancel()

func begin(k:String):
	if not k in KINDS: return
	kind=k
	rot=0
	aim_from_mouse=false
	ghost.mesh=models[k]
	ghost.visible=true
	update_preview()

func cancel():
	kind=""
	if ghost: ghost.visible=false

func rotate_piece():
	rot=(rot+1)%4
	update_preview()

func deck_height(p:Vector2)->float:
	var h=world.ground(p)
	if world.on_pier(p): h=maxf(h,2.63)
	for it in items:
		if it.kind in ["bridge","floor"] and abs(it.at.x-p.x)<=CELL*.51 and abs(it.at.y-p.y)<=CELL*.51:
			h=max(h,it.y+.056)
	return h

func has_fire(p:Vector2,r:float)->bool:
	for it in items:
		if it.kind=="fire" and p.distance_squared_to(it.at)<r*r: return true
	return false

func mouse_target()->Vector2:
	var mouse=game.get_viewport().get_mouse_position()
	var origin=game.camera.project_ray_origin(mouse)
	var dir=game.camera.project_ray_normal(mouse)
	var last=origin
	for i in range(1,92):
		var v=origin+dir*i*.85
		var p=Vector2(v.x,v.z)
		var h=max(world.ground(p),game.water)
		if v.y<=h:
			var f=clampf((last.y-h)/max(.01,last.y-v.y),0,1)
			var hit=last.lerp(v,f)
			return Vector2(hit.x,hit.z)
		last=v
	return Vector2(999,999)

func update_preview():
	if kind=="": return
	var yaw=game.actor.facing
	var front=Vector2(-sin(yaw),-cos(yaw))
	var p=game.xy+front*4.0
	if aim_from_mouse:
		var target=mouse_target()
		if target.distance_to(game.xy)<9.1: p=target
		else: aim_from_mouse=false
	if kind in ["bridge","floor"]: p=p.snapped(Vector2.ONE*CELL)
	else: p=p.snapped(Vector2.ONE*.25)
	spot=p
	var h=world.ground(p)
	level=maxf(h+(.23 if kind=="floor" else .06),DECK) if kind in ["bridge","floor"] else h+.035
	if kind=="skiff": level=maxf(game.water+.18,h+.32)
	reason=""
	if game.xy.distance_to(p)>9.2: reason="Rapproche-toi de cet emplacement."
	elif world.on_pier(p): reason="Le ponton de la pêcherie occupe déjà la place."
	elif kind=="trap" and (h>1.92 or h< -2.8): reason="Le casier se pose sur l’estran, près de l’eau."
	elif kind=="skiff" and h>game.water+.33: reason="La yole doit être mise à l’eau."
	elif kind in ["fire","shelter"] and h<2.25: reason="La pleine mer recouvrirait le camp. Monte plus haut."
	elif kind=="bridge" and h< -7.0: reason="Le fond est trop profond pour les pilotis."
	elif kind=="floor" and h< -4.7: reason="Les pieux du plancher n’atteignent pas le fond."
	elif world.blocked(p,.64 if kind!="shelter" else 1.35): reason="Le terrain est occupé."
	elif kind=="shelter" and game.xy.distance_to(p)<1.6: reason="Recule pour tendre la toile."
	if kind in FITTINGS:
		var support={}
		var distance=3.55
		for it in items:
			var d=p.distance_to(it.at)
			if it.kind=="floor" and d<distance:
				support=it;distance=d
		if support.is_empty(): reason="Vise d’abord un plancher sur pilotis."
		else:
			p=support.at
			level=support.y+.036
			if kind!="roof": p+=Vector2(-sin(rot*PI*.5),-cos(rot*PI*.5))*CELL*.5
			spot=p
			reason="" if p.distance_to(game.xy)<9.2 else "Rapproche-toi de ce plancher."
			for it in items:
				if (kind=="roof" and it.kind=="roof" or kind!="roof" and it.kind in ["wall","door"]) and it.at.distance_to(p)<.28:
					reason="Cette partie du plancher est déjà équipée."
			if kind in ["wall","door"] and wall_at(p,rot,kind,game.xy): reason="Écarte-toi de l’emplacement du mur."
	elif reason=="":
		for it in items:
			var gap=2.05 if "shelter" in [kind,it.kind] else 1.4
			if p.distance_to(it.at)<gap:
				reason="Une construction occupe déjà cet emplacement."
				break
	if kind=="floor" and reason=="":
		for it in items:
			if it.kind=="floor" and absf(it.at.distance_to(p)-CELL)<.18 and it.y>h-.045 and absf(it.y-level)<1.6:
				level=it.y;break
	if reason=="":
		for q in world.spots:
			if p.distance_to(q)<1.9: reason="Laisse l’accès à la caisse de sauvetage."
	if reason=="" and kind in ["fire","shelter"]:
		var variation=0.
		for off in [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]:
			variation=max(variation,abs(world.ground(p+off*(1.65 if kind=="shelter" else .7))-h))
		if variation>(.90 if kind=="shelter" else .55): reason="Cherche un sol plus plat."
	affordable=game.bag.wood>=COST[kind][0] and game.bag.stone>=COST[kind][1]
	if reason=="" and not affordable: reason="Il manque des matériaux."
	ghost.material_override=good if reason=="" else bad
	ghost.position=Vector3(p.x,level+.05,p.y)
	ghost.rotation.y=rot*PI*.5

func wall_at(anchor:Vector2,quarter:int,k:String,p:Vector2)->bool:
	var local=(p-anchor).rotated(quarter*PI*.5)
	for rect in building_bounds(k):
		if rect.has_point(local): return true
	return false

func building_bounds(k:String)->Array[Rect2]:
	match k:
		"wall": return [Rect2(-2.02,-.34,4.04,.68)]
		"door": return [Rect2(-2.02,-.34,1.53,.68),Rect2(.49,-.34,1.53,.68)]
		"shelter": return [Rect2(-1.91,-1.9,.96,3.8),Rect2(.95,-1.9,.96,3.8)]
	return []

func crosses_bounds(start:Vector2,finish:Vector2,rect:Rect2)->bool:
	# Old saves may start inside a wall. Allow the player to leave it.
	if rect.has_point(start): return false
	var motion=finish-start
	var enter:=0.0
	var leave:=1.0
	for axis in 2:
		if absf(motion[axis])<.000001:
			if start[axis]<rect.position[axis] or start[axis]>rect.end[axis]: return false
			continue
		var first:float=(rect.position[axis]-start[axis])/motion[axis]
		var last:float=(rect.end[axis]-start[axis])/motion[axis]
		enter=maxf(enter,minf(first,last))
		leave=minf(leave,maxf(first,last))
		if enter>leave: return false
	return true

func building_blocks_move(from:Vector2,to:Vector2,feet:float)->bool:
	for it in items:
		if it.kind not in ["wall","door","shelter"]: continue
		if feet+.9<it.y or feet>it.y+2.65: continue
		var angle:float=it.rot*PI*.5
		var start:Vector2=(from-it.at).rotated(angle)
		var finish:Vector2=(to-it.at).rotated(angle)
		for rect in building_bounds(it.kind):
			if crosses_bounds(start,finish,rect): return true
	return false

func nearby()->Array:
	var list=[]
	for i in items.size():
		if items[i].at.distance_to(game.xy)<5.25: list.append(i)
	list.sort_custom(func(a,b):return items[a].at.distance_squared_to(game.xy)<items[b].at.distance_squared_to(game.xy))
	return list

func dismantle(i:int):
	if i<0 or i>=items.size(): return
	var it=items[i]
	if it.at.distance_to(game.xy)>5.25 or not game.sailing.is_empty(): return
	if it.kind=="floor":
		for other in items:
			if other.kind in FITTINGS and other.at.distance_to(it.at)<CELL*.53:
				game.state="play"
				game.notify("Retire d’abord le toit et les panneaux qui s’appuient sur ce plancher.",4)
				return
	game.bag.wood+=COST[it.kind][0];game.bag.stone+=COST[it.kind][1]
	if it.kind in ["shelter","roof"] and game.home.distance_to(it.at)<3.: game.home=game.world.SPAWN
	it.node.queue_free();items.remove_at(i)
	world.cover_terrain(it.at,items,game.age)
	game.audio.effect("chantier",-5,.82);game.state="play"
	game.notify(NAMES[it.kind]+" démonté • matériaux récupérés.")
	game.find_nearest();game.save_run()

func commit()->bool:
	update_preview()
	if kind=="": return false
	if reason!="":
		game.notify(reason)
		return false
	var k=kind
	game.bag.wood-=COST[k][0]
	game.bag.stone-=COST[k][1]
	spawn(k,spot,level,rot)
	game.total_built+=1
	game.audio.effect("chantier",-2)
	spray(Vector3(spot.x,level+.4,spot.y),"wood",10)
	if k=="fire" and not game.has_ember:
		game.has_ember=true
		game.notify("Braise conservée • la lampe du phare pourra être amorcée.",4)
	else: game.notify(NAMES[k]+" en place.")
	if k!="bridge" or game.bag.wood<COST[k][0]: cancel()
	game.save_run()
	return true

func spawn(k:String,p:Vector2,y:float,quarter:int,charge:float=0):
	if not k in KINDS: return
	var root=Node3D.new()
	var model=MeshInstance3D.new()
	model.mesh=models[k]
	root.add_child(model)
	root.position=Vector3(p.x,y,p.y)
	root.rotation.y=quarter*PI*.5
	add_child(root)
	var it={"kind":k,"at":p,"y":y,"rot":quarter,"heading":quarter*PI*.5,"node":root,"charge":charge,"flame":null,"smoke":[]}
	if k=="fire":
		var flame=MeshInstance3D.new()
		flame.mesh=fire_mesh
		root.add_child(flame)
		it.flame=flame
		var warm=OmniLight3D.new()
		warm.light_color=Color("#ffb95c")
		warm.omni_range=7.3
		warm.light_energy=1.22
		warm.position.y=.95
		root.add_child(warm)
		for j in 4:
			var smoke=MeshInstance3D.new()
			smoke.mesh=smoke_mesh
			smoke.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(smoke)
			it.smoke.append(smoke)
	items.append(it)
	if k in ["fire","floor","shelter","bridge","trap"]: world.cover_terrain(p,items,game.age)

func tick(dt:float,t:float):
	if kind!="": update_preview()
	for it in items:
		if it.kind=="fire":
			it.flame.scale=Vector3(1.+.05*sin(t*7),.96+.16*sin(t*8)+.09*sin(t*13),1.)
			it.flame.rotation.y=t*1.4
			for j in 4:
				var k=fposmod(t*.25+j*.25,1)
				it.smoke[j].position=Vector3(k*k*1.43,.85+k*3.15,k*.35+.12*sin(k*7))
				it.smoke[j].scale=Vector3.ONE*(.10+.40*sin(PI*k))
		elif it.kind=="trap" and game.water>it.y-.22:
			it.charge=min(1.,it.charge+dt/28.)
		elif it.kind=="skiff":
			var wet=clampf(game.water-world.ground(it.at)+.32,0.,1.)
			it.y=maxf(game.water+.15+sin(t*1.8+it.at.x*.08)*.072*wet,world.ground(it.at)+.32)
			it.node.position=Vector3(it.at.x,it.y,it.at.y)
			it.node.rotation=Vector3(sin(t*1.14)*.028*wet,it.heading,sin(t*1.6)*.042*wet)
	for i in range(motes.size()-1,-1,-1):
		var v=motes[i]
		v.life-=dt
		if v.life<=0: v.node.queue_free(); motes.remove_at(i); continue
		v.vel.y-=dt*6.8
		v.node.position+=v.vel*dt
		v.node.rotate_z(dt*3)
		v.node.scale=Vector3.ONE*min(1.,v.life*3.7)
	for i in range(rings.size()-1,-1,-1):
		var r=rings[i]
		r.t+=dt
		if r.t>r.d: r.node.queue_free(); rings.remove_at(i); continue
		var f=r.t/r.d
		r.node.scale=Vector3.ONE*lerpf(.32,r.radius,1.-pow(1.-f,2))
		r.mat.albedo_color=Color(.98,.87,.53,(1-f)*.84)

func spray(p:Vector3,k:String,count:int):
	for j in count:
		var n=MeshInstance3D.new()
		n.mesh=burst_models[k]
		n.position=p
		add_child(n)
		motes.append({"node":n,"vel":Vector3(randf_range(-2.2,2.2),randf_range(1.4,3.4),randf_range(-2.2,2.2)),"life":randf_range(.4,.76)})

func ripple(p:Vector3,r:float,d:float=.78):
	var m=StandardMaterial3D.new()
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	m.albedo_color=Color(.99,.91,.64,.75)
	var n=MeshInstance3D.new()
	n.mesh=ring_mesh
	n.material_override=m
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.position=p+Vector3.UP*.17
	add_child(n)
	rings.append({"node":n,"t":0.,"d":d,"radius":r,"mat":m})
