extends Node3D
const World=preload("res://biome.gd")
const Actor=preload("res://actor.gd")
const Camp=preload("res://camp.gd")
const Sound=preload("res://audio.gd")
const Overlay=preload("res://hud.gd")
const Ink=preload("res://meshwork.gd")
const Art=preload("res://art.gd")
const KeravelMap=preload("res://keravel_map.gd")
const StoryOpening=preload("res://keravel_prologue.gd")
const EXPEDITION=[
	"ea-sentier-embruns","ea-camp-base","ea-embouchure","ea-gue-lavandieres",
	"ea-pont-de-corde","ea-cascade-voile","ea-grotte-voile","ea-lac-miroir",
	"ea-foret-coat-du","ea-coeur-foret","ea-marais-stank","ea-ker-goz",
	"ea-antre-serpent","ea-landes-brug","ea-gorges-rochgwenn","ea-ruines-veilleurs",
	"ea-camp-garde","ea-mines-vertes","ea-citadelle-cryptes","ea-citadelle-remparts",
	"ea-citadelle-cour","ea-citadelle-donjon","ea-salle-verte","ea-crete-vents","ea-plage-naufrages",
]
const DAY=282.0
const TIDE_CYCLE=135.0
const SAVE_PATH="user://quart_v1.json"
var world
var actor
var camp
var audio
var hud
var camera=Camera3D.new()
var state="menu"
var bag={"wood":0,"stone":0,"food":2}
var xy=World.SPAWN
var home=World.SPAWN
var safe=World.SPAWN
var age=0.0
var visual_time=0.0
var water=0.0
var night=0.0
var storm=0.0
var hp=100.0
var warmth=100.0
var hunger=90.0
var stamina=100.0
var pieces=[false,false,false]
var has_ember=false
var rescued=false
var total_built=0
var harvests=0
var survived=0
var run_name=0
var depth=0.0
var speed=0.0
var velocity=Vector2.ZERO
var yaw=.24
var pitch=.27
var zoom=12.4
var cam_target=Vector3.ZERO
var menu_t=0.
var mouselook=false
var cool=0.
var ring_anim=0.
var gather_cd=0.
var gather_clock=0.
var foot_clock=0.
var next_cry=13.0
var foe_clock=0.
var foes=[]
var last_hit=-10.
var autosave=0.
var save_status=true
var active_save=false
var nearest={}
var last_region=""
var region_t=0.
var toast=""
var toast_time=0.
var ui_hidden=false
var cinematic_t=0.
var boat:Node3D
var boat_start=Vector2(-51,-12)
var boat_end=Vector2(-35,2)
var build_tip=false
var selected_site=-1
var hit_flash=0.
var weather_note=""
var seen_weather=""
var fog_warnings={}
var rain:MultiMeshInstance3D
var drops=[]
var rain_phase=0.
var rng=RandomNumberGenerator.new()
var menu_return="play"
var previous_panel="play"
var sleep_t=0.
var dawn_fade=0.
var settings=ConfigFile.new()
var prompt_toggle=false
var qa=false
var touch_mode=false
var move_finger=-1
var look_finger=-1
var touch_move=Vector2.ZERO
var browser_qa
var campaign_phase=-1
var expedition_index=0
var campaign_track=""
var opening=StoryOpening.new()
var qa_save_path=""
var save_timer_msg=0.
var compass_targets=[]
var was_new=true
var told_bell=false
var sailing={}
var sail_speed=0.
var wake_clock=0.
var heading_free=0.
var salvage=preload("res://salvage.gd").new()
var signal_active=false
var signal_calls=0
var signal_start=0.
var next_signal=0.
var call_announced=false
const Shore=preload("res://shore.gd")
var stamps=[false,false,false]
var stamp_page=0
var exhausted=false
var closing=false
var marsh=preload("res://marais.gd").new()

func _ready():
	opening.game=self
	touch_mode=DisplayServer.is_touchscreen_available()
	if OS.has_feature("web"):
		touch_mode=touch_mode or bool(JavaScriptBridge.eval("matchMedia('(pointer: coarse)').matches || navigator.maxTouchPoints > 0"))
	qa=OS.get_cmdline_user_args().has("--qa")
	if qa: qa_save_path="user://essai_"+str(OS.get_process_id())+".json"
	if qa and OS.has_feature("web"): browser_qa=JavaScriptBridge.get_interface("ninTest")
	rng.randomize()
	world=World.new()
	world.mobile_detail=touch_mode
	add_child(world)
	camp=Camp.new()
	add_child(camp)
	camp.setup(self,world)
	add_child(marsh);marsh.setup(self)
	actor=Actor.new()
	add_child(actor)
	add_child(camera)
	camera.current=true
	camera.near=.15
	camera.far=630
	camera.fov=52
	if touch_mode:
		get_viewport().msaa_3d=Viewport.MSAA_2X
		world.sun.shadow_enabled=false
	audio=Sound.new()
	add_child(audio)
	settings.load("user://preferences.cfg")
	audio.enabled=settings.get_value("audio","active",true)
	audio.music_on=settings.get_value("audio","musique",true)
	make_rain()
	make_boat()
	var canvas=CanvasLayer.new()
	add_child(canvas)
	hud=Overlay.new()
	canvas.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.game=self
	hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	active_save=not read_saved().is_empty()
	update_sea()
	world.atmosphere(0,water,0,0,false)
	reset_camera()
	actor.visible=false
	menu_camera(0)
	get_tree().auto_accept_quit=false

func make_rain():
	var m=Ink.new()
	m.rod(Vector3.ZERO,Vector3(-.07,.52,0),.014,.008,Color("#a6c9cf"),3)
	var mm=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.mesh=m.mesh(world.mat)
	var count=72 if touch_mode else 155
	mm.instance_count=count
	rain=MultiMeshInstance3D.new()
	rain.multimesh=mm
	rain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rain)
	for i in count: drops.append(Vector3(rng.randf_range(-10,10),rng.randf_range(0,12),rng.randf_range(-9,9)))

func make_boat():
	var m=Ink.new()
	Art.vessel(m)
	boat=m.node(world.mat)
	boat.scale=Vector3.ONE*1.22
	boat.visible=false
	add_child(boat)

func toggle_fullscreen():
	var w=get_window()
	w.mode=Window.MODE_WINDOWED if w.mode in [Window.MODE_EXCLUSIVE_FULLSCREEN,Window.MODE_FULLSCREEN] else Window.MODE_FULLSCREEN

