extends Node3D
const Ink=preload("res://meshwork.gd")
const A=preload("res://art.gd")
const CENTER=Vector2(80,48)
const BOARD=Vector2(62,44)
const GATES=[Vector2(72,40),Vector2(86,57),Vector2(92,40)]
const NAMES=["Crabe des vasières","Anguille de saumure","Héron de suie","Méduse-lanterne","Bélier de sel","Le Roi des Vannes"]
const HOMES=[Vector2(69,45),Vector2(76,39),Vector2(80,59),Vector2(89,53),Vector2(93,42),CENTER]
var g
var stage=0
var gates=[false,false,false]
var defeated=[]
var mobs=[]
var wheels=[]
var alert=""
var boss_hp=5

static func extent(p:Vector2)->float:
	return ((p-CENTER)/Vector2(25,17)).length()

static func terrain(p:Vector2,old:float)->float:
	var e=extent(p)
	if e>1.42:return old
	var banks=maxf(1.-smoothstep(.35,2.,absf(fposmod(p.x-2,10.)-5.)),1.-smoothstep(.4,2.,absf(fposmod(p.y,9.)-4.5)))
	var h=-1.08+banks*3.79+.16*sin(p.x*.36+p.y*.19)
	h=maxf(h,2.72-smoothstep(3.,7.,p.distance_to(CENTER))*2.)
	for anchor in [BOARD,GATES[0],GATES[1],GATES[2]]: h=maxf(h,2.75-smoothstep(1.5,4.,anchor.distance_to(p))*2.)
	return maxf(old,lerpf(h,-6.,smoothstep(.88,1.42,e)))

func setup(game):
	g=game
	var m=Ink.new()
	var rng=RandomNumberGenerator.new()
	rng.seed=804
	for i in 1250:
		var q=CENTER+Vector2(rng.randf_range(-25,25),rng.randf_range(-17,17))
		if extent(q)>.99 or q.distance_to(CENTER)<4:continue
		var p=g.world.pos(q)
		if i%6==0:
			for j in 3:
				var b=p+Vector3(.12*j,0,.11*sin(j))
				m.rod(b,b+Vector3(.12,.42+j*.16,.04),.05,.016,Color("#856842"),4)
				m.blob(b+Vector3(.10,.40+j*.16,.04),Vector3(.08,.16,.08),Color("#9a5947"),j,5)
		elif i%3==0:
			m.blob(p,Vector3(.36,.17,.25),Color("#e1d5bd"),i,5)
		else:
			for j in 3:
				var a=j*2.1+i
				m.rod(p,p+Vector3(.18*cos(a),.22+.08*j,.18*sin(a)),.07,.045,Color("#a56874") if i%2 else Color("#788453"),5)
	var board=g.world.pos(BOARD)
	m.column(board,2.1,.14,.11,A.WOOD)
	m.box(board+Vector3.UP*1.7,Vector3(1.85,.85,.19),A.LWOOD)
	m.box(board+Vector3(0,1.7,.11),Vector3(1.28,.55,.04),A.CREAM)
	for q in GATES:
		var p=g.world.pos(q)
		for x in [-1,1]:m.box(p+Vector3(x,.9,0),Vector3(.35,2.5,.47),A.WOOD)
		m.box(p+Vector3.UP*1.95,Vector3(2.5,.32,.5),A.LWOOD)
		m.box(p+Vector3.UP*.45,Vector3(1.74,1.25,.22),Color("#4c7977"))
		var wheel=Ink.new()
		for j in 8:
			var a=Vector3(cos(TAU*j/8),sin(TAU*j/8),0)*.54
			var b=Vector3(cos(TAU*(j+1)/8),sin(TAU*(j+1)/8),0)*.54
			wheel.rod(a,b,.075,.075,A.RED,5)
			if j%2==0:wheel.rod(Vector3.ZERO,a,.045,.045,A.RED,4)
		var n=wheel.node(g.world.mat);n.position=p+Vector3(0,1.32,.35);add_child(n);wheels.append(n)
	add_child(m.node(g.world.mat))
	for i in 6:
		var n=model(i)
		add_child(n)
		mobs.append({"node":n,"at":HOMES[i],"hp":2,"wait":1.,"wind":0.,"rest":0.,"aim":Vector2.ZERO})
	reset({})

