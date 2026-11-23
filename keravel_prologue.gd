extends RefCounted

const Land=preload("res://keravel_map.gd")
enum { REGISTER, BOARD, BELL, PRAIRIE, GATHER, FIRE, JOURNAL, COMPLETE }
const NEEDS={"wood":5,"food":3,"stone":2}
const SPEAKERS={"narrateur":"Journal de relève","releve":"La relève","ewen":"Ewen Kerdreux",
	"soizic":"Soizic Penhoat","erwan":"Erwan Le Bris","goulven":"Goulven Mével",
	"maelle":"Maëlle Quéré","tangi":"Tangi Le Roux","azenor":"Sœur Azenor"}

var game
var step=REGISTER
var gathered={}
var warm_seconds=0.0
var title=""
var lines=[]
var line_index=0
var crossing_time=0.0

func reset():
	step=REGISTER
	gathered={}
	warm_seconds=0.
	lines=[]
	line_index=0
	crossing_time=0.

func pack()->Dictionary:
	return {"step":step,"gathered":gathered,"warm_seconds":warm_seconds}

func restore(saved:Dictionary):
	reset()
	step=clampi(int(saved.get("step",BOARD if game.campaign_phase==0 else COMPLETE)),REGISTER,COMPLETE)
	gathered=saved.get("gathered",{})
	warm_seconds=clampf(float(saved.get("warm_seconds",0.)),0.,45.)

func destination()->String:
	match step:
		REGISTER: return "tv-place-cloche"
		BOARD: return "tv-port"
		BELL: return "ponton-arrivee"
		PRAIRIE,GATHER,FIRE: return "prairie-phare"
		JOURNAL: return "phare-keravel"
	return ""

func objective()->String:
	match step:
		REGISTER: return "Présente-toi au registre de la place de la Cloche."
		BOARD: return "Passe la porte du port et rejoins le bateau de la relève."
		BELL: return "Sur le ponton, écoute la cloche qui vient du phare."
		PRAIRIE: return "Remonte le sentier jusqu’à la prairie du phare."
		GATHER: return "Bois %d/5  ·  Baies %d/3  ·  Silex %d/2"%[
			mini(int(gathered.get("wood",0)),5),mini(int(gathered.get("food",0)),3),mini(int(gathered.get("stone",0)),2)]
		FIRE:
			if not game.has_ember: return "Construis un feu [B], puis prends sa chaleur [E]."
			if game.night<.28: return "Attends le crépuscule près du feu."
			return "Reste au chaud près du feu · %d/45 s"%floori(warm_seconds)
		JOURNAL: return "Monte jusqu’au phare et lis le journal d’Erwan."
	return ""

func action()->Dictionary:
	var id=destination()
	if id=="" or step in [PRAIRIE,GATHER,FIRE]: return {}
	var at:Vector2=Land.RELAY_OFFICE if step==REGISTER else game.world.campaign.points[id]
	var radius=5.2 if step==JOURNAL else 3.2
	if game.xy.distance_to(at)>radius: return {}
	var label={
		REGISTER:"Recevoir l’ordre de relève",BOARD:"Embarquer sur le bateau de la relève",
		BELL:"Écouter la cloche",JOURNAL:"Lire le journal d’Erwan",
	}
	return {"kind":"campaign","id":id,"at":at,"label":label[step]}

func accept(id:String):
	if id!=destination(): return
	match step:
		REGISTER:
			step=BOARD
			speak("Prologue · L’ordre de relève",[
				{"speaker":"soizic","text":"Te voilà enfin. Le Service des feux t’attendait à Trois-Vannes. Signe le registre, puis descends au port par la porte de mer."},
				{"speaker":"ewen","text":"Votre premier quart commence à Keravel. Le phare n’a pas éclairé la mer depuis trois ans. Gardez la flamme."},
				{"speaker":"releve","text":"Je rejoins le ponton. Au prochain signal, le phare répondra."},
			])
		BOARD:
			step=BELL
			crossing_time=0.
			game.campaign_phase=1
			game.age=maxf(game.age,132.)
			game.campaign_landing("ponton-arrivee")
			game.actor.visible=false
			game.boat.visible=true
			game.state="arrival_film"
			game.audio.effect("corne",-9)
		BELL:
			step=PRAIRIE
			game.audio.effect("cloche",-4)
			speak_part(0,0)
		JOURNAL:
			step=COMPLETE
			speak_part(1,1)

func added(kind:String,quantity:int):
	if step!=GATHER: return
	gathered[kind]=int(gathered.get(kind,0))+quantity
	for item in NEEDS:
		if int(gathered.get(item,0))<NEEDS[item]: return
	step=FIRE
	speak_part(0,2)

func tick(dt:float):
	if step==PRAIRIE and game.xy.distance_to(game.world.campaign.points["prairie-phare"])<9.:
		step=GATHER
		speak_part(0,1)
	elif step==FIRE and game.has_ember and game.night>=.28 and game.camp.has_fire(game.xy,5.7):
		warm_seconds=minf(45.,warm_seconds+dt)
		if warm_seconds>=45.:
			step=JOURNAL
			game.notify("Premier quart tenu. Monte au phare lire le journal d’Erwan.",6.)
			game.save_run()

func speak_part(chapter:int,part:int):
	var content:Dictionary=game.world.campaign.story_part(chapter,part)
	speak(content.title,content.dialogue)

func speak(heading:String,dialogue:Array):
	title=heading
	lines=dialogue
	line_index=0
	game.open_panel("story_dialogue")
	game.save_run()

func current_line()->Dictionary:
	if lines.is_empty(): return {}
	return lines[line_index]

func advance_line():
	if line_index+1<lines.size():
		line_index+=1
		return
	lines=[]
	game.close_panel()

func tick_crossing(dt:float):
	crossing_time+=dt
	var t=clampf(crossing_time/7.4,0,1)
	var ease=smoothstep(0.,1.,t)
	var landing=game.world.pos(Land.ARRIVAL)
	var coast=game.world.light_base
	var ferry=landing+Vector3(3.8,0,lerpf(22.,-4.3,ease))
	game.boat.position=Vector3(ferry.x,game.water+.36+sin(t*24.)*.12,ferry.z)
	game.boat.rotation.y=0.
	game.camera.position=landing+Vector3(lerpf(21.,10.4,ease),lerpf(9.,15.,ease),lerpf(31.,9.5,ease))
	game.camera.look_at((landing+Vector3.UP*1.2).lerp(coast+Vector3.UP*6.5,ease),Vector3.UP)
	if crossing_time>=7.4: finish_crossing()

func finish_crossing():
	game.boat.visible=false
	game.actor.visible=true
	game.state="play"
	game.reset_camera()
	game.notify("Ponton de l’Arrivée • Écoute la cloche.",5.)
