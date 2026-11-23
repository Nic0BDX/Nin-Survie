extends SceneTree

const Map=preload("res://keravel_map.gd")
const Cartography=preload("res://keravel_cartography.gd")
const Opening=preload("res://keravel_prologue.gd")
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

func use_destination(game,id:String,offset=Vector2.ZERO):
	game.xy=game.world.campaign.points[id]+offset
	game.gather_cd=0
	game.interact()

func finish_dialogue(game):
	while game.state=="story_dialogue": game.command("story_next")

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
	var bridge:Vector2=world.points["ea-pont-de-corde"]
	check(game.camp.deck_height(bridge)>world.water_at(bridge,0.),"Pont au-dessus de la Stêr-Glas")
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
	print("KERAVEL_WORLD_\u0045ND ",failures.size()," failure(s)")
	quit(0 if failures.is_empty() else 1)