func pref():
	settings.set_value("audio","active",audio.enabled)
	settings.set_value("audio","musique",audio.music_on)
	if not qa: settings.save("user://preferences.cfg")

func notify(message:String,d:float=2.8):
	toast=message
	toast_time=d

func new_run():
	marsh.reset({})
	sailing={}
	sail_speed=0.
	camp.clear_world()
	clear_foes()
	for r in world.resources:
		r.ready=0.0
		r.node.visible=true
	age=0.
	bag={"wood":0,"stone":0,"food":2}
	hp=100.; warmth=100.; hunger=92.; stamina=100.
	pieces=[false,false,false]
	stamps=[false,false,false];exhausted=false
	has_ember=false
	rescued=false
	signal_active=false;signal_calls=0;signal_start=0.;next_signal=0.;call_announced=false
	total_built=0
	harvests=0
	survived=0
	campaign_phase=0
	opening.reset()
	expedition_index=0
	campaign_track=""
	safe=KeravelMap.START
	home=safe
	xy=safe
	actor.facing=.20
	actor.rotation.y=.20
	selected_site=-1
	told_bell=false
	run_name=int(Time.get_unix_time_from_system())
	fog_warnings.clear()
	was_new=true
	start_play()
	save_run()
	notify("Trois-Vannes • Le registre de relève t’attend à la place de la Cloche.",6)

func start_play():
	state="play"
	world.set_campaign_lamp(100 if campaign_phase>=6 else (35 if campaign_phase>=2 else 0))
	ui_hidden=false
	actor.visible=true
	boat.visible=rescued
	toast_time=0
	foe_clock=5
	cool=0; ring_anim=0; gather_cd=.22; gather_clock=0; autosave=0; hit_flash=0
	last_hit=age-4
	speed=0; velocity=Vector2.ZERO
	yaw=.24; pitch=.27; zoom=12.4
	next_cry=age+18
	seen_weather=""
	last_region=world.region(xy)
	region_t=4
	update_sea()
	set_actor_height(true)
	reset_camera()
	world.atmosphere(visual_time,water,night,storm,rescued or signal_active)
	find_nearest()

func begin_or_confirm():
	if active_save: state="confirm_new"
	else: new_run()

func go_menu():
	if state not in ["menu","confirm_new"]: save_run()
	state="menu"
	actor.visible=false
	camp.cancel()
	mouselook=false
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	menu_t=0
	boat.visible=false
	rain.visible=false
	hud.focus_index=0

func update_sea():
	var phase=fmod(age,DAY)/DAY
	# The first landing takes place two hours after sunrise, at low tide.
	var solar=cos(TAU*(phase-.17))
	night=smoothstep(-.10,.86,-solar)
	water=.64-1.48*cos(TAU*age/TIDE_CYCLE)
	var weather_phase=fposmod(age+7.,196.)/196.
	storm=smoothstep(.61,.74,weather_phase)*(1.-smoothstep(.86,.99,weather_phase))
	if age<62: storm=0.
	if signal_active:
		var bank=smoothstep(0.,9.,age-signal_start)
		storm=maxf(storm,.84*bank)
		night=maxf(night,.55*bank)
func tide_rising()->bool:
	return sin(TAU*age/TIDE_CYCLE)>=0.
func tide_label()->String:
	if water<-.54: return "BASSE MER"
	if water>1.87: return "PLEINE MER"
	return "FLOT MONTANT" if tide_rising() else "JUSANT"
func clock_readout()->String:
	var mins=int(fposmod(8.+age/DAY*24.,24.)*60)
	return "%02d h %02d"%[mins/60,mins%60]
func day_number()->int: return 1+floori(age/DAY)
func weather_label()->String:
	if storm>.50: return "GRAIN"
	if night>.56: return "NUIT"
	if night>.12: return "PÉNOMBRE"
	return "ÉCLAIRCIES"
func get_save_path()->String: return qa_save_path if qa else SAVE_PATH
func read_saved()->Dictionary:
	for suffix in ["",".bak"]:
		var path=get_save_path()+suffix
		if not FileAccess.file_exists(path): continue
		var f=FileAccess.open(path,FileAccess.READ)
		if not f: continue
		var data=JSON.parse_string(f.get_as_text())
		if typeof(data)==TYPE_DICTIONARY and data.get("version",0)==1 and data.has("xy") and data.has("bag"): return data
	return {}
func save_run():
	if state in ["menu","confirm_new"] or (state=="help" and menu_return=="menu"): return
	var built=[]
	for it in camp.items: built.append([it.kind,it.at.x,it.at.y,it.y,it.rot,it.charge,it.heading])
	var pickups={}
	for i in world.resources.size():
		var r=world.resources[i]
		if r.ready>age: pickups[str(i)]=r.ready
	var data={"version":1,"age":age,"xy":[xy.x,xy.y],"safe":[safe.x,safe.y],"home":[home.x,home.y],"bag":bag,"hp":hp,"warmth":warmth,"hunger":hunger,"stamina":stamina,"parts":pieces,"ember":has_ember,"won":rescued,"built":built,"pickup":pickups,"total":total_built,"harvests":harvests,"survived":survived,"run":run_name,"tracked":selected_site}
	data["aboard"]=camp.items.find(sailing) if not sailing.is_empty() else -1
	data["watch"]=[signal_active,signal_calls,signal_start,next_signal]
	data["stamps"]=stamps
	data["marais"]=marsh.pack()
	data["campaign"]=[campaign_phase,expedition_index,campaign_track]
	data["opening"]=opening.pack()
	data["map_revision"]=2
	var path=get_save_path()
	var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if f==null:
		save_status=false
		return
	f.store_string(JSON.stringify(data)); f.flush()
	var write_ok=f.get_error()==OK
	f.close()
	if not write_ok: save_status=false; return
	var raw=ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path+".bak"): DirAccess.remove_absolute(raw+".bak")
		if DirAccess.rename_absolute(raw,raw+".bak")!=OK: save_status=false; return
	if DirAccess.rename_absolute(raw+".tmp",raw)!=OK:
		save_status=false
		if FileAccess.file_exists(path+".bak"): DirAccess.rename_absolute(raw+".bak",raw)
		return
	save_status=true
	active_save=true
	save_timer_msg=1.6

