extends Control
const W=preload("res://biome.gd")
const C=preload("res://camp.gd")
const PAPER=Color("#f7ecd1")
const GOLD=Color("#edc782")
const MINT=Color("#a6ccba")
const MUTED=Color("#abc0b7")
const INK=Color("#132e35")
const DEEP=Color("#0d222b")
const BRICK=Color("#d18465")
const GLASS=Color(.045,.115,.14,.88)
const WASH=Color(.72,.82,.77,.27)
var game
var sans=SystemFont.new()
var bold=SystemFont.new()
var serif=SystemFont.new()
var mono=SystemFont.new()
var v=Vector2(1440,810)
var ui_scale=1.
var buttons=[]
var focus_index=0
var pointer_mode=true
var hand=false
var mpos=Vector2.ZERO
var last_state=""
var shade:GradientTexture2D
var side_shade:GradientTexture2D
var last_region=""
var last_pointer=Vector2.ZERO
var map_rect=Rect2()
var craft_tab=0

func _ready():
	sans.font_names=PackedStringArray(["Bahnschrift","Trebuchet MS","Arial"])
	bold.font_names=sans.font_names
	bold.font_weight=700
	serif.font_names=PackedStringArray(["Georgia","Times New Roman"])
	mono.font_names=PackedStringArray(["Consolas","Courier New"])
	shade=gradient([Color(.015,.043,.056,.0),Color(.015,.043,.056,.70),Color(.015,.043,.056,.94)],[0.,.52,1.],Vector2(0,.0),Vector2(0,1))
	side_shade=gradient([Color(.018,.060,.074,.97),Color(.018,.060,.074,.86),Color(.018,.060,.074,.24),Color(.018,.060,.074,0)],[0.,.41,.81,1.],Vector2(0,0),Vector2(1,0))

func gradient(cols:Array,off:Array,a:Vector2,b:Vector2)->GradientTexture2D:
	var gr=Gradient.new()
	gr.offsets=PackedFloat32Array(off)
	gr.colors=PackedColorArray(cols)
	var tx=GradientTexture2D.new()
	tx.gradient=gr;tx.fill_from=a;tx.fill_to=b;tx.width=256;tx.height=64
	return tx

func txt(s:String,x:float,y:float,fs:int=18,col:Color=PAPER,font:Font=null,align:HorizontalAlignment=HORIZONTAL_ALIGNMENT_LEFT,width:float=-1.):
	draw_string(font if font else sans,Vector2(x,y),s,align,width,fs,col)
func center(s:String,x:float,y:float,fs:int=18,col:Color=PAPER,font:Font=null):
	var fo=font if font else sans
	txt(s,x-fo.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x*.5,y,fs,col,fo)
func right(s:String,x:float,y:float,fs:int=16,col:Color=PAPER,font:Font=null):
	var fo=font if font else sans
	txt(s,x-fo.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x,y,fs,col,fo)
func line(a:Vector2,b:Vector2,c:Color=WASH,w:float=1.): draw_line(a,b,c,w,true)
func panel(r:Rect2,c:Color=GLASS,stroke:Color=WASH):
	draw_rect(r,c)
	if stroke.a>.01: draw_rect(r,stroke,false,1.)
