## Sfx
##
## Sound effects + background music. Sounds live in res://art/sfx/<name>.wav.
## Use Sfx.play("coin") from anywhere once the game has created the node.
class_name Sfx
extends Node

const DIR := "res://art/sfx/"
const NAMES := ["click", "work", "coin", "sale", "upgrade", "error", "bonus_spawn", "bonus_get",
	"landfill", "fire", "extinguish", "flood", "event", "year", "card", "sort_ok", "sort_bad",
	"sort_open", "whoosh", "confetti", "sprogimas"]
const POOL := 10
const MUSIC_DB := -15.0

# Per-sound volume (dB) and minimum gap between repeats (s).
const VOL := {"sale": -10.0, "coin": -16.0, "work": -4.0, "landfill": -4.0, "click": -8.0,
	"fire": -8.0, "flood": -6.0, "confetti": -6.0, "sprogimas": -1.0}
const GAP := {"coin": 0.12, "sale": 0.15, "work": 0.04, "landfill": 0.1, "click": 0.03}

static var inst: Sfx

var muted: bool = false
var music_vol: float = 0.7   # 0..1
var sfx_vol: float = 0.8     # 0..1
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _last: Dictionary = {}
var _music: AudioStreamPlayer

func _ready() -> void:
	inst = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in NAMES:
		var p: String = DIR + n + ".wav"
		if ResourceLoader.exists(p):
			_streams[n] = load(p)
	for i in POOL:
		var pl := AudioStreamPlayer.new()
		add_child(pl)
		_players.append(pl)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	add_child(_music)
	if ResourceLoader.exists(DIR + "muzika.wav"):
		_music.stream = load(DIR + "muzika.wav")
		_music.finished.connect(func(): _music.play())
	music_vol = float(Settings.get_value("music_vol", 0.7))
	sfx_vol = float(Settings.get_value("sfx_vol", 0.8))
	_apply_music_volume()
	set_muted(bool(Settings.get_value("muted", false)))

static func play(sound: String, pitch_var: float = 0.06, pitch: float = 1.0) -> void:
	if inst != null:
		inst._play(sound, pitch_var, pitch)

func _play(sound: String, pitch_var: float, pitch: float) -> void:
	if muted or not _streams.has(sound):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(sound, -10.0)) < float(GAP.get(sound, 0.0)):
		return
	_last[sound] = now
	var pl := _players[_next]
	_next = (_next + 1) % POOL
	pl.stream = _streams[sound]
	if sfx_vol <= 0.01:
		return
	pl.volume_db = float(VOL.get(sound, -3.0)) + linear_to_db(sfx_vol)
	pl.pitch_scale = pitch * randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	pl.play()

func set_music_volume(v: float) -> void:
	music_vol = clampf(v, 0.0, 1.0)
	Settings.set_value("music_vol", music_vol)
	_apply_music_volume()

func set_sfx_volume(v: float) -> void:
	sfx_vol = clampf(v, 0.0, 1.0)
	Settings.set_value("sfx_vol", sfx_vol)

func _apply_music_volume() -> void:
	if _music == null:
		return
	_music.volume_db = MUSIC_DB + linear_to_db(maxf(music_vol, 0.0001))
	if music_vol <= 0.01:
		_music.stop()
	elif not muted:
		start_music()

func start_music() -> void:
	if _music.stream != null and not _music.playing and not muted and music_vol > 0.01:
		_music.play()

func set_muted(m: bool) -> void:
	muted = m
	Settings.set_value("muted", m)
	if _music == null:
		return
	if m:
		_music.stop()
	else:
		start_music()
