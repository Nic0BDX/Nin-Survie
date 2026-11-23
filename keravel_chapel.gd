extends RefCounted

const Nave=preload("res://keravel_chapel_interior.gd")
const Crypt=preload("res://keravel_crypt.gd")
const Ink=preload("res://meshwork.gd")
const ORIGIN=Vector3(-220,64,34)
const AZENOR=Vector2(-2.9,-5.6)
const CHAPTER=8

var game
var room=""
var local=Vector2.ZERO
var progress=0
var model:Node3D

func title()->String:
	return "Les Caves aux Fresques" if room=="crypt" else "Chapelle Sainte-Azenor"

func objective()->String:
	if room=="crypt":
		return "Examine les fresques au fond des caves." if progress<3 else "Lis l’inscription, ou regagne la chapelle."
	if game.campaign_phase<2: return "La chapelle est ouverte. La sœur veille sur le sanctuaire."
	match progress:
		0: return "Parle à Sœur Azenor près de l’autel."
		1: return "Apporte deux bois d’épave à Sœur Azenor."
		2: return "Descends par la trappe à droite de l’autel."
	return "Tu connais la légende. La porte donne sur Trois-Vannes."

func pack()->Dictionary:
	return {"room":room,"local":[local.x,local.y],"progress":progress}

func reset():
	close_visual()
	progress=0

func restore(record:Dictionary):
	progress=clampi(int(record.get("progress",0)),0,4)
	var saved_room:String=record.get("room","")
	if saved_room not in ["chapel","crypt"] or (saved_room=="crypt" and progress<2): return
	var stored:Array=record.get("local",[])
	var entry:Vector2=Crypt.ENTRY if saved_room=="crypt" else Nave.ENTRY
	if stored.size()==2:
		var position=Vector2(float(stored[0]),float(stored[1]))
		if position.is_finite() and not blocked_in(saved_room,position): entry=position
	enter(saved_room,entry)

func blocked_in(id:String,at:Vector2)->bool:
	return Crypt.blocked(at,.22) if id=="crypt" else Nave.navigation_blocked(at,.22)

func close_visual():
	if is_instance_valid(model):
		model.hide()
		model.queue_free()
	model=null
	room=""
	if game.world: game.world.show()
	if game.camp: game.camp.show()

func enter(id:String,entry:Vector2):
	close_visual()
	room=id
	local=entry
	var builder=Crypt if id=="crypt" else Nave
	model=builder.create(ORIGIN,game.world.mat,true)
	game.add_child(model)
	if room=="chapel": add_azenor()
	game.world.hide()
	game.camp.hide()
	game.rain.hide()
	game.boat.hide()
	game.camp.cancel()
	game.reset_touch()
	game.depth=0.
	game.velocity=Vector2.ZERO
	game.speed=0.
	game.yaw=0.
	game.pitch=.25
	game.actor.facing=0.
	game.actor.visible=true
	place_actor()
	camera()
	game.last_region=title()
	game.region_t=2.9
	game.find_nearest()

func place_actor():
	game.actor.position=ORIGIN+Vector3(local.x,0,local.y)

func add_azenor():
	var m=Ink.new()
	var p=Vector3(AZENOR.x,0,AZENOR.y)
	m.column(p,.97,.30,.21,Color("#303b42"),8)
	m.column(p+Vector3.UP*.91,.58,.23,.21,Color("#323d44"),8)
	m.blob(p+Vector3(0,1.62,.023),Vector3(.203,.238,.178),Color("#c99b7b"),0.,8)
	m.blob(p+Vector3(0,1.67,-.055),Vector3(.236,.255,.17),Color("#ddd3bf"),1.,8)
	m.box(p+Vector3(0,1.30,.24),Vector3(.25,.31,.091),Color("#c7ad82"))
	m.box(p+Vector3(0,1.26,.295),Vector3(.17,.046,.015),Color("#d9c39c"))
	model.add_child(m.node(game.world.mat))