func ptext(s:String,p:Vector2,width:float,fs:int=18,c:Color=MUTED,f:Font=null,lead:float=1.32)->float:
	var font=f if f else sans
	var words=s.split(" "); var row=""; var y=p.y
	for word in words:
		if word=="": continue
		var test=row+" "+word if row!="" else word
		if row!="" and font.get_string_size(test,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>width:
			txt(row,p.x,y,fs,c,font); y+=fs*lead; row=word
		else: row=test
	if row!="": txt(row,p.x,y,fs,c,font)
	return y+fs*lead
func keycap(s:String,p:Vector2,w:float=28,h:float=25,accent:bool=false):
	var bg=GOLD if accent else Color(.72,.80,.75,.14)
	draw_rect(Rect2(p,Vector2(w,h)),bg)
	draw_rect(Rect2(p,Vector2(w,h)),GOLD if accent else WASH,false,1.)
	center(s,p.x+w*.5,p.y+h*.72,int(h*.57),INK if accent else PAPER,bold)
func path(points:Array,c:Color,w:float=2.):
	draw_polyline(PackedVector2Array(points),c,w,true)
func poly(points:Array,c:Color): draw_colored_polygon(PackedVector2Array(points),c)
func icon(k:String,p:Vector2,s:float=20,col:Color=PAPER):
	var q=s/20.
	var pp=func(a:float,b:float): return p+Vector2(a,b)*q
	var l=func(a:float,b:float,c:float,d:float): line(pp.call(a,b),pp.call(c,d),col,maxf(1.,1.55*q))
	var pts=func(arr:Array):
		var out=[]
		for a in arr: out.append(pp.call(a[0],a[1]))
		return out
	match k:
		"wood":
			path(pts.call([[-8,4],[3,-7],[8,-4],[-3,7],[-8,4],[-7,0],[3,-9],[8,-6],[8,-4]]),col,1.6*q)
			l.call(-5,2,4,-6)
		"stone":
			path(pts.call([[-8,2],[-3,-6],[4,-7],[9,1],[5,6],[-5,7],[-8,2],[1,0],[4,-7]]),col,1.6*q);l.call(1,0,5,6)
		"food":
			for a in [[-4,3],[3,4],[0,-2]]: draw_circle(pp.call(a[0],a[1]),3.5*q,col)
			l.call(0,-3,3,-9); l.call(2,-7,7,-7)
		"fire","warmth":
			path(pts.call([[-6,7],[-8,2],[-4,-3],[-4,0],[1,-9],[2,-4],[6,-6],[8,0],[5,6],[0,8],[-6,7]]),col,1.7*q)
			path(pts.call([[-2,6],[0,1],[3,5]]),col,1.35*q)
		"bridge":
			for i in 5: l.call(-6+i*3,-6,-6+i*3,5)
			l.call(-9,-4,9,-4);l.call(-9,3,9,3);l.call(-7,4,-7,8);l.call(7,4,7,8)
		"shelter":
			path(pts.call([[-9,6],[0,-8],[9,6],[-9,6]]),col,1.7*q)
			l.call(0,-8,2,6);l.call(-7,7,-9,9);l.call(7,7,9,9)
		"trap":
			path(pts.call([[-8,6],[-4,-5],[4,-5],[8,6],[-8,6]]),col,1.6*q)
			l.call(-6,1,6,1);l.call(-2,-5,-3,6);l.call(2,-5,3,6);l.call(6,6,7,-9);l.call(7,-9,11,-7)
		"skiff":
			path(pts.call([[-9,4],[9,4],[5,8],[-5,8],[-9,4]]),col,1.5*q)
			l.call(-2,3,-2,-9);path(pts.call([[-1,-9],[7,1],[-1,1],[-1,-9]]),col,1.5*q)
		"floor":
			path(pts.call([[-9,-2],[0,-7],[9,-2],[0,3],[-9,-2],[-9,3],[0,8],[9,3],[9,-2]]),col,1.4*q)
			l.call(-5,-4,4,1);l.call(-1,-6,7,-1);l.call(0,3,0,8)
		"wall","door":
			path(pts.call([[-9,8],[-9,-7],[9,-7],[9,8]]),col,1.5*q)
			for x in [-6,-3,0,3,6]:
				l.call(x,-5,x,-2 if k=="door" and abs(x)<=3 else 7)
			if k=="door":path(pts.call([[-4,8],[-4,-2],[4,-2],[4,8]]),col,1.55*q)
		"roof":
			path(pts.call([[-9,1],[0,-8],[9,1],[6,1],[0,-5],[-6,1],[-9,1]]),col,1.5*q)
			l.call(-7,1,-7,8);l.call(7,1,7,8);l.call(-7,8,7,8)
		"heart": path(pts.call([[0,7],[-8,0],[-8,-4],[-5,-7],[-2,-7],[0,-4],[3,-7],[6,-7],[9,-4],[9,0],[0,7]]),col,1.65*q)
		"bell":
			path(pts.call([[-8,4],[-5,0],[-4,-5],[0,-7],[4,-5],[5,0],[8,4],[-8,4]]),col,1.6*q)
			draw_circle(pp.call(0,6),1.7*q,col)
		"wave":
			for y in [-3,3]:
				var a=[]
				for i in 17: a.append(pp.call(i-8,y+sin(i*.58)*1.65))
				path(a,col,1.6*q)
		"lamp":
			path(pts.call([[-6,8],[-4,-1],[4,-1],[6,8],[-6,8]]),col,1.55*q)
			path(pts.call([[-5,-2],[-5,-6],[0,-9],[5,-6],[5,-2],[-5,-2]]),col,1.55*q)
			l.call(-7,9,7,9);l.call(-2,2,3,2)
		"lens":
			draw_arc(p,6.4*q,0,TAU,24,col,1.75*q,true)
			draw_arc(p,3.8*q,0,TAU,20,col,1.25*q,true)
			l.call(5,5,9,9)
		"copper":
			path(pts.call([[-8,5],[-7,-2],[-1,-8],[6,-7],[9,-2],[4,5],[-3,8],[-8,5]]),col,1.6*q)
			l.call(-6,4,5,-6);l.call(-2,6,7,-3)
		"dynamo":
			path(pts.call([[-7,-5],[6,-5],[6,6],[-7,6],[-7,-5]]),col,1.6*q)
			l.call(-10,-2,-7,-2);l.call(6,0,10,0);path(pts.call([[1,-4],[-2,0],[2,0],[-1,5]]),col,1.4*q)
		"map": path(pts.call([[-9,-6],[-3,-3],[3,-7],[9,-5],[9,7],[3,5],[-3,9],[-9,6],[-9,-6]]),col,1.5*q);l.call(-3,-3,-3,8);l.call(3,-7,3,5)
		"hammer":
			l.call(-6,8,4,-4);path(pts.call([[-1,-7],[3,-9],[9,-4],[6,0],[2,-4],[-1,-7]]),col,1.7*q)
		"sun":
			draw_circle(p,3.4*q,col)
			for i in 8:
				var a=Vector2.from_angle(TAU*i/8);line(p+a*5.4*q,p+a*8.6*q,col,1.3*q)
		"moon": draw_arc(p,7*q,-1.55,1.70*PI,22,col,1.7*q,true);draw_arc(pp.call(3,-2),6*q,.48*PI,1.43*PI,14,col,1.5*q,true)
		"check": path(pts.call([[-6,0],[-2,4],[7,-5]]),col,2*q)
		"arrow": l.call(-7,0,7,0);path(pts.call([[2,-5],[7,0],[2,5]]),col,1.5*q)

func register(id:String,r:Rect2)->bool:
	var idx=buttons.size()
	buttons.append([id,r])
	var over=r.has_point(mpos)
	if over: hand=true
	return over if pointer_mode else idx==focus_index
func button(id:String,label:String,r:Rect2,primary:bool=false):
	var hot=register(id,r)
	var bg=(PAPER if hot else GOLD) if primary else (Color("#38564f") if hot else Color(.07,.17,.19,.88))
	panel(r,bg,Color(0,0,0,0) if primary else WASH)
	txt(label,r.position.x+18,r.position.y+r.size.y*.65,20,INK if primary else PAPER,bold if primary else sans)
	icon("arrow",r.end-Vector2(24,r.size.y*.49),16,INK if primary else MINT)
func click_at(point:Vector2):
	for b in buttons:
		if b[1].has_point(point/ui_scale):
			game.command(b[0]);return
func click_hud(point:Vector2)->bool:
	for b in buttons:
		if b[1].has_point(point/ui_scale): game.command(b[0]); return true
	return false
func key_nav(k:int):
	if buttons.is_empty(): return
	if k in [KEY_UP,KEY_LEFT]: pointer_mode=false;focus_index=posmod(focus_index-1,buttons.size())
	elif k in [KEY_DOWN,KEY_RIGHT,KEY_TAB]: pointer_mode=false;focus_index=posmod(focus_index+1,buttons.size())
	elif k in [KEY_ENTER,KEY_SPACE,KEY_KP_ENTER]: game.command(buttons[clampi(focus_index,0,buttons.size()-1)][0])

func _draw():
	if not game: return
	ui_scale=minf(size.x/1440.,size.y/810.)
	if ui_scale<=0: return
	v=size/ui_scale
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*ui_scale)
	mpos=get_local_mouse_position()/ui_scale
	buttons.clear();hand=false
	if last_state!=game.state: focus_index=0;last_state=game.state
	match game.state:
		"menu": title_screen()
		"confirm_new":
			title_screen(false)
			modal_shade()
			var r=middle(515,248)
			panel(r);eyebrow("JOURNAL DE BORD",r.position+Vector2(30,36))
			txt("Recommencer le quart ?",r.position.x+30,r.position.y+83,33,PAPER,serif)
			txt("Une nouvelle traversée remplacera ta sauvegarde.",r.position.x+30,r.position.y+123,18,MUTED)
			button("confirm","Recommencer",Rect2(r.position+Vector2(30,164),Vector2(230,49)),true)
			button("back","Retour",Rect2(r.position+Vector2(275,164),Vector2(205,49)))
		"play": if not game.ui_hidden: play_hud()
		"pause": pause_panel()
		"help": help_panel()
		"map": atlas()
		"craft": workshop()
		"salvage": salvage_panel()
		"letter": letter_panel()
		"remove": remove_panel()
		"dead","won": end_panel()
		"cinema": cinema()
	if not game.save_status and game.state=="play": center("Sauvegarde indisponible",v.x/2,26,14,GOLD,mono)
	if game.hit_flash>0 and game.state=="play":
		draw_rect(Rect2(Vector2.ZERO,v),Color(.56,.15,.10,game.hit_flash*.21))
	if game.dawn_fade>0 and game.state=="play":
		draw_rect(Rect2(Vector2.ZERO,v),Color(.94,.86,.69,game.dawn_fade*.69))
	var cursor=Input.CURSOR_POINTING_HAND if hand else Input.CURSOR_ARROW
	if Input.get_current_cursor_shape()!=cursor: Input.set_default_cursor_shape(cursor)

