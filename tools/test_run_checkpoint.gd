extends SceneTree
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	if not ok:push_error(label);quit(1)
func run()->void:
	RunSave.path="user://checkpoint-test.json";RunSave.clear()
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game
	await process_frame
	game.start_game(1,false,false);game.paused=true
	game.money=1234.5;game.year=3;game.year_time=27.25;game.total_earned=840.0
	game.stations[1].speed_level=4;game.stations[1].cap_level=3;game.stations[1]._timer=0.44;game.stations[1].recompute()
	game._start_event(game.EVENTS[0])
	var token:=Token.new();token.form=1;token.active=false;token.visible=false;token.value=12.5;token.angle=1.2;token.target_angle=2.3;token.next_station=1
	game.add_child(token);game.tokens.append(token);game.stations[1].buffer.append(token)
	for i in 20:game.landfill.add(i%6)
	game.landfilled=20
	assert(game.save_progress());assert(game.save_progress(),"Atomic replacement failed")
	var saved:=RunSave.read_save();assert(not saved.is_empty())
	assert(RunSave.restore(game,saved));game.paused=true
	assert(game.money==1234.5 and game.year==3 and game.year_time==27.25)
	assert(game.stations[1].speed_level==4 and game.stations[1].cap_level==3)
	assert(absf(game.stations[1]._timer-0.44)<0.0001)
	assert(game.tokens.size()==1 and game.stations[1].buffer.size()==1)
	assert(game.stations[1].buffer[0].value==12.5 and not game.tokens[0].active)
	assert(game.landfill.count==20 and game.landfill._items.size()==20)
	assert(game.event.id=="black_friday" and game.event_left>0)
	# Resuming the annual report must not award the bonus twice.
	game.paused=false;game._end_year()
	var report_money:float=game.money
	assert(game.save_progress());saved=RunSave.read_save()
	assert(RunSave.restore(game,saved))
	assert(game.in_report and game.paused and game.hud.report.visible)
	assert(game.money==report_money and game.report_cards.size()==3)
	game.choose_card(0)
	assert(not game.in_report and game.year==4)
	for icon in game.hud.card_icons:assert(icon.sheet==null)
	# A lesson and a question already answered both survive a reload.
	game.start_game(1,false,false);game.learning=true;game.hud.start_learning(false)
	game.hud.show_lesson("intro");assert(game.save_progress());saved=RunSave.read_save()
	assert(RunSave.restore(game,saved));assert(game.lesson_open and game.hud.lesson_dim.visible)
	game.hud._close_lesson();assert(not game.lesson_open)
	game.hud._start_quiz();game.hud._mid_quiz=true
	game.hud._answer(int(Learning.quiz()[0][2]))
	assert(game.save_progress());saved=RunSave.read_save();assert(RunSave.restore(game,saved))
	assert(game.hud._quiz_i==1 and game.hud._quiz_score==1 and game.lesson_open)
	game.start_game(1,true,true);game.paused=true
	game.hud.tutorial._go(1);game.hud.tutorial._clicks=2
	assert(game.save_progress());saved=RunSave.read_save();assert(RunSave.restore(game,saved))
	assert(game.tutorial_active and game.hud.tutorial._step==1 and game.hud.tutorial._clicks==2)
	assert(not game.coach_freeze)
	# Invalid JSON is ignored instead of producing a broken Continue action.
	var f:=FileAccess.open(RunSave.path,FileAccess.WRITE);f.store_string("{broken");f.close()
	assert(RunSave.read_save().is_empty())
	assert(game.ring._planet_ok==null and game.ring._planet_bad==null and game.ring._planet_fire==null)
	for station in game.stations:
		var base:Texture2D=StationMotion.base(station.index,station._sheet)
		assert(base.get_size()==Vector2(512,512) and not base is AtlasTexture)
	print("SAVE_ROUNDTRIP_OK money, year, upgrades, buffers, event, landfill, report once, lessons, quiz, corruption, small masks, unused textures")
	RunSave.clear();game.running=false
	await create_timer(0.7).timeout
	game.free();StationMotion._first_frames.clear();GameArt._textures.clear();GameArt._frames.clear();GameArt._bounds.clear();quit()
