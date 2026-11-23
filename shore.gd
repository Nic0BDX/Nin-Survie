extends RefCounted
const Ink=preload("res://meshwork.gd")
const Art=preload("res://art.gd")
const MARKS=[Vector2(-65,-38),Vector2(48,43),Vector2(18,-68)]
const TITLES=["L’amer des Dents","La cabane de la Veuve","La vigie d’Ouessantine"]
const GIFTS=["Doublure de laine","Herminette de marine","Sangle de nage"]
const TEXTS=["« J’ai laissé ma vareuse sous les pierres. Quand le vent traverse le ciré, on croit que le froid vient de la mer. Il vient de partout à la fois. »","« Les bonnes planches ne sont pas celles qu’on abat. Ce sont celles que le flot a déjà rabotées pour nous. Prends mon herminette. »","« Regarde d’abord où tu vas ressortir. Attache la sangle à ton sac et laisse le courant porter le reste. »"]
const EFFECTS=["Tu perds 25 % de chaleur en moins.","Chaque tas de bois rapporte une branche de plus.","Ton souffle dure 25 % plus longtemps à la nage."]
var seals=[]
var crabs=[]
var relics=[]

func install(w):
	var m=Ink.new()
	var rand=RandomNumberGenerator.new()
	rand.seed=18722
	# Fissured pale granite shelves, with heather caps above the spray.
	for area in [[Vector2(-67,-38),8.,7],[Vector2(-28,-53),8.,5],[Vector2(72,-24),7.,4],[Vector2(-78,15),5.,3],[Vector2(24,42),5.,3],[Vector2(14,-70),7.,4]]:
		for j in int(area[2]):
			var a=TAU*j/area[2]+.32
			var q:Vector2=area[0]+Vector2(cos(a),sin(a))*float(area[1])
			var p=w.pos(q)
			var s=rand.randf_range(.71,1.37)
			m.blob(p+Vector3.UP*.69*s,Vector3(2.9,1.65,2.12)*s,Color("#758a89"),a,6)
			m.blob(p+Vector3(.2,1.62,-.21)*s,Vector3(2.38,.61,1.80)*s,Color("#a1aa99"),a+.05,6)
			if j%3==1: m.blob(p+Vector3(.15,1.98,-.22)*s,Vector3(1.62,.30,1.21)*s,Color("#849067"),a,6)
			w.blocks.append([q,1.18*s])
	# A slatted fisherman's jetty on the south shore of the inhabited island.
	var pier=Vector3(11.5,2.54,46.6)
	for i in 18:
		m.box(pier+Vector3(.025*sin(i),0,i*.42),Vector3(2.20+.08*sin(i*3),.17,.40),Art.LWOOD.darkened((i%3)*.045))
	for side in [-1,1]:
		m.box(pier+Vector3(side*.74,-.23,3.47),Vector3(.19,.33,7.65),Art.WOOD)
		for k in 4:
			var p=pier+Vector3(side*.93,0,k*2.34)
			m.column(p-Vector3.UP*7.,7.44,.11,.12,Art.WOOD)
			m.column(p+Vector3.UP*.29,.13,.13,.13,Art.CREAM)
	for k in 2:
		var a=pier+Vector3(.93,.4,k*2.34+.02)
		var b=a+Vector3.BACK*2.34
		var c=a.lerp(b,.5)-Vector3.UP*.27
		m.rod(a,c,.032,.032,Art.CREAM,5);m.rod(c,b,.032,.032,Art.CREAM,5)
	var q=w.pos(Vector2(60,-18))
	for i in 3: barrel(m,q+Vector3(1.1*i,0,i*.15),.86+(i%2)*.2)
	net_rack(m,w.pos(Vector2(49.6,-22.7)))
	# Dry-stone boundary and buoys drying outside the keeper's cottage.
	for j in 13:
		var p=w.pos(Vector2(-14.4+.18*sin(j*.4),13.+j*.62))
		for k in 2: m.blob(p+Vector3(.03,.21+k*.37,0),Vector3(.37,.24,.43),Color("#90978a").darkened(.035*(j%3)),j+.4*k,6)
	for j in 4: Art.marine(m,w.pos(Vector2(-9.9-j*.69,17.2+.21*sin(j))))
	for i in 300:
		var p=Vector2(rand.randf_range(-83,86),rand.randf_range(-78,58))
		var h=w.ground(p)
		if h<-.9 or h>1.4: continue
		var origin=w.pos(p)
		for j in 4:
			var a=TAU*j/4+rand.randf_range(-.36,.36)
			var stem=Vector3(cos(a),0,sin(a))
			var b=origin+stem*rand.randf_range(.33,.66)+Vector3.UP*.06
			m.rod(origin,b,.027,.016,Color("#735f47"),4)
			m.blob(b,Vector3(.18,.057,.10),Color("#838654"),a,5)
	for i in 3:
		var p=w.pos(MARKS[i])
		if i==0:
			for j in 4: m.blob(p+Vector3(.03*j,.24+j*.49,0),Vector3(1.3-j*.23,.40,1.04-j*.18),Color("#87918a"),i+j*.5)
			m.column(p+Vector3.UP*2.05,.98,.10,.08,Art.WOOD)
			m.box(p+Vector3.UP*2.91,Vector3(.98,.22,.14),Art.CREAM)
		elif i==1:
			Art.hut(m,p+Vector3(0,0,-1.5),.64)
			barrel(m,p+Vector3(2.1,0,-.5),.65)
		else:
			m.column(p,2.4,.78,.55,Art.CREAM,9)
			m.column(p+Vector3.UP*1.15,.61,.70,.65,Art.DARK,9)
			m.column(p+Vector3.UP*2.40,.36,.68,.18,Art.RED,9)
		var pos2=MARKS[i]+Vector2(0,1.6)
		var box=Ink.new()
		box.column(Vector3.ZERO,.8,.15,.13,Art.WOOD)
		box.box(Vector3(0,1.,0),Vector3(.87,.62,.40),Color("#328080"))
		box.box(Vector3(0,1.35,0),Vector3(1.0,.12,.56),Art.CREAM)
		box.box(Vector3(0,1.02,.22),Vector3(.50,.075,.04),Art.GOLD)
		var node=box.node(w.mat);node.position=w.pos(pos2);w.add_child(node)
		relics.append(pos2)
	w.add_child(m.node(w.mat))
	seal_colony(w)
	beach_crabs(w,rand)

