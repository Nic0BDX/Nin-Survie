extends Node
var music=AudioStreamPlayer.new()
var sea=AudioStreamPlayer.new()
var clips={}
var voices=[]
var next=0
var enabled=true
var music_on=true

func _ready():
	for item in [[music,"keravel",-11.0],[sea,"ressac",-2.0]]:
		var p:AudioStreamPlayer=item[0]
		p.stream=load("res://audio/"+item[1]+".ogg")
		p.stream.loop=true
		p.volume_db=item[2]
		add_child(p)
		p.play()
	for k in ["pas","eau","prise","chantier","cloche","vestige","choc","corne","goeland","braise","noye"]:
		clips[k]=load("res://audio/"+k+".wav")
	for i in 12:
		var p=AudioStreamPlayer.new()
		add_child(p)
		voices.append(p)

func effect(k:String,db:float=0.0,pitch:float=1.0):
	if not enabled or not clips.has(k): return
	var p=voices[next%voices.size()]
	next+=1
	p.stream=clips[k]
	p.volume_db=db
	p.pitch_scale=pitch
	p.play()

func mix(surf:float,storm:float,night:float):
	sea.volume_db=lerpf(-8.5,1.8,clampf(surf+storm*.45,0,1)) if enabled else -80.
	music.volume_db=-10.5-night*2.5 if enabled and music_on else -80.

func mute():
	enabled=not enabled
	for p in voices:
		if not enabled: p.stop()