func model(i:int)->Node3D:
	var m=Ink.new()
	var cs=[Color("#aa5144"),Color("#537b7b"),Color("#353e4c"),Color("#8cbcac"),Color("#aba19d"),Color("#645760")]
	var c=cs[i]
	if i in [0,5]:
		var s=2.65 if i==5 else 1.
		m.blob(Vector3.UP*.46*s,Vector3(.80,.48,.67)*s,c,i,9)
		for d in [-1,1]:
			for j in 3:
				var a=Vector3(d*.57,.40,(j-1)*.37)*s
				var b=a+Vector3(d*.47,.17,.12)*s
				m.rod(a,b,.093*s,.07*s,c);m.rod(b,b+Vector3(d*.23,-.52,.14)*s,.08*s,.024*s,c)
			m.blob(Vector3(d*.91,.61,-.70)*s,Vector3(.32,.23,.48)*s,A.RED,i)
		if i==5:
			for j in 5:m.column(Vector3((j-2)*.44,2.05,-.12),.88-abs(j-2)*.12,.31,.04,A.GOLD,5)
	elif i==1:
		for j in 8:m.blob(Vector3(sin(j*.72)*.35,.28,j*.26-.7),Vector3(.30-j*.021,.26-j*.018,.38),c,j)
	elif i==2:
		for d in [-1,1]:m.rod(Vector3(d*.15,0,.1),Vector3(d*.17,1.15,.05),.045,.06,A.LWOOD)
		m.blob(Vector3(0,1.25,.16),Vector3(.36,.42,.66),c,2)
		m.rod(Vector3(0,1.34,-.24),Vector3(0,2.05,-.46),.16,.12,c)
		m.blob(Vector3(0,2.04,-.48),Vector3(.23,.20,.31),c,4)
		m.rod(Vector3(0,2.02,-.71),Vector3(0,1.96,-1.38),.12,.01,A.GOLD)
	elif i==3:
		m.blob(Vector3.UP*1.25,Vector3(.64,.47,.63),c,3,9)
		for j in 7:
			var a=j*TAU/7
			m.rod(Vector3(cos(a)*.42,1.18,sin(a)*.42),Vector3(cos(a+.4)*.54,.18,sin(a+.4)*.54),.08,.027,A.GOLD)
	else:
		m.blob(Vector3.UP*.84,Vector3(.61,.60,.90),c,4)
		m.blob(Vector3(0,1.1,-.70),Vector3(.4,.41,.43),c.darkened(.3),3)
		for d in [-1,1]:
			m.rod(Vector3(d*.23,1.31,-.72),Vector3(d*.65,1.69,-.50),.17,.06,A.CREAM)
			for z in [-.5,.5]:m.column(Vector3(d*.38,0,z),.72,.11,.14,c)
	return m.node(g.world.mat)

func reset(data):
	stage=int(data.get("stage",0));gates=data.get("gates",[false,false,false]).duplicate();defeated=data.get("dead",[]).duplicate();boss_hp=int(data.get("boss",5))
	for i in 6:
		var m=mobs[i];m.at=HOMES[i];m.hp=2 if i in [0,4] else 1;m.wind=0.;m.rest=0.;m.wait=1.
		m.node.position=g.world.pos(m.at)
		m.node.visible=not defeated.has(float(i)) and not defeated.has(i) and (i<5 or stage==2)
	for i in 3:wheels[i].rotation.z=1.2 if gates[i] else 0.
func pack():return {"stage":stage,"gates":gates,"dead":defeated,"boss":boss_hp}
func target():
	if g.xy.distance_to(BOARD)<3.:return {"kind":"marsh","index":-1,"at":BOARD,"label":"Lire le registre du paludier"}
	for i in 3:
		if g.xy.distance_to(GATES[i])<3.2 and not gates[i]:return {"kind":"marsh","index":i,"at":GATES[i],"label":"Tourner la vanne"}
	return {}