func resume_run():
	var d=read_saved()
	if d.is_empty(): new_run(); return
	camp.clear_world(); clear_foes()
	age=float(d.age)
	var map_revision=int(d.get("map_revision",1))
	xy=restore_map_point(Vector2(d.xy[0],d.xy[1]),map_revision)
	safe=restore_map_point(Vector2(d.safe[0],d.safe[1]),map_revision)
	home=restore_map_point(Vector2(d.home[0],d.home[1]),map_revision)
	bag={"wood":int(d.bag.wood),"stone":int(d.bag.stone),"food":int(d.bag.food)}
	hp=float(d.hp); warmth=float(d.warmth); hunger=float(d.hunger); stamina=float(d.stamina)
	pieces=d.parts.duplicate(); has_ember=d.ember; rescued=d.won
	marsh.reset(d.get("marais",{}))
	stamps=d.get("stamps",[false,false,false]).duplicate()
	var watch=d.get("watch",[false,0,0,0])
	signal_active=watch[0];signal_calls=int(watch[1]);signal_start=float(watch[2]);next_signal=float(watch[3]);call_announced=false
	total_built=int(d.total); harvests=int(d.harvests); survived=int(d.survived); run_name=int(d.run)
	selected_site=int(d.get("tracked",-1))
	var journey=d.get("campaign",[-1,0,""])
	campaign_phase=int(journey[0])
	opening.restore(d.get("opening",{}))
	expedition_index=clampi(int(journey[1]),0,EXPEDITION.size())
	campaign_track=journey[2] if world.campaign.zones.has(journey[2]) else ""
	sailing={};sail_speed=0.
	for b in d.built:
		camp.spawn(b[0],restore_map_point(Vector2(b[1],b[2]),map_revision),b[3],int(b[4]),b[5])
		if b.size()>6: camp.items.back().heading=b[6]
	var seat=int(d.get("aboard",-1))
	if seat>=0 and seat<camp.items.size() and camp.items[seat].kind=="skiff": sailing=camp.items[seat]
	for i in world.resources.size():
		var r=world.resources[i]
		r.ready=float(d.pickup.get(str(i),0.))
		r.node.visible=r.ready<=age and not r.covered
	was_new=false
	start_play()
	if hp<=0: state="dead"
	else: notify("Journal ouvert • quart repris.")

func restore_map_point(p:Vector2,revision:int)->Vector2:
	return KeravelMap.outer_to_world(p) if revision<2 and KeravelMap.ISLAND_SOURCE.has_point(p) else p

func respawn():
	sailing={};sail_speed=0.
	xy=home
	if world.ground(xy)<2.25: xy=World.SPAWN
	safe=xy
	hp=85; warmth=85; hunger=67; stamina=100
	for k in ["wood","stone"]: bag[k]=floori(bag[k]*.66)
	bag.food=maxi(1,bag.food)
	age+=13; survived+=1
	clear_foes()
	start_play()
	save_run()
	notify("De retour au camp • une partie des matériaux a été perdue.",4)

func _notification(what):
	if what==NOTIFICATION_WM_CLOSE_REQUEST and is_inside_tree():
		exit_game()
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree() and state=="play":
		open_panel("pause")

func exit_game():
	if closing: return
	closing=true
	save_run()
	set_process(false);set_process_input(false)
	if audio:
		audio.music.stop();audio.sea.stop()
		for voice in audio.voices: voice.stop()
	await get_tree().create_timer(.18).timeout
	get_tree().quit()

func reset_camera():
	cam_target=Vector3(xy.x,max(camp.deck_height(xy),water-.46)+1.12,xy.y)
	follow_camera(1.,true)

func menu_camera(t:float):
	# Leave a quiet strip of sea and sky to the left of the lighthouse for the title.
	var a=.65+sin(t*.028)*.22
	var q=world.light_base+Vector3(-6.6,4.85,2.8)
	var p=world.light_base+Vector3(sin(a)*27.,10.3+sin(t*.10)*.5,cos(a)*27.)
	camera.position=p
	camera.look_at(q,Vector3.UP)
	camera.fov=55

func follow_camera(dt:float,snap:bool=false):
	var target=actor.position+Vector3.UP*2.05+Vector3(velocity.x,0,velocity.y)*.12
	if snap: cam_target=target
	else: cam_target=cam_target.lerp(target,1-exp(-dt*8.5))
	var flat=cos(pitch)*zoom
	var offset=Vector3(sin(yaw)*flat,sin(pitch)*zoom+.50,cos(yaw)*flat)
	var want=cam_target+offset
	var ground_h=world.ground(Vector2(want.x,want.z))
	want.y=max(want.y,ground_h+1.42,water+1.12)
	for i in [2,4,6,8]:
		var f=i*.1
		var probe=cam_target.lerp(want,f)
		var under=world.ground(Vector2(probe.x,probe.z))+.42-probe.y
		if under>0: want.y+=under/max(f,.15)
	camera.position=want
	camera.look_at(cam_target,Vector3.UP)
	camera.fov=lerpf(camera.fov,52.+min(2.,speed*.24),1-exp(-dt*3.3))

func set_actor_height(snap:bool=false,dt:float=.016):
	var base=camp.deck_height(xy)
	var surface:float=world.campaign.water_at(xy,water)
	depth=maxf(0.,surface-base)
	var target=maxf(base,surface-.98+.055*sin(visual_time*3))
	actor.position=Vector3(xy.x,target if snap else lerpf(actor.position.y,target,1-exp(-dt*16.0)),xy.y)

func open_panel(s:String):
	reset_touch()
	mouselook=false
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	previous_panel=state
	state="campaign_atlas" if s=="map" and campaign_phase>=0 else s
	hud.focus_index=0
	if s in ["pause","map","help","craft"]: save_run()

func close_panel():
	if state=="confirm_new": state="menu"
	elif state=="help": state=menu_return
	else: state="play"
	gather_cd=.30
	mouselook=false
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	hud.focus_index=0