func camera():
	var aim=game.actor.position+Vector3.UP*1.03
	var limit=4.0 if room=="crypt" else 4.15
	var z_min=-6.45 if room=="crypt" else -8.0
	var z_max=7.72 if room=="crypt" else 8.12
	var pitch:float=clampf(game.pitch,.12,.52)
	var offset=Vector3(sin(game.yaw)*2.6,1.12+sin(pitch)*1.9,cos(game.yaw)*2.6)
	var want=aim+offset-ORIGIN
	want.x=clampf(want.x,-limit,limit)
	want.z=clampf(want.z,z_min,z_max)
	want.y=clampf(want.y,1.62,3.0 if room=="crypt" else 3.7)
	game.camera.position=ORIGIN+want
	var alignment=Vector2(want.x, want.z).distance_squared_to(Vector2(local.x, local.y))
	game.camera.look_at(aim,Vector3.UP if alignment>.0001 else Vector3.BACK)
	game.camera.fov=63.

func tick(dt:float):
	var dir:Vector2=game.input_move()
	var delta=dir*3.75*dt
	var horizontal=local+Vector2(delta.x,0)
	if not blocked_in(room,horizontal): local=horizontal
	var vertical=local+Vector2(0,delta.y)
	if not blocked_in(room,vertical): local=vertical
	game.speed=dir.length()*3.75
	if dir!=Vector2.ZERO: game.actor.facing=atan2(-dir.x,-dir.y)
	place_actor()
	game.actor.pose(dt,game.speed,0.,0.,0.,game.visual_time)
	game.gather_cd=maxf(0.,game.gather_cd-dt)
	game.find_nearest()
	camera()
	game.audio.mix(.12,0.,0.)
	game.autosave+=dt
	if game.autosave>=8.:
		game.autosave=0.
		game.save_run()

func action()->Dictionary:
	if room=="chapel":
		if local.distance_to(Nave.EXIT)<1.55: return {"kind":"interior","id":"leave","label":"Sortir sur le parvis"}
		if local.distance_to(Nave.HATCH)<1.65:
			return {"kind":"interior","id":"hatch","label":"Descendre dans les caves" if progress>=2 else "Examiner la trappe"}
		if local.distance_to(AZENOR)<2.0: return {"kind":"interior","id":"azenor","label":"Parler à Sœur Azenor"}
	else:
		if local.distance_to(Crypt.EXIT)<1.65: return {"kind":"interior","id":"leave","label":"Remonter à la chapelle"}
		if local.distance_to(Crypt.INSCRIPTION)<1.33 and progress>=3: return {"kind":"interior","id":"inscription","label":"Lire l’inscription des Veilleurs"}
		if local.distance_to(Crypt.FRESCO)<2.08: return {"kind":"interior","id":"frescos","label":"Examiner les trois fresques"}
	return {}

func part(index:int):
	game.opening.speak_part(CHAPTER,index)

func interact(id:String):
	match id:
		"leave":
			if room=="crypt": enter("chapel",Nave.HATCH+Vector2(-.75,1.0))
			else:
				close_visual()
				game.xy=game.world.campaign.points["tv-chapelle"]+Vector2(0,1.85)
				game.yaw=PI
				game.pitch=.27
				game.set_actor_height(true)
				game.reset_camera()
		"azenor":
			if game.campaign_phase<2:
				game.opening.speak("Sainte-Azenor",[{"speaker":"azenor","text":"Le phare dort encore. Quand sa lampe aura repris, viens me parler de la braise."}])
			elif progress==0:
				progress=1
				part(0)
			elif progress==1 and game.bag.wood>=2:
				game.bag.wood-=2
				progress=2
				game.notify("Sœur Azenor te confie la clé des caves.",4.)
			elif progress==1:
				game.notify("Il manque deux bois d’épave pour les cierges.",4.)
			else: game.notify("La trappe est à droite de l’autel.",4.)
		"hatch":
			if progress>=2: enter("crypt",Crypt.ENTRY)
			else: game.notify("La trappe est fermée. Sœur Azenor en garde la clé.",4.)
		"frescos":
			progress=maxi(3,progress)
			part(1)
		"inscription":
			progress=4
			part(2)
	game.save_run()