func use(i:int):
	if stage==0 and i<0:
		stage=1;g.notify("Le sel noir • Ouvre les trois vannes rouges du marais.",5)
	elif i<0 or stage==0:g.notify(hint(),4)
	elif stage==1 and not gates[i]:
		gates[i]=true;wheels[i].rotation.z=1.2;g.audio.effect("chantier")
		if gates.count(true)==3:
			stage=2;mobs[5].node.visible=true;g.audio.effect("corne");g.notify("Le Roi des Vannes se lève au centre du marais.",5)
		else:g.notify("Vanne ouverte • %d sur 3"%gates.count(true))
	g.save_run()
func hint()->String:
	return ["Lis le registre à l’entrée ouest du marais.","Vannes ouvertes   %d / 3"%gates.count(true),"Évite la charge, puis sonne près du roi.","Marais libéré • cloche renforcée"][stage]
func tick(dt):
	alert=""
	if extent(g.xy)>1.8:return
	for i in 6:
		var m=mobs[i]
		if not m.node.visible:continue
		var delta=g.xy-m.at
		var dist=delta.length()
		var reach=[2.8,3.5,4.,4.7,5.2,6.4][i]
		m.wait-=dt
		if m.wind>0:
			m.wind-=dt
			if dist<12:alert=NAMES[i]+" prépare son attaque"
			if m.wind<=0:
				if i in [1,2,4,5]:m.at=m.at.move_toward(m.aim,reach)
				if m.at.distance_to(g.xy)<(reach if i==3 else (3.4 if i==5 else 2.35)) and g.age-g.last_hit>1.2:
					g.last_hit=g.age;g.hurt([6,7,9,8,12,18][i])
				m.rest=3.3 if i==5 else 1.6;m.wait=m.rest+1.1
		elif m.rest>0:
			m.rest-=dt
			if i==5 and dist<12:alert="Sa couronne est exposée • Espace"
		elif dist<reach and m.wait<=0:
			m.aim=g.xy;m.wind=1.65 if i==5 else .9
			g.camp.ripple(g.world.pos(m.aim),3.3 if i==5 else 2.,m.wind)
		elif dist<13. and HOMES[i].distance_to(g.xy)<20:
			m.at=m.at.move_toward(g.xy,dt*[1.6,2.8,1.4,.9,1.35,1.65][i])
		else:m.at=m.at.move_toward(HOMES[i],dt)
		var y=maxf(g.world.ground(m.at),g.water-.15)
		m.node.position=Vector3(m.at.x,y+.07*sin(g.visual_time*(4 if i!=3 else 2)+i),m.at.y)
		m.node.rotation.y=atan2(-delta.x,-delta.y)
		m.node.rotation.x=-.22 if m.wind>0 else (.18 if m.rest>0 else 0.)
func strike():
	for i in 6:
		var m=mobs[i]
		if not m.node.visible or g.xy.distance_to(m.at)>8.6:continue
		if i==5:
			if m.rest<=0:g.notify("Sa couronne le protège. Attends la fin de sa charge.");continue
			boss_hp-=1
			g.notify("La couronne se fissure • %d / 5"%maxi(0,boss_hp))
		else:m.hp-=1
		m.at+=(m.at-g.xy).normalized()*2.;m.rest=1.7;m.wind=0.
		g.camp.spray(m.node.position+Vector3.UP,"gold",8)
		if (i==5 and boss_hp<=0) or (i<5 and m.hp<=0):
			m.node.visible=false;defeated.append(i)
			if i==5:
				stage=3;g.audio.effect("vestige");g.notify("Le sel noir est dissipé. Ta cloche se recharge en trois secondes.",6)
			else:g.bag.food+=1;g.notify(NAMES[i]+" repoussé • +1 ration")
		g.save_run()