func command(id:String):
	match id:
		"replay":
			if state=="salvage" and salvage.site==1: salvage.replay()
		"new": begin_or_confirm()
		"confirm": new_run()
		"resume": resume_run()
		"back": close_panel()
		"help":
			menu_return=state
			open_panel("help")
		"sound": audio.mute(); pref()
		"music": audio.music_on=not audio.music_on; pref()
		"full": toggle_fullscreen()
		"map": open_panel("map")
		"campaign_atlas": state="campaign_atlas"
		"atlas_style": hud.illustrated_atlas=not hud.illustrated_atlas
		"local_atlas": state="map"
		"craft": open_panel("craft")
		"menu": go_menu()
		"respawn": respawn()
		"free":
			state="play"
			reset_camera()
			save_run()
			notify("Le phare veille. L’archipel reste à explorer.",4)
		"quit":
			exit_game()
		"skip": finish_cinematic()
		"story_next": opening.advance_line()
		"arrival_skip": opening.finish_crossing()
		_:
			if id.begins_with("chart_"):
				var marker=id.trim_prefix("chart_")
				if world.campaign.zones.has(marker):
					campaign_track="" if campaign_track==marker else marker
					selected_site=-1
			if id.begins_with("plans_"):
				hud.craft_tab=int(id.trim_prefix("plans_"))
				audio.effect("prise",-13,1.18)
			if id.begins_with("salvagebuild_") and state=="remove": camp.dismantle(int(id.trim_prefix("salvagebuild_")))
			if id.begins_with("salvage_") and state=="salvage":
				salvage.action(int(id.trim_prefix("salvage_")))
			if id.begins_with("make_"):
				state="play"
				camp.begin(id.trim_prefix("make_"))
			if id.begins_with("track_"):
				var i=int(id.trim_prefix("track_"))
				selected_site=-1 if selected_site==i else i
				save_run()
				audio.effect("prise",-10,1.2)

func _input(event):
	if not hud: return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		handle_touch(event)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k=event.keycode
		if k==KEY_F11: toggle_fullscreen(); return
		if k==KEY_F2 and state=="play": ui_hidden=not ui_hidden; return
		if state=="story_dialogue":
			if k in [KEY_E,KEY_ENTER,KEY_KP_ENTER,KEY_SPACE,KEY_ESCAPE]: opening.advance_line()
			return
		if state=="arrival_film":
			if k in [KEY_E,KEY_ENTER,KEY_SPACE,KEY_ESCAPE]: opening.finish_crossing()
			return
		if state=="cinema":
			if k in [KEY_ESCAPE,KEY_ENTER,KEY_SPACE]: finish_cinematic()
			return
		if state=="salvage":
			if k==KEY_ESCAPE: close_panel()
			elif salvage.site==0 and k in [KEY_SPACE,KEY_E,KEY_ENTER]: salvage.action()
			elif salvage.site==1 and k==KEY_R: salvage.replay()
			elif event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_3: salvage.action(event.physical_keycode-KEY_1)
			elif k>=KEY_1 and k<=KEY_3: salvage.action(k-KEY_1)
			else: hud.key_nav(k)
			return
		if k==KEY_ESCAPE:
			if state=="play":
				if camp.kind!="": camp.cancel()
				else: open_panel("pause")
			elif state in ["map","campaign_atlas","craft","help","pause","confirm_new","letter","remove"]: close_panel()
			return
		if state=="menu" and k in [KEY_ENTER,KEY_SPACE] and hud.focus_index==0:
			if active_save: resume_run()
			else: new_run()
			return
		if state in ["map","campaign_atlas"] and k in [KEY_M,KEY_TAB]: close_panel(); return
		if state=="craft":
			if k==KEY_B: close_panel(); return
			if k>=KEY_1 and k<=KEY_9:
				command("make_"+Camp.KINDS[k-KEY_1]); return
			if event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_9:
				command("make_"+Camp.KINDS[event.physical_keycode-KEY_1]); return
		if state!="play":
			hud.key_nav(k)
			return
		if k in [KEY_M,KEY_TAB]: open_panel("map"); return
		if k==KEY_B and sailing.is_empty(): open_panel("craft"); return
		if k==KEY_X and sailing.is_empty():
			camp.cancel()
			if camp.nearby().is_empty(): notify("Approche-toi d’une de tes constructions pour la démonter.")
			else: open_panel("remove")
			return
		if k==KEY_H or k==KEY_F1: menu_return="play"; open_panel("help"); return
		if sailing.is_empty() and ((k>=KEY_1 and k<=KEY_9) or (event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_9)):
			var i=k-KEY_1 if k>=KEY_1 and k<=KEY_9 else event.physical_keycode-KEY_1
			camp.begin(Camp.KINDS[i]); return
		if k==KEY_R:
			if camp.kind!="": camp.rotate_piece()
			else: eat()
			return
		if k==KEY_E:
			if camp.kind!="": camp.commit()
			else: interact()
			return
		if k==KEY_SPACE: ring_bell(); return
		if k==KEY_C:
			yaw=actor.facing
			return
	if event is InputEventMouseMotion:
		if mouselook and state=="play":
			heading_free=3.3
			yaw-=event.relative.x*.006
			pitch=clampf(pitch+event.relative.y*.004,.12,.92)
		elif state=="play" and camp.kind!="":
			camp.aim_from_mouse=true
		hud.pointer_mode=true
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			if state=="play":
				mouselook=event.pressed
				Input.mouse_mode=Input.MOUSE_MODE_CAPTURED if mouselook else Input.MOUSE_MODE_VISIBLE
			return
		if not event.pressed: return
		if event.button_index==MOUSE_BUTTON_LEFT:
			if state!="play": hud.click_at(event.position)
			elif camp.kind!="": camp.commit()
			elif hud.click_hud(event.position): pass
		if state=="play" and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom=clampf(zoom+(-1.45 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.45),6.4,23.)

func reset_touch():
	move_finger=-1
	look_finger=-1
	touch_move=Vector2.ZERO

func handle_touch(event):
	touch_mode=true
	if event is InputEventScreenTouch:
		if not event.pressed or event.canceled:
			if event.index==move_finger:
				move_finger=-1
				touch_move=Vector2.ZERO
			if event.index==look_finger: look_finger=-1
			return
		if state!="play":
			if state=="cinema": finish_cinematic()
			else: hud.click_at(event.position)
			return
		var key:int=hud.touch_key(event.position)
		if key!=0:
			var press=InputEventKey.new()
			press.keycode=key
			press.pressed=true
			_input(press)
			return
		if hud.touch_stick_hit(event.position) and move_finger==-1:
			move_finger=event.index
			touch_move=hud.touch_stick_value(event.position)
		elif look_finger==-1:
			look_finger=event.index
	elif state=="play":
		if event.index==move_finger:
			touch_move=hud.touch_stick_value(event.position)
		elif event.index==look_finger:
			heading_free=3.3
			var delta:Vector2=event.relative/maxf(hud.ui_scale,.01)
			yaw-=delta.x*.004
			pitch=clampf(pitch+delta.y*.003,.12,.92)
			camp.aim_from_mouse=false

func input_move()->Vector2:
	if touch_move!=Vector2.ZERO: return touch_move.rotated(-yaw)
	var x=float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var z=float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	return Vector2(x,z).normalized().rotated(-yaw)