func eyebrow(s:String,p:Vector2,col:Color=GOLD):
	txt(s,p.x,p.y,14,col,mono)
func middle(w:float,h:float)->Rect2: return Rect2((v-Vector2(w,h))*.5,Vector2(w,h))
func modal_shade():
	draw_rect(Rect2(Vector2.ZERO,v),Color(.016,.047,.063,.70))
func title_screen(interactive:bool=true):
	draw_texture_rect(side_shade,Rect2(0,0,v.x*.76,v.y),false)
	draw_texture_rect(shade,Rect2(0,v.y-104,v.x,104),false,Color(1,1,1,.58))
	var x=66.
	var y=v.y*.35
	line(Vector2(x,62),Vector2(x+40,62),GOLD,2)
	eyebrow("ARCHIVES DES VEILLEURS   /   N° 01",Vector2(x+52,67))
	txt("NIN SURVIE",x-5,y+48,75,PAPER,serif)
	line(Vector2(x+4,y+116),Vector2(x+386,y+116),WASH)
	ptext("La mer efface les chemins. Trois pièces manquent à la lanterne de Keravel. À toi de reprendre le quart.",Vector2(x+4,y+153),389,21,PAPER,sans,1.38)
	var by=y+239
	if interactive:
		if game.active_save:
			button("resume","Reprendre le quart",Rect2(x+4,by,324,51),true)
			button("new","Nouvelle traversée",Rect2(x+4,by+61,324,44))
			button("help","Carnet du veilleur",Rect2(x+4,by+113,324,42))
		else:
			button("new","Prendre le quart",Rect2(x+4,by,324,53),true)
			button("help","Carnet du veilleur",Rect2(x+4,by+65,324,46))
	if interactive:
		var sr=Rect2(v.x-179,35,141,34)
		var hot=register("sound",sr)
		panel(sr,Color(.04,.11,.13,.78),GOLD if hot else WASH)
		center("SON  "+("ACTIVÉ" if game.audio.enabled else "COUPÉ"),sr.get_center().x,sr.position.y+22,14,PAPER,mono)
		var qr=Rect2(v.x-291,35,102,34)
		var ho=register("quit",qr)
		panel(qr,Color(.04,.11,.13,.78),GOLD if ho else WASH)
		center("QUITTER",qr.get_center().x,qr.position.y+22,14,PAPER,mono)
	eyebrow("ARCHIPEL DE KERAVEL  /  BRETAGNE",Vector2(x,v.y-35),MUTED)
	right("SURVIE  •  EXPLORATION  •  CONSTRUCTION",v.x-39,v.y-35,14,PAPER,mono)
	var cx=v.x-84.;var cy=v.y-114.
	draw_arc(Vector2(cx,cy),29,0,TAU,48,Color(.93,.90,.76,.45),1,true)
	poly([Vector2(cx,cy-22),Vector2(cx+4,cy+1),Vector2(cx,cy+16),Vector2(cx-4,cy)],GOLD)
	center("N",cx,cy-34,13,PAPER,mono)