func barrel(m,p,s):
	m.column(p,.20*s,.43*s,.50*s,Art.WOOD,10)
	m.column(p+Vector3.UP*.20*s,.56*s,.50*s,.51*s,Art.LWOOD,10)
	m.column(p+Vector3.UP*.76*s,.27*s,.51*s,.43*s,Art.WOOD,10)
	for y in [.22,.78]:m.column(p+Vector3.UP*y*s,.07*s,.517*s,.517*s,Art.METAL,10)
func net_rack(m,p):
	for i in [-1,1]:
		m.rod(p+Vector3(i*1.8,0,0),p+Vector3(i*1.75,2.6,.1),.11,.075,Art.WOOD,6)
	m.rod(p+Vector3(-1.83,2.45,0),p+Vector3(1.84,2.56,0),.074,.074,Art.WOOD)
	for k in 11:
		var x=-1.55+k*.31
		var len2=minf(.94,1.55-abs(x)*.34)
		m.rod(p+Vector3(x,2.42,.03),p+Vector3(minf(1.7,x+.60),2.42-len2,.15),.022,.022,Art.METAL,4)
		m.rod(p+Vector3(x,2.42,.06),p+Vector3(maxf(-1.7,x-.60),2.42-len2,.19),.022,.022,Art.METAL,4)
	for j in 5:
		var x=-1.4+j*.70
		m.blob(p+Vector3(x,2.42,.02),Vector3(.11,.15,.11),Art.RED if j%2==0 else Art.CREAM,j,6)

func seal_colony(w):
	var m=Ink.new()
	var gray=Color("#7e918c")
	m.blob(Vector3(0,.32,0),Vector3(.40,.38,.90),gray,1,9)
	m.blob(Vector3(0,.61,-.66),Vector3(.30,.32,.33),gray.lightened(.03),.4,8)
	m.blob(Vector3(0,.54,-.91),Vector3(.20,.15,.18),Color("#a9afa0"),1.3,7)
	m.blob(Vector3(0,.60,-1.07),Vector3(.072,.053,.055),Art.DARK,2,6)
	for side in [-1,1]:
		m.blob(Vector3(side*.155,.69,-.90),Vector3.ONE*.055,Art.DARK,1,6)
		m.blob(Vector3(side*.30,.14,.03),Vector3(.27,.07,.35),gray.darkened(.12),1)
		m.blob(Vector3(side*.14,.13,.86),Vector3(.15,.08,.35),gray.darkened(.12),3)
	var mesh=m.mesh(w.mat)
	for i in 6:
		var p=[Vector2(-68,1),Vector2(-63,1),Vector2(-46,-3),Vector2(40,48),Vector2(44,51),Vector2(76,-7)][i]
		var n=MeshInstance3D.new();n.mesh=mesh;w.add_child(n)
		seals.append({"node":n,"home":p,"phase":i*1.69})
func beach_crabs(w,rand):
	var m=Ink.new()
	var shell=Color("#c16d51")
	m.blob(Vector3(0,.13,0),Vector3(.23,.14,.19),shell,1.7,7)
	for side in [-1,1]:
		for j in 3:
			var a=Vector3(side*.16,.11,-.07+j*.09)
			var b=a+Vector3(side*.14,.04,.02);m.rod(a,b,.034,.026,shell,4)
			m.rod(b,b+Vector3(side*.09,-.14,.055),.027,.012,shell,4)
		m.blob(Vector3(side*.25,.19,-.17),Vector3(.105,.087,.11),shell.lightened(.12),1,5)
	var model=m.mesh(w.mat)
	for i in 2500:
		var p=Vector2(rand.randf_range(-76,76),rand.randf_range(-66,54))
		if w.ground(p)<-.75 or w.ground(p)>1.7: continue
		var n=MeshInstance3D.new();n.mesh=model;w.add_child(n)
		crabs.append({"node":n,"home":p,"phase":rand.randf()*TAU})
		if crabs.size()==30: break
func animate(w,t,water):
	for s in seals:
		var a=t*.115+s.phase;var origin=s.home
		var p=origin+Vector2(cos(a)*1.8,sin(a)*1.22)
		var bed=w.ground(p)
		var bob=sin(a*2.7+s.phase)
		var h=maxf(bed,water-.39+.20*bob-.56*smoothstep(.6,.93,sin(a*.91+s.phase)))
		s.node.position=Vector3(p.x,h,p.y);s.node.rotation=Vector3(.10*bob,-a-.9,.045*sin(a*3))
	for c in crabs:
		var a=t*.58+c.phase;var p=c.home+Vector2(sin(a)*.53,cos(a*.61)*.31)
		var h=w.ground(p)
		c.node.visible=water<h+.12
		if c.node.visible:
			c.node.position=Vector3(p.x,h+.009+.025*abs(sin(t*11+c.phase)),p.y);c.node.rotation.y=c.phase+sin(a*.4)*.3