func reachable_world(p:Vector2)->bool:
	return world.campaign.inside(p) and (campaign_phase<0 or campaign_phase>=4 or not KeravelMap.on_outer_island(p))

func can_walk(p:Vector2)->bool:
	if not reachable_world(p): return false
	if world.blocked(p,.19) and not world.blocked(xy,.19): return false
	if camp.building_blocks_move(xy,p,actor.position.y): return false
	return true

func move_player(dt:float):
	var dir=input_move()
	if dir!=Vector2.ZERO and camp.kind!="": camp.aim_from_mouse=false
	if Input.is_key_pressed(KEY_J): yaw+=dt*1.65
	if Input.is_key_pressed(KEY_L): yaw-=dt*1.65
	if stamina<2.1: exhausted=true
	elif stamina>17.: exhausted=false
	var sprint=(Input.is_key_pressed(KEY_SHIFT) or touch_move.length()>.96) and not exhausted and dir!=Vector2.ZERO
	var pace=5.0 if not sprint else 7.5
	if depth>.12: pace=lerpf(pace,2.9 if not sprint else 3.7,clamp(depth,0,1))
	velocity=velocity.move_toward(dir*pace,(20. if dir!=Vector2.ZERO else 29.)*dt)
	var candidate=xy+velocity*dt
	if can_walk(candidate): xy=candidate
	else:
		if can_walk(Vector2(candidate.x,xy.y)): xy.x=candidate.x
		if can_walk(Vector2(xy.x,candidate.y)): xy.y=candidate.y
	speed=velocity.length()
	if dir!=Vector2.ZERO: actor.facing=atan2(-dir.x,-dir.y)
	set_actor_height(false,dt)
	if depth>.99: stamina-=dt*(10.5 if sprint else 8.6)*(.8 if stamps[2] else 1.)
	elif sprint: stamina-=dt*4.6
	else: stamina+=dt*(8.5 if depth<.4 else 4.2)
	stamina=clampf(stamina,0,100)
	if depth>.99 and stamina<=.01:
		hurt(20.0)
		xy=safe
		stamina=47
		warmth=maxf(0,warmth-13)
		set_actor_height(true); reset_camera()
		notify("Le courant t’a rejeté sur la dernière rive.",4.2)
	if depth<.06 and world.ground(xy)>2.24 and not camp.kind=="bridge": safe=xy
	foot_clock-=dt*speed
	if speed>1 and foot_clock<=0:
		foot_clock=2.1 if sprint else 1.75
		audio.effect("eau" if depth>.13 else "pas",-10 if depth>.13 else -12,rng.randf_range(.88,1.15))
		if depth>.18: camp.spray(Vector3(xy.x,water,xy.y),"water",2)

func find_nearest():
	var best=INF
	nearest={}
	if camp.kind!="": return
	if not sailing.is_empty():
		nearest={"kind":"disembark","at":xy,"label":"Quitter la yole"}
		return
	var story_target=campaign_action()
	if not story_target.is_empty():
		nearest=story_target
		return
	var target=marsh.target()
	if not target.is_empty(): nearest=target; return
	var dl=xy.distance_to(World.LIGHT)
	if dl<5.6:
		nearest={"kind":"phare","label":("Consulter la veille" if signal_active else "Rallumer le phare") if not rescued else "Écouter le large","at":World.LIGHT}
		best=max(0.,dl-2.45)
	for i in 3:
		var d=xy.distance_to(world.shore.relics[i])
		if d<2.8 and d<best:
			best=d
			nearest={"kind":"letter","index":i,"at":world.shore.relics[i],"label":"Ouvrir la boîte du veilleur" if not stamps[i] else "Relire le mot"}
	for i in 3:
		if campaign_phase==1 and opening.step<StoryOpening.COMPLETE: break
		if pieces[i]: continue
		var d=xy.distance_to(world.spots[i])
		if d<3.15 and d<best:
			best=d
			nearest={"kind":"site","index":i,"at":world.spots[i],"label":"Récupérer • "+World.PARTS[i]}
	for it in camp.items:
		if it.kind in ["bridge","floor","wall","door"]: continue
		var d=xy.distance_to(it.at)
		if d<2.95 and d<best:
			best=d
			var label={"fire":"Prendre la chaleur","shelter":"Dormir • 1 ration","roof":"Dormir à la cabane • 1 ration","trap":"Relever le casier" if it.charge>=.999 else "Examiner le casier","skiff":"Monter dans la yole"}[it.kind]
			nearest={"kind":"camp","item":it,"label":label,"at":it.at}
	for i in world.resources.size():
		var r=world.resources[i]
		if r.ready>age or r.covered: continue
		var d=xy.distance_to(r.at)
		if d<2.75 and d<best:
			best=d
			nearest={"kind":"resource","index":i,"at":r.at,"label":{"wood":"Ramasser le bois","stone":"Ramasser le silex","food":"Cueillir les baies"}[r.kind]}