func bar(p:Vector2,w:float,amount:float,col:Color):
	draw_rect(Rect2(p,Vector2(w,4)),Color(.7,.8,.75,.18))
	draw_rect(Rect2(p,Vector2(w*clampf(amount/100,0,1),4)),col)
func stat(k:String,name:String,val:float,p:Vector2,col:Color):
	icon(k,p+Vector2(9,10),15,col)
	txt(name,p.x+22,p.y+11,14,MUTED)
	right(str(ceili(val)),p.x+113,p.y+11,14,PAPER,mono)
	bar(p+Vector2(22,18),91,val,col)
func compass():
	var cx=v.x*.5
	var ww=312.
	var r=Rect2(cx-ww*.5,18,ww,43)
	draw_rect(r,Color(.035,.09,.11,.62))
	var dir_deg=fposmod(-rad_to_deg(game.yaw),360.)
	var labels=["N","NE","E","SE","S","SO","O","NO"]
	for i in range(-48,97):
		var value=i*7.5; var diff=wrapf(value-dir_deg,-180,180)
		if value<0 or value>=360 or abs(diff)>55: continue
		var x=cx+diff*2.7
		if i%6==0: center(labels[posmod(i/6,8)],x,42,16,PAPER,bold)
		else: line(Vector2(x,28),Vector2(x,32 if i%3 else 36),MUTED,1)
	poly([Vector2(cx-4,52),Vector2(cx+4,52),Vector2(cx,47)],GOLD)
	var target=game.selected_site
	if target>=0 and target<=3:
		var point=W.LIGHT if target==3 else game.world.spots[target]
		var delta=point-game.xy
		var d=wrapf(rad_to_deg(atan2(delta.x,-delta.y))-dir_deg,-180,180)
		if abs(d)<=54: draw_circle(Vector2(cx+d*2.7,53),3.4,GOLD)
func caption(s:String,p:Vector2,fs:int=19,col:Color=PAPER,f:Font=null):
	var font=f if f else sans
	draw_string_outline(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,5,Color(.035,.075,.08,.85))
	txt(s,p.x,p.y,fs,col,font)

