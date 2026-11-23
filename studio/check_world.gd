extends SceneTree

const Map=preload("res://keravel_map.gd")
const Cartography=preload("res://keravel_cartography.gd")
const Opening=preload("res://keravel_prologue.gd")
const HIGH_WATER=2.12
const DEEP_WATER=.99
const INTERACTION_RANGE=4.4
const OUTER_OBJECTIVES=[
	"ea-sentier-embruns","ea-camp-base","ea-embouchure","ea-gue-lavandieres",
	"ea-pont-de-corde","ea-grotte-voile","ea-foret-coat-du","ea-coeur-foret",
	"ea-marais-stank","ea-ker-goz","ea-antre-serpent","ea-landes-brug",
	"ea-gorges-rochgwenn","ea-ruines-veilleurs","ea-camp-garde","ea-mines-vertes",
	"ea-citadelle-cryptes","ea-citadelle-remparts","ea-citadelle-cour",
	"ea-citadelle-donjon","ea-salle-verte","ea-crete-vents",
]
var failures:Array[String]=[]

func _initialize():
	call_deferred("run")

func check(condition:bool,label:String):
	print(("PASS " if condition else "FAIL ")+label)
	if not condition: failures.append(label)

func connected(game,start:Vector2,finish:Vector2,bounds:Rect2)->bool:
	var queue:Array[Vector2]=[start]
	var visited={Vector2i(start/2.):true}
	var i=0
	while i<queue.size():
		var point=queue[i]
		i+=1
		if point.distance_to(finish)<3.2: return true
		for step in [Vector2(2,0),Vector2(-2,0),Vector2(0,2),Vector2(0,-2)]:
			var next=point+step
			var key=Vector2i(next/2.)
			if not bounds.has_point(next) or visited.has(key): continue
			visited[key]=true
			if game.camp.deck_height(next)>2.12 and not game.world.blocked(next,.19): queue.append(next)
	return false

func outdoor_depth(game,source:Vector2)->float:
	var world_point=Map.outer_to_world(source)
	var surface:float=game.world.campaign.water_at(world_point,HIGH_WATER)
	var deck:float=game.camp.deck_height(world_point)
	return maxf(0.,surface-deck)

func outdoor_step(game,source:Vector2)->bool:
	var world_point=Map.outer_to_world(source)
	return game.reachable_world(world_point) and not game.world.blocked(world_point,.19) and outdoor_depth(game,source)<=DEEP_WATER

func missing_outer_routes(game,beach:Vector2)->Array:
	# One bounded search for all land destinations. Coordinates follow the native bridge/ford axes.
	var area=Rect2(-483,-85,312,170)
	var source=Map.world_to_outer(beach)
	var start=Vector2i(roundi(source.x/2.)*2,roundi(source.y/2.)*2)
	var queue:Array[Vector2i]=[]
	if outdoor_step(game,Vector2(start)): queue.append(start)
	var visited={start:true}
	var pending={}
	for id in OUTER_OBJECTIVES:
		pending[id]=game.world.campaign.points[id]
	var index=0
	while index<queue.size() and not pending.is_empty():
		var current=queue[index]
		index+=1
		var world_point=Map.outer_to_world(Vector2(current))
		for id in pending.keys():
			if world_point.distance_squared_to(pending[id])<=INTERACTION_RANGE*INTERACTION_RANGE:
				pending.erase(id)
		for offset in [Vector2i(2,0),Vector2i(-2,0),Vector2i(0,2),Vector2i(0,-2)]:
			var next=current+offset
			if visited.has(next) or not area.has_point(Vector2(next)): continue
			if not outdoor_step(game,Vector2(next)):
				visited[next]=true
				continue
			var clear=true
			# Midpoints catch narrow collision walls between otherwise valid grid cells.
			for fraction in [.25,.5,.75]:
				if not outdoor_step(game,Vector2(current)+Vector2(offset)*fraction):
					clear=false
					break
			if clear:
				visited[next]=true
				queue.append(next)
	return pending.keys()

func crossing_depth(game,id:String,half_length:float)->float:
	var center=Map.world_to_outer(game.world.campaign.points[id])
	var depth=0.
	var count=ceili(half_length*4.)
	for i in range(-count,count+1):
		var point=center+Vector2(0,i*.25)
		var world_point=Map.outer_to_world(point)
		if not game.reachable_world(world_point) or game.world.blocked(world_point,.19): return INF
		depth=maxf(depth,outdoor_depth(game,point))
	return depth

func check_outer_world(game,beach:Vector2):
	var old_phase:int=game.campaign_phase
	game.campaign_phase=4
	check(outdoor_step(game,Map.world_to_outer(beach)),"Débarquement praticable sur la plage des Naufragés à marée haute")
	var missing=missing_outer_routes(game,beach)
	check(missing.is_empty(),"Réseau terrestre de l’île à marée haute (22 repères, sans nage profonde)"+
		(" · isolés : "+", ".join(PackedStringArray(missing)) if not missing.is_empty() else ""))
	var bridge_depth=crossing_depth(game,"ea-pont-de-corde",10.)
	var ford_depth=crossing_depth(game,"ea-gue-lavandieres",8.)
	check(bridge_depth<=.12,"Pont de corde praticable à sec sur son axe, de rive à rive")
	check(ford_depth<=DEEP_WATER,"Gué des Lavandières praticable sur son axe sans nage profonde")
	var world=game.world.campaign
	var upstream:float=world.water_at(Map.outer_to_world(Map.RIVER[0]),HIGH_WATER)
	var above_falls:float=world.water_at(Map.outer_to_world(Map.RIVER[1]),HIGH_WATER)
	var below_falls:float=world.water_at(Map.outer_to_world(Map.RIVER[2]),HIGH_WATER)
	var mouth:float=world.water_at(Map.outer_to_world(Map.RIVER.back()),HIGH_WATER)
	check(upstream>above_falls and above_falls>below_falls and below_falls>mouth
		and is_equal_approx(mouth,HIGH_WATER),"Stêr-Glas : chute de niveau à la cascade et débouché au niveau de la mer")
	var channel=Map.outer_to_world(Map.RIVER[5])
	check(world.water_at(channel,HIGH_WATER)>game.camp.deck_height(channel),"Chenal immergé hors des aménagements du pont et du gué")
	game.campaign_phase=old_phase