func interact():
	if state!="play" or gather_cd>0.: return
	find_nearest()
	if nearest.is_empty(): return
	gather_cd=.39
	match nearest.kind:
		"campaign": advance_campaign(nearest.id)
		"marsh": marsh.use(nearest.index)
		"disembark": disembark()
		"letter":
			stamp_page=nearest.index
			open_panel("letter")
			if not stamps[stamp_page]:
				stamps[stamp_page]=true
				audio.effect("vestige",-5)
				save_run()
		"resource":
			var r=world.resources[nearest.index]
			var n=(4 if stamps[1] else 3) if r.kind=="wood" else 2
			bag[r.kind]+=n
			r.ready=age+(95 if r.kind=="food" else 130)
			r.node.visible=false
			harvests+=1
			camp.spray(world.pos(r.at)+Vector3.UP*.45,r.kind,7)
			audio.effect("prise",-6,rng.randf_range(.92,1.13))
			notify("+%d %s"%[n,{"wood":"bois flottés","stone":"silex","food":"rations de baies"}[r.kind]],2.1)
			if not build_tip and not has_ember and bag.wood>=3 and bag.stone>=2:
				build_tip=true
				notify("Assez de matériaux • B pour construire ton premier feu.",4.3)
			if campaign_phase==1: opening.added(r.kind,n)
		"site": recover_part(nearest.index)
		"phare":
			if campaign_phase==1 and has_ember and pieces.count(true)==3:
				campaign_phase=2
				world.set_campaign_lamp(35)
				campaign_track=""
				notify("Le phare retrouve une lueur pâle. À Trois-Vannes, enquête sur la braise volée.",6)
				save_run()
			elif campaign_phase==5:
				campaign_phase=6
				world.set_campaign_lamp(100)
				campaign_track=""
				notify("Le Kalon-Glas rallume Keravel. Tu peux continuer à explorer l’archipel.",6)
				save_run()
			elif campaign_phase in [2,3,4,6]: notify("Le phare veille sur le chenal.")
			elif rescued: audio.effect("corne",-6); notify("Le canot de relève garde le contact.")
			elif signal_active: notify("Reste près du phare. Réponds avec Espace quand le canot appelle.",4)
			elif not has_ember or pieces.count(true)<3: notify("La lanterne réclame trois pièces et la braise d’un feu de camp.",4.4)
			else: start_watch()
		"camp":
			var it=nearest.item
			match it.kind:
				"skiff":
					sailing=it
					sail_speed=0.
					xy=it.at
					camp.cancel()
					notify("À la barre • avance pour border la voile, gauche et droite pour virer.",4.3)
					audio.effect("eau",-2)
					save_run()
				"fire":
					if not has_ember: has_ember=true
					notify("Près du feu, ta chaleur et ta santé remontent."); audio.effect("braise",-6)
				"trap":
					if it.charge<.999: notify("Casier à %d %% • il se remplit sous l’eau."%roundi(it.charge*100))
					else:
						it.charge=0.; bag.food+=3; audio.effect("prise",-3); notify("Prise du jour • +3 rations de poisson."); save_run()
				"shelter","roof":
					if bag.food<1: notify("Il faut une ration pour passer la nuit.")
					else:
						bag.food-=1; home=it.at+Vector2(.0,1.8); safe=home
						var next_day=(floor(age/DAY)+1.)*DAY
						var elapsed=next_day-age
						for other in camp.items:
							if other.kind=="trap" and elapsed>45: other.charge=1.
						age=next_day; warmth=100; stamina=100; hp=minf(100,hp+32); hunger=minf(100,hunger+13)
						clear_foes(); refresh_pickups(); update_sea()
						dawn_fade=1.; next_cry=age+12; audio.effect("vestige",-9)
						notify("À l’aube • camp de repli enregistré.",4.2); save_run()
	find_nearest()

func recover_part(i:int):
	if pieces[i]: return
	var cost=[0,4,4][i]
	var k="stone" if i==1 else "wood"
	if bag[k]<cost:
		notify("Il faut %d %s pour %s."%[cost,"silex" if i==1 else "bois","caler le treuil" if i==1 else "étayer l’atelier"],4)
		return
	salvage.begin(self,i)
	open_panel("salvage")

func claim_part(i:int):
	if pieces[i]: return
	var cost=[0,4,4][i]
	var k="stone" if i==1 else "wood"
	bag[k]-=cost
	pieces[i]=true
	if selected_site==i: selected_site=-1
	camp.spray(world.pos(world.spots[i])+Vector3.UP,"gold",15)
	audio.effect("vestige",-2)
	notify(World.PARTS[i]+" récupéré"+("e" if i!=1 else "")+" • %d / 3"%pieces.count(true),4.5)
	save_run()

func campaign_destination()->String:
	match campaign_phase:
		0: return opening.destination()
		1:
			if opening.step<StoryOpening.COMPLETE: return opening.destination()
			for i in 3:
				if not pieces[i]: return ["le-courlis","corne-de-brume","ateliers-salines"][i]
			return "phare-keravel" if has_ember else "prairie-phare"
		2: return "tv-place-cloche"
		3: return "tv-port"
		4:
			if expedition_index<EXPEDITION.size(): return EXPEDITION[expedition_index]
		5: return "phare-keravel"
	return ""

func campaign_action()->Dictionary:
	if campaign_phase in [0,1] and opening.step<StoryOpening.COMPLETE: return opening.action()
	var id=campaign_destination()
	if id=="" or id=="phare-keravel" or campaign_phase==1: return {}
	var p:Vector2=world.campaign.points[id]
	if xy.distance_to(p)>4.4: return {}
	var label="Lire le repère"
	match campaign_phase:
		0: label="Embarquer pour le ponton du phare"
		2: label="Consulter les annonces de Trois-Vannes"
		3: label="Prendre la Veilleuse vers Enez-Aerouant"
		4:
			match id:
				"ea-ruines-veilleurs": label="Lire le message d’Erwan"
				"ea-salle-verte": label="Récupérer le Kalon-Glas"
				"ea-plage-naufrages": label="Reprendre la Veilleuse vers Trois-Vannes"
	return {"kind":"campaign","id":id,"at":p,"label":label}

func campaign_landing(id:String):
	xy=world.campaign.points[id]
	safe=xy
	home=xy
	velocity=Vector2.ZERO
	set_actor_height(true)
	reset_camera()

func advance_campaign(id:String):
	if id!=campaign_destination(): return
	if campaign_phase in [0,1] and opening.step<StoryOpening.COMPLETE:
		opening.accept(id)
		campaign_track=""
		save_run()
		return
	match campaign_phase:
		2:
			campaign_phase=3
			notify("Les registres du Baron désignent Kastell-Glas. La Veilleuse attend au port.",6)
		3:
			campaign_phase=4
			campaign_landing("ea-plage-naufrages")
			notify("La tempête t’a rejeté sur la plage. Gagne le camp des Naufragés.",6)
		4:
			expedition_index+=1
			if id=="ea-plage-naufrages":
				campaign_phase=5
				campaign_landing("tv-port")
				notify("Retour à Trois-Vannes. Rapporte le Kalon-Glas au phare par la route côtière.",6)
			elif id=="ea-ruines-veilleurs": notify("Message d’Erwan • Le Kalon-Glas est le cœur d’Aerouant.",6)
			elif id=="ea-salle-verte": notify("Kalon-Glas récupéré • Fuis par la Crête des Vents.",6)
			else: notify(world.campaign.zones[id].description,5.5)
	campaign_track=""
	save_run()

func eat():
	if bag.food<=0: notify("Provisions épuisées • cherche des baies ou relève un casier."); return
	if hunger>97 and hp>96: notify("Tu es rassasié."); return
	bag.food-=1
	hunger=minf(100,hunger+31)
	hp=minf(100,hp+5)
	audio.effect("prise",-9,.79)
	notify("Une ration • +31 de satiété.")
	save_run()

