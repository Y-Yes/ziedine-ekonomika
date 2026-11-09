## Local run checkpoints. Never sends progress or names to an external server.
class_name RunSave
extends RefCounted
static var path := "user://run-save.json"
const VERSION := 1
const GAME_FIELDS := ["difficulty","learning","lesson_timer","money","total_earned","loops","pollution","made_recycled","made_raw","landfilled","cleanups","elapsed","spawn_timer","bonus_timer","disaster_timer","sort_timer","year","year_time","y_earned","y_recycled","y_raw","y_landfill","perk_price","perk_decay","perk_loop_bonus","perk_cleanup","perk_bonus","perk_fire","event_timer","event_left","demand_mult","price_mult","raw_cost_mult","fine_mult","catastrophe","heat_left","in_report"]
const STATION_FIELDS := ["speed_level","cap_level","value_level","speed_mult","perk_speed","cap_bonus","cost_mult","fire","strike","strike_cost","hazard_mult","overflow_heat","sort_alert","_timer"]

static func read_save() -> Dictionary:
	if not FileAccess.file_exists(path):return {}
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK:return {}
	var data:Variant=parser.data
	if not data is Dictionary or int(data.get("version",0))!=VERSION:return {}
	if not data.get("state") is Dictionary or not data.get("stations") is Array:return {}
	if data.stations.size()!=6 or int(data.state.get("year",0)) not in range(1,11):return {}
	if not data.get("tokens",[]) is Array or data.get("tokens",[]).size()>2000:return {}
	for field in GAME_FIELDS:
		if not data.state.has(field):return {}
	if int(data.state.difficulty) not in range(4):return {}
	for station in data.stations:
		if not station is Dictionary:return {}
		for field in STATION_FIELDS:
			if not station.has(field):return {}
	for token in data.get("tokens",[]):
		if not token is Dictionary:return {}
		for field in ["form","next","angle","target","active","value","raw","buffer"]:
			if not token.has(field):return {}
	return data

static func available() -> bool:return not read_save().is_empty()

static func clear() -> void:
	if FileAccess.file_exists(path):DirAccess.remove_absolute(path)

static func capture(game:Node) -> Dictionary:
	var state:Dictionary={}
	for field in GAME_FIELDS:state[field]=game.get(field)
	var stations:Array=[]
	for station in game.stations:
		var row:Dictionary={}
		for field in STATION_FIELDS:row[field]=station.get(field)
		stations.append(row)
	var tokens:Array=[]
	for token in game.tokens:
		if not is_instance_valid(token):continue
		var buffered:=-1
		for i in game.stations.size():
			if token in game.stations[i].buffer:buffered=i;break
		tokens.append({"form":token.form,"next":token.next_station,"angle":token.angle,"target":token.target_angle,"active":token.active,"value":token.value,"raw":token.raw,"buffer":buffered})
	var litter:Array=[]
	for item in game.landfill._items:
		litter.append({"x":item.pos.x,"y":item.pos.y,"single":item.single,"rot":item.rot,"size":item.size})
	var cards:Array=[]
	for card in game.report_cards:cards.append(str(card.id))
	var h=game.hud
	var lesson:=""
	if h.lesson_dim.visible and h.lesson_box.visible:lesson=h._lesson_id
	var tutorial:Dictionary={}
	if game.tutorial_active and is_instance_valid(h.tutorial):tutorial={"step":h.tutorial._step,"clicks":h.tutorial._clicks}
	var bonuses:Array=[]
	for bonus in game.bonuses:
		if is_instance_valid(bonus) and bonus!=game._tut_bonus:
			var offset:Vector2=bonus.position-game.center
			bonuses.append({"x":offset.x,"y":offset.y,"amount":bonus.amount,"remaining":maxf(0.0,bonus.life-bonus._t)})
	return {"version":VERSION,"state":state,"stations":stations,"tokens":tokens,"litter":litter,"bonuses":bonuses,"event":game.event,"perks":game.perks_taken,"cards":cards,"report":game._report_summary,"tutorial":tutorial,"coach":h._coach_on,"coach_seen":h._coach_seen,"shown":h._lessons_shown,"queue":h._lesson_queue,"lesson":lesson,"quiz_done":h.quiz_done,"quiz_score":h._quiz_score,"quiz_active":h.lesson_dim.visible and h.quiz_box.visible,"quiz_i":h._quiz_i,"quiz_answered":h._quiz_answered,"mid_quiz":h._mid_quiz,"ending":h._learning_ending,"end_summary":h._end_summary,"name":h.name_edit.text,"income":game._income_log,"diagnostics":{"fps":Engine.get_frames_per_second(),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)}}

