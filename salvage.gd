extends RefCounted
const TITLES=["Le treuil du Courlis","L’appel de la Corne","La courroie de la dynamo"]
const INTRO=["Le coffre pend au bout d’un câble mangé par le sel. Bloque le cliquet quand la tension passe dans la zone dorée.","Le contrepoids retient le réflecteur. Écoute le signal des trois cloches, puis reproduis-le dans le même ordre.","Le vilebrequin entraîne trois roues. Amène les aiguilles sur leurs repères dorés. Chaque roue entraîne sa voisine de droite."]
const LOG=["« On a sauvé la lentille avant que le Courlis ne talonne. »","« Par temps bouché, c’était la cloche qui ramenait les équipages. »","« Nous avons laissé de quoi remonter la dynamo à la main. »"]
const NOTES=["Grave","Médium","Aigu"]
const PITCH=[.75,1.,1.335]
var game
var site=-1
var elapsed=0.
var last_try=-2.
var steps=0
var misses=0
var message=""
var message_t=0.
var sequence=[0,2,1]
var played=0
var replay_t=0.
var replay_i=-1
var flash=-1
var flash_t=0.
var gears=[1,3,0]
var stops=[0,1,3]
var solved=false
var finish_t=0.
func begin(g,i:int):
	game=g;site=i;elapsed=0.;last_try=-2.;steps=0;misses=0
	message="";message_t=0.;solved=false;finish_t=0.;flash=-1;flash_t=0.;played=0
	sequence=[[0,2,1],[2,0,1],[1,0,2]][posmod(int(g.run_name),3)].duplicate()
	gears=[1,3,0];stops=[0,1,3]
	if i==1: replay()
func tick(dt):
	elapsed+=dt
	message_t=maxf(0.,message_t-dt);flash_t=maxf(0,flash_t-dt)
	if solved:
		finish_t+=dt
		if finish_t>.85:
			game.state="play"
			game.claim_part(site)
			game.find_nearest()
		return
	if site==1 and replay_i>=0:
		replay_t-=dt
		if replay_t<=0:
			if replay_i==sequence.size():
				replay_i=-1
				message="À toi de répondre.";message_t=2.5
			else:
				note(sequence[replay_i])
				replay_i+=1;replay_t=.81
func position()->float: return .50+.46*sin(elapsed*(2.05+steps*.18)+steps*.64)
func sweet()->float: return [.62,.33,.73][mini(steps,2)]
func tolerance()->float: return .126+minf(.065,misses*.015)
func note(i:int):
	flash=i;flash_t=.52
	game.audio.effect("cloche",-5,PITCH[i])
func replay():
	played=0;replay_i=0;replay_t=.46
	message="Écoute et regarde les cloches.";message_t=3.
func win():
	solved=true;finish_t=0.;message="Mécanisme libéré";message_t=1.
	game.audio.effect("prise",-4,1.3)
func action(i:int=0):
	if solved: return
	if site==0:
		if elapsed-last_try<.37: return
		last_try=elapsed
		if abs(position()-sweet())<=tolerance():
			steps+=1
			game.audio.effect("chantier",-7,1.+steps*.12)
			message="Cliquet engagé";message_t=.7
			if steps>=3: win()
		else:
			misses+=1;message="Attends le passage dans la zone dorée.";message_t=1.5
			game.audio.effect("pas",-5,.70)
	elif site==1:
		if replay_i>=0 or i<0 or i>2: return
		note(i)
		if i==sequence[played]:
			played+=1
			if played==3: win()
		else:
			misses+=1;replay();replay_t=1.05
			message="Écoute de nouveau le signal.";message_t=2.8
	elif site==2:
		if i<0 or i>2: return
		gears[i]=posmod(gears[i]+1,4)
		if i<2: gears[i+1]=posmod(gears[i+1]-1,4)
		game.audio.effect("chantier",-11,1.0+i*.24)
		if gears==stops: win()