func ring_bell():
	if cool>0:
		notify("La cloche résonne encore • %.0f s"%ceil(cool),1.2)
		return
	cool=3. if marsh.stage==3 else 5.
	marsh.strike()
	ring_anim=.64
	audio.effect("cloche",-3)
	camp.ripple(actor.position,7.4,.94)
	var n=0
	for f in foes:
		var delta=f.at-xy
		if delta.length()<8.6:
			if delta.length()<.05: delta=Vector2(1,0)
			f.at+=delta.normalized()*4.5
			f.stun=4.; f.life-=1; n+=1
	if n>0: notify("Le timbre repousse les noyés.",2)
	if signal_active and age>=next_signal:
		if xy.distance_to(World.LIGHT)>12.:
			notify("Le canot ne t’entend pas • rapproche-toi du phare.",3.6)
		else:
			signal_calls+=1
			audio.effect("vestige",-5,1.+signal_calls*.08)
			if signal_calls>=3: victory()
			else:
				next_signal=age+11.+signal_calls*1.7;call_announced=false
				notify("Accusé de réception • %d / 3 appels."%signal_calls,3)
				save_run()

func refresh_pickups():
	for r in world.resources:
		if not r.node.visible and not r.covered and r.ready<=age: r.node.visible=true

func hurt(amount:float):
	hp=max(0.,hp-amount)
	hit_flash=.55
	audio.effect("choc",-5)
	if hp<=0 and state=="play":
		state="dead"
		camp.cancel()
		mouselook=false
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		hud.focus_index=0
		save_run()

func survive(dt:float):
	var fire=camp.has_fire(xy,5.7)
	var sheltered=false
	for it in camp.items:
		if it.kind in ["shelter","roof"] and xy.distance_to(it.at)<2.7: sheltered=true; break
	hunger=maxf(0.,hunger-dt*(.178+(.038 if speed>5.1 else 0.0)))
	var chill=(.05+.35*night+.32*storm+.82*clampf(depth,0,1)) if night>.13 or storm>.27 or depth>.22 else -.17
	if fire: chill=-3.8
	elif sheltered: chill=-.95
	if chill>0 and stamps[0]: chill*=.75
	warmth=clampf(warmth-dt*chill,0,100)
	if fire and hunger>16: hp=minf(100,hp+dt*.84)
	if warmth<.1 or hunger<.1:
		hp-=dt*(.72 if warmth<.1 else .48)
		if hp<=0: hurt(1)
	if warmth<22 and not fog_warnings.has("cold"):
		fog_warnings.cold=true; notify("Tu grelottes • un feu ou un abri te réchauffera.",4)
	if hunger<28 and not fog_warnings.has("food"):
		fog_warnings.food=true; notify("La faim se fait sentir • R pour manger.",4)
	if warmth>60: fog_warnings.erase("cold")
	if hunger>60: fog_warnings.erase("food")

func clear_foes():
	for f in foes: f.node.queue_free()
	foes.clear()

func threat(dt:float):
	var danger=night>.54 or storm>.72
	foe_clock-=dt
	if danger and foe_clock<=0 and foes.size()<mini(4,1+day_number()):
		foe_clock=16.
		var a=rng.randf()*TAU
		var p=xy+Vector2(cos(a),sin(a))*rng.randf_range(17.,23.)
		var g=Actor.spectre(world.mat)
		add_child(g)
		foes.append({"node":g,"at":p,"stun":0.,"life":2,"seed":rng.randf()*9.})
		audio.effect("noye",-10,.93)
		if not told_bell: told_bell=true; notify("Un noyé approche • Espace pour sonner la cloche.",5)
	for i in range(foes.size()-1,-1,-1):
		var f=foes[i]
		var diff=xy-f.at
		if f.life<=0 or diff.length()>56 or (not danger and diff.length()>17):
			camp.spray(f.node.position+Vector3.UP,"water",5)
			f.node.queue_free(); foes.remove_at(i); continue
		f.stun=maxf(0.,f.stun-dt)
		var afraid=not danger or camp.has_fire(xy,5.2) or camp.has_fire(f.at,5.1)
		if f.stun<.01:
			var step=diff.normalized()*(1.30+day_number()*.075)
			if afraid: step*=-1.75
			f.at+=step*dt
			if diff.length()<1.38 and age-last_hit>3.8 and not afraid:
				last_hit=age
				hurt(12.)
				f.stun=2.8
				notify("Le noyé te glace • fais sonner ta cloche.",2.6)
		var h=maxf(world.ground(f.at),water-.18)
		f.node.position=Vector3(f.at.x,h+.22+sin(visual_time*2+f.seed)*.11,f.at.y)
		f.node.rotation.y=atan2(-diff.x,-diff.y)+(sin(visual_time*12)*.17 if f.stun>0 else 0.)

func victory():
	signal_active=false
	rescued=true
	state="cinema"
	cinematic_t=0.
	camp.cancel()
	clear_foes()
	boat.visible=true
	audio.effect("vestige",0)
	audio.effect("corne",-1,.93)
	world.beam.visible=true
	save_run()

func start_watch():
	signal_active=true;signal_calls=0;signal_start=age;next_signal=age+5.;call_announced=false
	selected_site=3
	foe_clock=2.4
	world.beam.visible=true
	audio.effect("vestige",-1)
	notify("Le phare est allumé. Réponds aux trois appels du canot avec ta cloche.",5.2)
	save_run()

func signal_watch():
	if signal_active and age>=next_signal and not call_announced:
		call_announced=true
		audio.effect("corne",-3,.93+signal_calls*.06)
		notify("Appel du canot • Espace près du phare pour répondre.",5.4)

func finish_cinematic():
	state="won"
	hud.focus_index=0
	save_run()

func cinematic(dt:float):
	cinematic_t+=dt
	var f=clampf(cinematic_t/8.,0,1)
	var a=.82-f*.99
	var target=world.light_base+Vector3(-3.,6.0,1.)
	camera.position=world.light_base+Vector3(sin(a)*37,13.2+f*3,cos(a)*37)
	camera.look_at(target,Vector3.UP)
	camera.fov=52
	var loc=boat_start.lerp(boat_end,smoothstep(0,1,f))
	boat.position=Vector3(loc.x,water+.32+sin(visual_time*1.8)*.12,loc.y)
	boat.rotation.y=atan2(boat_start.x-boat_end.x,boat_start.y-boat_end.y)
	boat.rotation.z=sin(visual_time)*.045
	world.atmosphere(visual_time,water,minf(night,.38),0,true)
	if cinematic_t>9.1: finish_cinematic()

