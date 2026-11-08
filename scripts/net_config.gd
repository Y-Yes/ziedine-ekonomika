## NetConfig
##
## Where the online leaderboard lives (PostgREST over HTTPS).
##
## The key below is the database's *publishable* key. It is meant to be shipped
## inside the client and is public by definition – a web export can be unpacked
## by anyone, and every browser has to be able to read it anyway. It is NOT a
## password and hiding it is impossible, not merely inconvenient.
##
## All protection lives in the database instead:
##   * row level security – `anon` may SELECT and INSERT, nothing else, so the
##     table cannot be edited or wiped with this key;
##   * CHECK constraints – nickname length / charset / profanity and the ranges
##     of every number are validated by Postgres, so the rules cannot be
##     bypassed by patching the game.
## Nickname filtering is deliberately server-side only: the profanity list is
## part of the schema, not of this source code.
##
## Never put the `sb_secret_...` key in the game.
class_name NetConfig
extends RefCounted

const URL := "https://lnslrkrxpcjtagabnrfs.supabase.co"
const KEY := "sb_publishable_0FERqKCMmBPKUjLqLY9-VA__1X26hLD"
const TABLE := "leaderboard"

## Set to false for a fully offline build: no requests are made at all.
const ENABLED := true

## Seconds before a request is given up on. Generous on purpose: the first
## request from a browser to the server pays DNS + TCP + TLS + a CORS preflight,
## and on a slow school network 8 s was not enough (it surfaced as
## HTTPRequest.RESULT_TIMEOUT, i.e. "failed to load the table"). The game never
## blocks on this – the board simply shows an error after the wait.
const TIMEOUT := 20.0

static func endpoint() -> String:
	return "%s/rest/v1/%s" % [URL, TABLE]