func play_hud():
	var x=34.;var base=v.y-42.
	var c=Vector2(x+41,base-44)
	# Brass tide watch, cream dial and a moving hand.
	draw_circle(c,40,Color("#3a352b"));draw_circle(c,37,Color("#b18c52"));draw_circle(c,33,Color("#ead8af"))
	for i in 11:
		var d=Vector2.from_angle(lerpf(2.45,6.98,i/10.))
		line(c+d*26,c+d*30,INK,1.6)
	var handv=Vector2.from_angle(lerpf(2.45,6.98,clampf((game.water+.84)/2.96,0,1)))
	line(c,c+handv*25,BRICK,3);draw_circle(c,3,INK)
	center("MER",c.x,c.y+21,10,INK,bold)
	caption("Jour %d · %s"%[game.day_number(),game.clock_readout()],Vector2(x,base+14),15,PAPER)
	for i in 3:
		var amount=[game.hp,game.warmth,game.hunger][i]
		var col=[Color("#e58770"),GOLD,MINT][i]
		var p=Vector2(x+107,base-70+i*23)
		caption(["Vie","Chaleur","Faim"][i],p,15,PAPER,bold)
		line(p+Vector2(60,-5),p+Vector2(147,-5),Color("#304147"),5)
		line(p+Vector2(60,-5),p+Vector2(60+.87*clampf(amount,0,100),-5),col,4)
	if game.stamina<94: caption("Souffle  %d"%ceili(game.stamina),Vector2(x+106,base+5),16,MINT)
	var prompt=""
	if game.camp.kind!="":
		prompt=C.NAMES[game.camp.kind]+"   ·   "+(game.camp.reason if game.camp.reason!="" else "E poser   R tourner   Échap ranger")
	elif not game.nearest.is_empty():prompt="[ E ]   "+game.nearest.label
	if prompt!="":
		var w=sans.get_string_size(prompt,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
		caption(prompt,Vector2((v.x-w)/2,base-14),20)
	var msg=game.toast if game.toast_time>0 else ""
	if msg=="" and game.marsh.alert!="":msg=game.marsh.alert
	if msg=="" and game.region_t>0:msg=game.last_region
	if msg!="":
		var w=serif.get_string_size(msg,HORIZONTAL_ALIGNMENT_LEFT,-1,23).x
		caption(msg,Vector2((v.x-w)/2,58),23,PAPER,serif)
	var note=""
	if game.signal_active:note="Appel du canot · Espace" if game.age>=game.next_signal else "Prochain appel dans %d s"%ceili(game.next_signal-game.age)
	elif game.marsh.extent(game.xy)<1.35:
		note=game.marsh.hint()
		if game.marsh.stage==2:note="Roi des Vannes   "+str(game.marsh.boss_hp)+"/5  ·  "+note
	elif game.selected_site>=0:
		var i=game.selected_site
		var to=(W.LIGHT if i==3 else game.world.spots[i])-game.xy
		var dirs=["N","NE","E","SE","S","SO","O","NO"]
		note=("Keravel" if i==3 else W.TITLES[i])+"   "+dirs[posmod(roundi(atan2(to.x,-to.y)/(PI/4)),8)]+"   %d m"%roundi(to.length())
	elif game.age<40:note="Du bois, du silex, puis un feu.   B pour construire."
	if note!="":caption(note,Vector2(35,99),18,GOLD,bold)
	var action="B  Construire" if game.sailing.is_empty() else "E  Débarquer"
	caption(action+"     M  Carte",Vector2(v.x-242,base),17,PAPER,bold)
	if game.sailing.is_empty():register("craft",Rect2(v.x-248,base-22,125,29))
	register("map",Rect2(v.x-117,base-22,100,29))
	if game.cool>0:caption("Cloche   %.0f s"%ceil(game.cool),Vector2(v.x-240,base-30),16,GOLD)
	var bag="Bois %d   ·   Silex %d   ·   Rations %d"%[game.bag.wood,game.bag.stone,game.bag.food]
	caption(bag,Vector2(v.x-297,base+24),15,PAPER)

func page_heading(r:Rect2,kicker:String,title:String,sub:String):
	eyebrow(kicker,r.position+Vector2(34,34))
	txt(title,r.position.x+32,r.position.y+86,44,PAPER,serif)
	if sub!="": txt(sub,r.position.x+34,r.position.y+119,18,MUTED)
	var back=Rect2(r.end.x-96,r.position.y+23,66,30)
	var hot=register("back",back)
	panel(back,Color(.5,.6,.53,.12),GOLD if hot else WASH)
	center("ÉCHAP",back.get_center().x,back.position.y+20,14,PAPER,mono)

func pause_panel():
	modal_shade()
	var r=middle(510,536)
	panel(r)
	eyebrow("QUART INTERROMPU",r.position+Vector2(34,38))
	txt("À l’abri du temps",r.position.x+32,r.position.y+91,38,PAPER,serif)
	txt("Jour %02d • %s • %s"%[game.day_number(),game.clock_readout(),game.last_region],r.position.x+34,r.position.y+129,17,MUTED)
	var x=r.position.x+34;var y=r.position.y+157;var w=r.size.x-68
	button("back","Reprendre la traversée",Rect2(x,y,w,48),true)
	button("help","Carnet des commandes",Rect2(x,y+59,w,44))
	button("music","Musique   "+("activée" if game.audio.music_on else "coupée"),Rect2(x,y+111,w,44))
	button("sound","Son   "+("activé" if game.audio.enabled else "coupé"),Rect2(x,y+163,w,44))
	button("full","Changer le plein écran",Rect2(x,y+215,w,44))
	button("menu","Retour au titre",Rect2(x,y+267,w,44))
	eyebrow("JOURNAL ENREGISTRÉ" if game.save_status else "ÉCHEC DE SAUVEGARDE",Vector2(x,y+347),MINT)

func help_panel():
	modal_shade()
	var r=middle(1000,652);panel(r)
	page_heading(r,"CARNET DU VEILLEUR   /   TERRAIN","Prendre ses marques","Les touches physiques conviennent aux claviers AZERTY et QWERTY.")
	var x=r.position.x+36;var y=r.position.y+159
	var controls=[["ZQSD / WASD","Se déplacer"],["FLÈCHES","Se déplacer également"],["MAJ","Courir"],["CLIC DROIT","Maintenir et déplacer la caméra"],["J  /  L","Pivoter la caméra au clavier"],["MOLETTE","Ajuster la distance"],["C","Recentrer derrière le personnage"],["E","Ramasser, parler au phare, utiliser"],["ESPACE","Sonner la cloche et repousser"]]
	var controls2=[["B","Ouvrir la construction"],["1  À  9","Choisir directement un plan"],["CLIC / E","Poser le plan à portée"],["R","Manger ou tourner le plan"],["M / TAB","Ouvrir la carte et le journal"],["ÉCHAP","Ranger le plan, fermer ou pause"],["F2","Masquer l’interface pour filmer"],["F11","Basculer en plein écran"],["X","Démonter et récupérer les matériaux"]]
	for col in 2:
		var rows=controls if col==0 else controls2
		var xx=x+col*480
		for i in rows.size():
			var yy=y+i*39
			keycap(rows[i][0],Vector2(xx,yy),112,26)
			txt(rows[i][1],xx+126,yy+20,17,PAPER)
	line(Vector2(x,r.end.y-104),Vector2(r.end.x-34,r.end.y-104))
	ptext("Les hauts-fonds se découvrent à marée basse. Pose un casier sur le sable humide, garde une ration pour dormir et cherche la chaleur du feu quand le grain se lève.",Vector2(x,r.end.y-72),r.size.x-72,19,MINT)

func workshop():
	modal_shade()
	var r=middle(1270,598);panel(r)
	page_heading(r,"CARNET DE CONSTRUCTION   /   PLANS DE TERRAIN","Le chantier","Choisis un plan, déplace-toi, puis pose-le avec E ou un clic.")
	var x=r.position.x+32;var y=r.position.y+202
	for tab in 2:
		var b=Rect2(x+tab*213,y-57,204,35)
		var hot_tab=register("plans_"+str(tab),b)
		panel(b,Color("#3a5752") if tab==craft_tab or hot_tab else Color("#203b42"),GOLD if tab==craft_tab else WASH)
		center(["Camp & navigation","Cabane modulaire"][tab],b.get_center().x,b.position.y+23,17,PAPER,bold)
	var visible_indices=[0,1,2,3,4] if craft_tab==0 else [5,6,7,8]
	for slot in visible_indices.size():
		var i=visible_indices[slot]
		var k=C.KINDS[i];var cw=230. if craft_tab==0 else 291.
		var rr=Rect2(x+slot*(cw+13),y,cw,289)
		var hot=register("make_"+k,rr)
		panel(rr,Color("#27434a") if hot else Color("#1a353d"),GOLD if hot else WASH)
		keycap(str(i+1),rr.position+Vector2(13,13),26,24)
		icon(k,rr.position+Vector2(cw*.5,71),63,GOLD)
		center(C.NAMES[k],rr.get_center().x,rr.position.y+137,24,PAPER,serif)
		ptext(C.DESCRIPTIONS[k],rr.position+Vector2(15,172),cw-29,16,MUTED)
		line(rr.position+Vector2(14,235),rr.position+Vector2(cw-14,235))
		icon("wood",rr.position+Vector2(30,261),19,GOLD)
		txt(str(C.COST[k][0]),rr.position.x+47,rr.position.y+268,18,PAPER,mono)
		if C.COST[k][1]>0:
			icon("stone",rr.position+Vector2(88,261),19,MINT);txt(str(C.COST[k][1]),rr.position.x+105,rr.position.y+268,18,PAPER,mono)
		var enough=game.bag.wood>=C.COST[k][0] and game.bag.stone>=C.COST[k][1]
		right("PRÊT" if enough else "MANQUE",rr.end.x-13,rr.position.y+267,13,MINT if enough else BRICK,mono)
	var yy=r.end.y-58
	eyebrow("DANS LE SAC",Vector2(x,yy+7))
	icon("wood",Vector2(x+158,yy),24,GOLD);txt("%d bois"%game.bag.wood,x+179,yy+7,20,PAPER)
	icon("stone",Vector2(x+306,yy),24,MINT);txt("%d silex"%game.bag.stone,x+327,yy+7,20,PAPER)
	right("R   Pivoter      X   Démonter      ÉCHAP   Ranger",r.end.x-30,yy+7,16,MUTED,mono)

func map_point(p:Vector2,r:Rect2)->Vector2:
	return r.position+(p-W.ORIGIN)/Vector2(240,200)*r.size

func atlas():
	modal_shade()
	var r=middle(1220,720);panel(r,Color("#112c34"))
	page_heading(r,"SERVICE DES FEUX   /   CARTE HYDROGRAPHIQUE","L’archipel de Keravel","Repère les passes, choisis une destination et garde un œil sur la marée.")
	var mapr=Rect2(r.position+Vector2(33,151),Vector2(653,525))
	map_rect=mapr
	draw_texture_rect(game.world.map_tex,mapr,false)
	for i in range(1,12):
		var vx=mapr.position.x+mapr.size.x*i/12
		line(Vector2(vx,mapr.position.y),Vector2(vx,mapr.end.y),Color(.91,.88,.69,.12))
	for i in range(1,10):
		var vy=mapr.position.y+mapr.size.y*i/10
		line(Vector2(mapr.position.x,vy),Vector2(mapr.end.x,vy),Color(.91,.88,.69,.12))
	for pair in W.PATHS:
		var a=map_point(pair[0],mapr);var b=map_point(pair[1],mapr)
		draw_dashed_line(a,b,Color(.22,.30,.28,.39),1.6,5.,true,true)
	for it in game.camp.items:
		var p=map_point(it.at,mapr)
		draw_rect(Rect2(p-Vector2.ONE*2,Vector2.ONE*4),INK)
	for i in 3:
		var p=map_point(game.world.shore.relics[i],mapr)
		var corners=[p+Vector2(0,-8),p+Vector2(8,0),p+Vector2(0,8),p+Vector2(-8,0)]
		poly(corners,INK)
		center("✓" if game.stamps[i] else "?",p.x,p.y+4,12,GOLD,bold)
	var note_positions=[[Vector2(-88,-62),"BASSE DES DENTS"],[Vector2(43,69),"MER D’IROISE"],[Vector2(60,-58),"CHENAL DU NORD"]]
	for n in note_positions:
		var p=map_point(n[0],mapr)
		center(n[1],p.x,p.y,11,Color("#b4ccc0"),mono)
	var pts=game.world.spots.duplicate();pts.append(W.LIGHT)
	var syms=["lens","copper","dynamo","lamp"]
	for i in 4:
		var p=map_point(pts[i],mapr)
		var tracked=game.selected_site==i
		var done=game.rescued if i==3 else game.pieces[i]
		draw_circle(p,16,INK)
		draw_arc(p,16,0,TAU,28,GOLD if tracked else Color("#bfd1b7"),1.4,true)
		icon("check" if done else syms[i],p,18,GOLD if tracked else PAPER)
		var badge=Rect2(p-Vector2.ONE*21,Vector2.ONE*42)
		register("track_"+str(i),badge)
	var saline=map_point(game.marsh.BOARD,mapr)
	draw_circle(saline,8,BRICK)
	center("TROIS-VANNES",saline.x,saline.y+23,13,INK,bold)
	for j in 3:
		var gate_point=map_point(game.marsh.GATES[j],mapr)
		draw_circle(gate_point,3.5,MINT if game.marsh.gates[j] else BRICK)
	var you=map_point(game.xy,mapr)
	draw_circle(you,8.5,PAPER);draw_circle(you,5.7,Color("#c6674e"))
	draw_arc(you,12,0,TAU,26,Color("#f6dac0"),1,true)
	var north=mapr.position+Vector2(38,51)
	poly([north+Vector2(0,-17),north+Vector2(5,4),north,north+Vector2(-5,4)],PAPER)
	center("N",north.x,north.y-22,14,PAPER,mono)
	panel(Rect2(mapr.position+Vector2(10,mapr.size.y-38),Vector2(494,28)),Color(.06,.15,.17,.81),Color.TRANSPARENT)
	txt("●  Ta position    ┄  Passes    ◇  Boîtes des veilleurs  %d/3"%game.stamps.count(true),mapr.position.x+21,mapr.end.y-18,14,PAPER,mono)
	draw_rect(mapr,WASH,false)
	var x=r.position.x+714;var y=r.position.y+172
	eyebrow("JOURNAL DE RELÈVE",Vector2(x,y))
	txt("La lampe de Keravel",x,y+39,30,PAPER,serif)
	txt("Pièces %d / 3     •     %s"%[game.pieces.count(true),"Braise prête" if game.has_ember else "Braise manquante"],x,y+71,17,MINT)
	var names=W.TITLES.duplicate();names.append("Phare de Keravel")
	var info=["Lentille dans la cale • accès libre","Réflecteur sous le treuil • 4 silex","Dynamo de l’atelier • 4 bois","Allumage • 3 pièces et une braise"]
	for i in 4:
		var yy=y+92+i*75
		var rr=Rect2(x,yy,468,63)
		var hot=register("track_"+str(i),rr)
		var tracked=game.selected_site==i
		panel(rr,Color("#304e4c") if hot or tracked else Color("#1a373e"),GOLD if tracked else WASH)
		icon(syms[i],rr.position+Vector2(25,32),24,GOLD)
		txt(names[i],x+54,yy+25,20,PAPER,bold)
		txt(info[i],x+54,yy+48,16,MUTED)
		if (i<3 and game.pieces[i]) or (i==3 and game.rescued): icon("check",rr.end-Vector2(23,31),20,MINT)
		else: right("%d m"%roundi(game.xy.distance_to(pts[i])),rr.end.x-14,yy+25,14,GOLD if tracked else MUTED,mono)
	var by=y+414
	icon("wave",Vector2(x+10,by),22,MINT);txt(game.tide_label(),x+33,by+6,17,MINT,bold)
	var sec=ceili((CYCLE_HALF() if game.tide_rising() else WAVE_FULL())-fposmod(game.age,WAVE_FULL()))
	if sec<0: sec+=int(WAVE_FULL())
	txt("Prochaine %s dans %d s"%["pleine mer" if game.tide_rising() else "basse mer",sec],x,by+39,17,PAPER)
	txt("Clique sur un site pour le suivre à la boussole.",x,by+70,15,MUTED,mono)

func WAVE_FULL()->float: return game.TIDE_CYCLE
func CYCLE_HALF()->float: return game.TIDE_CYCLE*.5

func end_panel():
	modal_shade()
	var win=game.state=="won"
	var r=middle(644,446);panel(r)
	var x=r.position.x+38;var y=r.position.y+42
	eyebrow("TRANSCRIPTION RADIO   /   CANAL 16" if win else "JOURNAL DE BORD   /   QUART PERDU",Vector2(x,y))
	icon("lamp" if win else "wave",Vector2(r.end.x-65,y+19),42,GOLD)
	txt("Le large te répond." if win else "La mer reprend son dû.",x,y+73,44,PAPER,serif)
	var message="« Keravel, ici le canot de relève. On voit ton feu. On rentre à la maison. »" if win else "Tu as perdu connaissance. Le dernier abri te rendra une partie de tes forces. Les constructions et les pièces du phare sont conservées."
	ptext(message,Vector2(x,y+122),r.size.x-83,22,MUTED)
	line(Vector2(x,y+200),Vector2(r.end.x-38,y+200))
	txt("JOUR %02d     %d CONSTRUCTIONS     %d / 3 PIÈCES"%[game.day_number(),game.total_built,game.pieces.count(true)],x,y+236,16,GOLD,mono)
	button("free" if win else "respawn","Continuer sur l’archipel" if win else "Repartir du camp",Rect2(x,y+269,r.size.x-76,50),true)
	button("menu","Retour au titre",Rect2(x,y+332,r.size.x-76,44))

func cinema():
	draw_rect(Rect2(0,0,v.x,77),DEEP);draw_rect(Rect2(0,v.y-90,v.x,90),DEEP)
	center("KERAVEL   /   LE FEU EST RALLUMÉ",v.x*.5,47,18,GOLD,mono)
	center("« Ici le canot de relève… on voit ton feu. »",v.x*.5,v.y-38,26,PAPER,serif)
	right("ESPACE  Passer",v.x-24,v.y-23,13,MUTED,mono)

func salvage_panel():
	modal_shade()
	var s=game.salvage
	var r=middle(926,559)
	panel(r,Color("#132f37"))
	var x=r.position.x+34
	var y=r.position.y+151
	page_heading(r,"OPÉRATION DE SAUVETAGE   /   0%d"%(s.site+1),s.TITLES[s.site],s.LOG[s.site])
	ptext(s.INTRO[s.site],Vector2(x,y+14),r.size.x-68,20,MUTED)
	var rr=Rect2(x,y+77,r.size.x-68,193)
	panel(rr,Color("#1a3941"))
	match s.site:
		0:
			eyebrow("TENSION DU CÂBLE",rr.position+Vector2(25,31))
			right("%d  /  3   CLIQUETS"%s.steps,rr.end.x-25,rr.position.y+31,16,GOLD,mono)
			var a=rr.position+Vector2(46,82);var w=rr.size.x-92
			line(a,a+Vector2(w,0),WASH,4)
			for i in 41:
				var q=a+Vector2(w*i/40.,0)
				line(q+Vector2(0,-7 if i%5 else -14),q+Vector2(0,8),MUTED)
			var target=a+Vector2(w*s.sweet(),0)
			var delta=w*s.tolerance()
			draw_rect(Rect2(target.x-delta,target.y-17,delta*2,34),Color(GOLD,.50))
			line(target-Vector2(0,20),target+Vector2(0,19),GOLD,2)
			var pin=a+Vector2(w*s.position(),0)
			line(pin-Vector2(0,23),pin+Vector2(0,21),PAPER,4)
			poly([pin+Vector2(-6,-28),pin+Vector2(6,-28),pin+Vector2(0,-21)],PAPER)
			button("salvage_0","Bloquer le treuil   •   E",Rect2(rr.get_center().x-142,rr.end.y-62,284,42),true)
		1:
			var tones=["GRAVE","MÉDIUM","AIGU"]
			for i in 3:
				var box=Rect2(rr.position+Vector2(24+i*272,21),Vector2(256,114))
				var hot=register("salvage_"+str(i),box)
				var flash=s.flash==i and s.flash_t>0
				panel(box,GOLD if flash else (Color("#38534f") if hot else Color("#21434a")),GOLD if hot or flash else WASH)
				icon("bell",box.get_center()+Vector2(0,-12),40,INK if flash else [MINT,GOLD,BRICK][i])
				center("%d   %s"%[i+1,tones[i]],box.get_center().x,box.end.y-17,17,INK if flash else PAPER,mono)
			txt("RÉPONSE   "+("● ".repeat(s.played))+("○ ".repeat(3-s.played)),rr.position.x+27,rr.end.y-19,17,MINT,mono)
			var replay=Rect2(rr.end.x-182,rr.end.y-42,155,29)
			var hot=register("replay",replay)
			panel(replay,Color("#29474b"),GOLD if hot else WASH)
			center("R   Réécouter",replay.get_center().x,replay.end.y-8,15,PAPER,mono)
		2:
			for i in 3:
				var p=rr.position+Vector2(154+i*273,89)
				var box=Rect2(p-Vector2(100,69),Vector2(200,143))
				var hot=register("salvage_"+str(i),box)
				if i<2: line(p+Vector2(48,0),p+Vector2(218,0),MUTED,3)
				for j in 12:
					var arm=Vector2.from_angle(j*TAU/12.)
					line(p+arm*39,p+arm*48,GOLD if hot else MUTED,7)
				draw_circle(p,41,Color("#2f5559"))
				draw_arc(p,40,0,TAU,42,GOLD if hot else MINT,2,true)
				var target=Vector2.UP.rotated(s.stops[i]*PI*.5)
				poly([p+target*57,p+target*67+target.orthogonal()*5,p+target*67-target.orthogonal()*5],GOLD)
				var shaft=Vector2.UP.rotated(s.gears[i]*PI*.5)
				line(p,p+shaft*32,GOLD if s.gears[i]==s.stops[i] else PAPER,5)
				draw_circle(p,5,GOLD);center("ROUE  %d"%(i+1),p.x,p.y+78,15,PAPER,mono)
	var status=s.message if s.message_t>0 else ["Appuie sur E ou clique pour enclencher le frein.","Touches 1, 2, 3 ou clic sur les cloches.","Touches 1, 2, 3 ou clic sur les roues."][s.site]
	center(status,r.get_center().x,r.end.y-76,20,GOLD if s.solved else PAPER)
	line(Vector2(x,r.end.y-52),Vector2(r.end.x-34,r.end.y-52))
	eyebrow("PIÈCE RECHERCHÉE   /   "+W.PARTS[s.site].to_upper(),Vector2(x,r.end.y-27),MINT)

func letter_panel():
	modal_shade()
	var r=middle(712,448);panel(r,Color("#203c40"))
	var i=game.stamp_page
	var x=r.position.x+39;var y=r.position.y+38
	eyebrow("CORRESPONDANCE DES VEILLEURS   /   PLI 0%d"%(i+1),Vector2(x,y))
	txt(game.Shore.TITLES[i],x,y+61,40,PAPER,serif)
	ptext(game.Shore.TEXTS[i],Vector2(x,y+115),r.size.x-78,24,PAPER,serif,1.37)
	line(Vector2(x,y+223),Vector2(r.end.x-39,y+223))
	txt(game.Shore.GIFTS[i],x,y+264,24,GOLD,bold)
	txt(game.Shore.EFFECTS[i],x,y+295,19,MINT)
	button("back","Refermer le pli",Rect2(x,y+327,r.size.x-78,47),true)

func remove_panel():
	modal_shade()
	var indices=game.camp.nearby()
	var count=mini(indices.size(),8)
	var r=middle(654,191+count*52)
	panel(r)
	page_heading(r,"RÉCUPÉRATION   /   CHANTIER","Démonter une pièce","Choisis une construction à portée pour récupérer ses matériaux.")
	for i in count:
		var idx=indices[i]
		var it=game.camp.items[idx];var box=Rect2(r.position+Vector2(32,149+i*52),Vector2(r.size.x-64,45))
		var hot=register("salvagebuild_"+str(idx),box)
		panel(box,Color("#37554f") if hot else Color("#1c3b43"),GOLD if hot else WASH)
		icon(it.kind,box.position+Vector2(22,23),23,GOLD)
		txt(C.NAMES[it.kind],box.position.x+45,box.position.y+29,21,PAPER)
		right("+%d bois   +%d silex     %.1f m"%[C.COST[it.kind][0],C.COST[it.kind][1],it.at.distance_to(game.xy)],box.end.x-14,box.position.y+28,15,MUTED,mono)