func tick_rain():
	rain.visible=storm>.21
	if not rain.visible: return
	var mm=rain.multimesh
	mm.visible_instance_count=clampi(int(mm.instance_count*storm),1,mm.instance_count)
	rain.position=actor.position
	for i in mm.visible_instance_count:
		var q=drops[i]
		var y=fposmod(q.y-visual_time*(12.+i%3),12.)
		mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(q.x+(12.-y)*.18,y-1.,q.z)))

func _process(delta):
	if not hud: return
	if browser_qa:
		browser_qa.update(state,xy.x,xy.y,yaw,hud.v.x,hud.v.y,hud.safe_insets.x,hud.safe_insets.y,hud.safe_insets.z,hud.safe_insets.w)
	var dt=minf(delta,.065)
	visual_time+=dt
	if state=="menu" or state=="confirm_new" or (state=="help" and menu_return=="menu"):
		menu_t+=dt
		menu_camera(menu_t)
		world.atmosphere(visual_time,-.48+.12*sin(menu_t*.16),.02,0,false)
		audio.mix(.61,0,0)
	elif state=="play":
		age+=dt
		update_sea()
		world.atmosphere(visual_time,water,night,storm,rescued or signal_active or campaign_phase>=2)
		signal_watch()
		if sailing.is_empty(): move_player(dt)
		else: sail(dt)
		if campaign_phase==1: opening.tick(dt)
		actor.pose(dt,speed if sailing.is_empty() else 0.,depth,ring_anim,night,visual_time)
		ring_anim=maxf(0,ring_anim-dt); cool=maxf(0,cool-dt)
		gather_cd=maxf(0,gather_cd-dt)
		gather_clock-=dt
		if gather_clock<=0:
			gather_clock=.12
			refresh_pickups()
			find_nearest()
			if Input.is_key_pressed(KEY_E) and nearest.get("kind","")=="resource" and gather_cd<=0: interact()
		survive(dt)
		if state=="play": threat(dt)
		if state=="play": marsh.tick(dt)
		follow_camera(dt)
		camp.tick(dt,visual_time)
		tick_rain()
		audio.mix(clamp((3.6-world.ground(xy))/4.8,0,1),storm,night)
		if age>next_cry:
			if night<.5: audio.effect("goeland",-14,rng.randf_range(.86,1.12))
			next_cry=age+rng.randf_range(19,39)
		var loc=world.region(xy)
		if loc!=last_region: last_region=loc; region_t=3.4
		if storm>.47 and seen_weather!="grain":
			seen_weather="grain"; notify("Avis de grain • le froid gagne les passages exposés.",4)
		if storm<.16: seen_weather=""
		autosave+=dt
		if autosave>=8.: autosave=0.; save_run()
		if rescued:
			boat.visible=true
			boat.position=Vector3(boat_end.x,water+.37+sin(visual_time)*.14,boat_end.y)
			boat.rotation.z=sin(visual_time*.87)*.045
	elif state=="cinema":
		cinematic(dt)
	elif state=="arrival_film":
		update_sea()
		world.atmosphere(visual_time,water,.23,.08,false)
		opening.tick_crossing(dt)
	elif state=="salvage":
		salvage.tick(dt)
	elif state=="won":
		world.beam.rotation.y=visual_time*.64
	if state=="play":
		toast_time=maxf(0,toast_time-dt); region_t=maxf(0,region_t-dt); hit_flash=maxf(0,hit_flash-dt); dawn_fade=maxf(0,dawn_fade-dt*.46); save_timer_msg=maxf(0,save_timer_msg-dt)
	hud.queue_redraw()

func disembark():
	if sailing.is_empty(): return
	var forward=Vector2(-sin(sailing.heading),-cos(sailing.heading))
	var options=[xy+forward.orthogonal()*1.7,xy-forward.orthogonal()*1.7,xy-forward*2.2]
	var landing=xy
	for p in options:
		if can_walk(p) and (landing==xy or camp.deck_height(p)>camp.deck_height(landing)): landing=p
	if landing==xy:
		notify("Il n’y a pas assez de place pour débarquer.")
		return
	xy=landing
	sailing={};sail_speed=0.;velocity=Vector2.ZERO
	set_actor_height(true)
	audio.effect("eau",-5)
	save_run()

func sail(dt:float):
	var ahead=touch_move.y<-.25 or Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var brake=touch_move.y>.25 or Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	var left=touch_move.x<-.25 or Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var right_key=touch_move.x>.25 or Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	var turn=float(left)-float(right_key)
	sailing.heading+=turn*dt*(1.47 if abs(sail_speed)>1.0 else 1.)
	var front=Vector2(-sin(sailing.heading),-cos(sailing.heading))
	var wind=Vector2(.87,-.46).normalized()
	var wet=clampf((water-world.ground(sailing.at)+.24)/.78,0.,1.)
	var max_pace=(5.8+(front.dot(wind)*.5+.5)*4.2)*lerpf(.24,1.,wet)
	var target=max_pace if ahead else (-2.65 if brake else 0.)
	sail_speed=move_toward(sail_speed,target,dt*(3.8 if ahead else 4.6))
	var candidate=sailing.at+front*sail_speed*dt
	if world.ground(candidate)>water+.45 and world.ground(candidate)>world.ground(sailing.at):
		sail_speed=0.
	elif reachable_world(candidate) and not world.on_pier(candidate) and not world.blocked(candidate,.65) and not camp.building_blocks_move(sailing.at,candidate,sailing.y+.44):
		sailing.at=candidate
	else: sail_speed=0.
	xy=sailing.at
	actor.facing=sailing.heading
	actor.position=Vector3(xy.x,sailing.y+.44,xy.y)-Vector3(front.x,0,front.y)*1.15
	speed=abs(sail_speed);depth=0.;stamina=minf(100,stamina+dt*8)
	velocity=front*sail_speed
	heading_free=maxf(0.,heading_free-dt)
	if not mouselook and heading_free<=0 and speed>1.2: yaw=lerp_angle(yaw,sailing.heading,1.-exp(-dt*1.75))
	wake_clock-=dt
	if wet>.4 and speed>1.2 and wake_clock<=0:
		var stern=Vector3(xy.x,water+.015,xy.y)-Vector3(front.x,0,front.y)*1.80
		camp.spray(stern,"water",2)
		camp.ripple(stern-Vector3.UP*.13,1.0+speed*.115,.71)
		wake_clock=.30