func use_destination(game,id:String,offset=Vector2.ZERO):
	game.xy=game.world.campaign.points[id]+offset
	game.gather_cd=0
	game.interact()

func finish_dialogue(game):
	while game.state=="story_dialogue": game.command("story_next")

func check_chapel(game):
	var chapel=game.chapel
	game.campaign_phase=3
	check(game.campaign_destination()=="tv-chapelle","L’acte II conduit à la chapelle")
	use_destination(game,"tv-chapelle")
	check(chapel.room=="chapel" and chapel.model!=null and not game.world.visible,"Entrée dans la chapelle")
	if chapel.room!="chapel": return
	chapel.local=chapel.Nave.HATCH
	game.gather_cd=0.
	game.interact()
	check(chapel.room=="chapel" and chapel.progress==0,"Trappe verrouillée avant la rencontre")
	chapel.local=chapel.AZENOR
	game.gather_cd=0.
	game.interact()
	check(chapel.progress==1 and game.state=="story_dialogue","Dialogue de Sœur Azenor")
	finish_dialogue(game)
	game.bag.wood=2
	game.gather_cd=0.
	game.interact()
	check(chapel.progress==2 and game.bag.wood==0,"Don du bois et ouverture de la trappe")
	chapel.local=chapel.Nave.HATCH
	game.gather_cd=0.
	game.interact()
	check(chapel.room=="crypt","Descente aux Caves aux Fresques")
	if chapel.room!="crypt": return
	game.save_run()
	game.resume_run()
	check(chapel.room=="crypt" and chapel.progress==2,"Reprise de partie dans la crypte")
	chapel.local=chapel.Crypt.FRESCO
	game.gather_cd=0.
	game.interact()
	check(chapel.progress==3 and game.state=="story_dialogue","Lecture des fresques")
	finish_dialogue(game)
	chapel.local=chapel.Crypt.EXIT
	game.gather_cd=0.
	game.interact()
	chapel.local=chapel.Nave.EXIT
	game.gather_cd=0.
	game.interact()
	check(chapel.room=="" and game.world.visible and game.campaign_destination()=="tv-port","Retour au parvis et suite du r?cit au port")

func run():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.new_run()
	var world=game.world.campaign
	var atlas=load("res://keravel_atlas.jpg")
	check(world.points.size()==53 and world.chapters.size()==30 and atlas.get_size()==Cartography.SIZE,"Récit, 53 lieux et image d’atlas native")
	for id in world.points: check(Cartography.PINS.has(id),"Repère "+id)
	var wreck:Vector2=world.points["ea-plage-naufrages"]
	var peak:Vector2=world.points["ea-pic-braise"]
	check(wreck.x>Map.START.x and peak.y<wreck.y,"Enez-Aerouant à l’est, volcan au nord de la plage")
	check_outer_world(game,wreck)
	check(world.footprints.size()>=45 and connected(game,Map.START,world.points["tv-port"],Rect2(2,132,110,102)),"Ville bâtie, porte de mer et port accessibles à marée haute")
	check(connected(game,Map.START,Vector2(-7,19),Rect2(-20,14,85,143)),"Route du phare continue")
	check(game.opening.step==Opening.REGISTER and not game.reachable_world(wreck),"Départ à Trois-Vannes et verrou de l’île extérieure")
	use_destination(game,"tv-place-cloche",Map.RELAY_OFFICE-Map.START)
	check(game.state=="story_dialogue" and game.opening.step==Opening.BOARD,"Registre et ordre de relève")
	finish_dialogue(game)
	use_destination(game,"tv-port")
	check(game.state=="arrival_film" and game.xy==Map.ARRIVAL,"Embarquement et arrivée")
	game.command("arrival_skip")
	use_destination(game,"ponton-arrivee")
	check(game.state=="story_dialogue" and game.opening.step==Opening.PRAIRIE,"Cloche et dialogue original")
	finish_dialogue(game)
	game.xy=world.points["prairie-phare"]
	game.opening.tick(.02)
	finish_dialogue(game)
	game.opening.added("wood",6)
	game.opening.added("food",4)
	game.opening.added("stone",2)
	check(game.opening.step==Opening.FIRE,"Objectifs des premiers gestes")
	finish_dialogue(game)
	game.camp.spawn("fire",game.xy+Vector2(1,0),game.world.ground(game.xy),0)
	game.gather_cd=0
	game.interact()
	game.night=.7
	game.opening.tick(44.)
	check(game.opening.step==Opening.FIRE and game.opening.warm_seconds>=44.,"Premier quart attend les 45 secondes")
	game.opening.tick(1.1)
	use_destination(game,"phare-keravel",Vector2(0,3))
	check(game.state=="story_dialogue" and game.opening.step==Opening.COMPLETE,"Journal d’Erwan et départ de la quête")
	finish_dialogue(game)
	game.save_run()
	game.resume_run()
	check(game.opening.step==Opening.COMPLETE and game.campaign_destination()=="le-courlis","Sauvegarde et suite de l’acte I")
	check_chapel(game)
	print("KERAVEL_WORLD_\u0045ND ",failures.size()," failure(s)")
	quit(0 if failures.is_empty() else 1)