static func write_save(game:Node) -> bool:
	if not game.running or game.finished or game.exploding or game.sorting_active:return false
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify(capture(game)))
	file.close()
	return DirAccess.rename_absolute(path+".tmp",path)==OK

static func restore(game:Node,data:Dictionary) -> bool:
	if data.is_empty():return false
	game._restoring=true
	game.start_game(int(data.state.difficulty),false,false)
	for field in GAME_FIELDS:
		if data.state.has(field):game.set(field,data.state[field])
	game.diff=game.DIFFICULTIES[game.difficulty]
	game.perks_taken.assign(data.get("perks",[]))
	game.event=data.get("event",{})
	game._income_log=data.get("income",[])
	for i in game.stations.size():
		var station:Station=game.stations[i]
		for field in STATION_FIELDS:
			if data.stations[i].has(field):station.set(field,data.stations[i][field])
		station.recompute()
	for row in data.get("tokens",[]):
		var token:=Token.new()
		token.form=clampi(int(row.form),0,5);token.next_station=clampi(int(row.next),0,5)
		token.angle=float(row.angle);token.target_angle=float(row.target)
		token.active=bool(row.active);token.value=float(row.value);token.raw=bool(row.raw)
		token.position=game.ring.position_for_angle(token.angle)
		game.add_child(token);game.tokens.append(token)
		var buffer:=int(row.buffer)
		if buffer in range(6):
			token.active=false;game.stations[buffer].buffer.append(token)
		token.visible=token.active
	game.landfill.count=game.landfilled
	for row in data.get("litter",[]):
		game.landfill._items.append({"pos":Vector2(float(row.x),float(row.y)),"single":int(row.single),"rot":float(row.rot),"size":float(row.size),"age":1.0})
	for row in data.get("bonuses",[]):
		var bonus:=Bonus.new();bonus.amount=int(row.amount);bonus.life=float(row.remaining)
		bonus.position=game.center+Vector2(float(row.x),float(row.y))
		game.add_child(bonus);game.bonuses.append(bonus)
	game.report_cards.clear()
	for id in data.get("cards",[]):
		for card in game.PERKS:
			if str(card.id)==str(id):game.report_cards.append(card)
	game._report_summary=data.get("report",{})
	var h=game.hud
	h.name_edit.text=str(data.get("name",""))
	h.learn_badge.visible=game.learning
	h._lessons_shown.assign(data.get("shown",[]));h._lesson_queue.assign(data.get("queue",[]))
	h.quiz_done=bool(data.get("quiz_done",false));h._quiz_score=int(data.get("quiz_score",0))
	h._mid_quiz=bool(data.get("mid_quiz",false));h._learning_ending=bool(data.get("ending",false));h._end_summary=data.get("end_summary",{})
	h.start_coach(bool(data.get("coach",false)));h._coach_seen.assign(data.get("coach_seen",[]))
	# Never restore a pause flag without the corresponding visible modal.
	game.paused=false;game.lesson_open=false;game.coach_freeze=false;game.tutorial_active=false
	var tutorial:Dictionary=data.get("tutorial",{})
	if not tutorial.is_empty():
		game.tutorial_active=true;h.start_tutorial()
		h.tutorial._go(clampi(int(tutorial.step),0,5));h.tutorial._clicks=int(tutorial.clicks)
	if game.in_report and not game._report_summary.is_empty():
		game.paused=true;h.show_report(game._report_summary,game.report_cards)
	elif bool(data.get("quiz_active",false)):
		h._quiz_i=clampi(int(data.get("quiz_i",0)),0,Learning.quiz().size()-1)
		h.lesson_dim.show();h.lesson_box.hide();h.quiz_box.show();game.lesson_open=true
		if bool(data.get("quiz_answered",false)):h._next_question()
		else:h._show_question()
	elif str(data.get("lesson",""))!="":
		var id:=str(data.lesson);h._lessons_shown.erase(id);h.show_lesson(id)
	if not game.event.is_empty():h.show_event(game.event,clampf(game.event_left/maxf(float(game.event.get("time",1.0)),1.0),0.0,1.0))
	game._restoring=false
	h.refresh()
	return true
