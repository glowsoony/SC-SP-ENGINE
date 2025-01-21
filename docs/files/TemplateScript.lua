-- Lua stuff

function start()
	-- start of createing all things for gameplay
end

function onCreate()
	-- triggered when the lua file is started, some variables weren't created yet
end

function onCreatePost()
	-- end of "create"
end

function onDestroy()
	-- triggered when the lua file is ended (Song fade out finished)
end

-- Gameplay/Song interactions
function onBeatHit()
	-- triggered 4 times per section
end

function onStepHit()
	-- triggered 16 times per section
end

function onSectionHit()
	--triggered 1 time per section (16 steps or 4 beats)
end

function stepHit()
	-- triggered 4 times per section
end

function beatHit()
	-- triggered 16 times per section
end

function sectionHit()
	--triggered 1 time per section (16 steps or 4 beats)
end

function onUpdate(elapsed)
	-- start of "update", some variables weren't updated yet
end

function onUpdatePost(elapsed)
	-- end of "update"
end

function onStartCountdown()
	-- countdown started, duh
	-- return Function_Stop if you want to stop the countdown from happening (Can be used to trigger dialogues and stuff! You can trigger the countdown with startCountdown())
	return Function_Continue;
end

function onCountdownTick(counter)
	-- counter = 0 -> "Three"
	-- counter = 1 -> "Two"
	-- counter = 2 -> "One"
	-- counter = 3 -> "Go!"
	-- counter = 4 -> Nothing happens lol, tho it is triggered at the same time as onSongStart i think
end

function preUpdateSocre(miss)
	--miss = if player missed
end

function onUpdateScore(miss)
	--miss = if player missed
end

function onSongStart()
	-- Inst and Vocals start playing, songPosition = 0
end

function onSongGenerated()
	-- when song generates
end

function onEndSong()
	-- song ended/starting transition (Will be delayed if you're unlocking an achievement)
	-- return Function_Stop to stop the song from ending for playing a cutscene or something.
	return Function_Continue;
end


-- Substate interactions
function onPause()
	-- Called when you press Pause while not on a cutscene/etc
	-- return Function_Stop if you want to stop the player from pausing the game
	return Function_Continue;
end

function onResume()
	-- Called after the game has been resumed from a pause (WARNING: Not necessarily from the pause screen, but most likely is!!!)
end

function onGameOver()
	-- You died! Called every single frame your health is lower (or equal to) zero
	-- return Function_Stop if you want to stop the player from going into the game over screen
	return Function_Continue;
end

function onGameOverConfirm(retry)
	-- Called when you Press Enter/Esc on Game Over
	-- If you've pressed Esc, value "retry" will be false
end

-- Dialogue (When a dialogue is finished, it calls startCountdown again)
function onNextDialogue(line)
	-- triggered when the next dialogue line starts, dialogue line starts with 1
end

function onSkipDialogue(line)
	-- triggered when you press Enter and skip a dialogue line that was still being typed, dialogue line starts with 1
end

function goodNoteHitPre(id, direction, noteType, isSustainNote)
	-- Function called when you hit a note (***after*** note hit calculations)
	-- Values work the same as goodNoteHit
end
function opponentNoteHitPre(id, direction, noteType, isSustainNote)
	-- Works the same as goodNoteHitPost, but for Opponent's notes being hit
	-- Values work the same as goodNoteHit
end

-- Note miss/hit
function goodNoteHit(id, direction, noteType, isSustainNote)
	-- Function called when you hit a note (***before*** note hit calculations)
	-- id: The note member id, you can get whatever variable you want from this note, example: "getPropertyFromGroup('notes', id, 'strumTime')"
	-- noteData: 0 = Left, 1 = Down, 2 = Up, 3 = Right
	-- noteType: The note type string/tag
	-- isSustainNote: If it's a hold note, can be either true or false
end

function opponentNoteHit(id, direction, noteType, isSustainNote)
	-- Works the same as goodNoteHit, but for Opponent's notes being hit
end

function noteMissPress(direction)
	-- Called after the note press miss calculations
	-- Player pressed a button, but there was no note to hit (ghost miss)
end

function noteMiss(id, direction, noteType, isSustainNote)
	-- Called after the note miss calculations
	-- Player missed a note by letting it go offscreen
end

-- Other function hooks
function onRecalculateRating()
	-- return Function_Stop if you want to do your own rating calculation,
	-- use setRatingPercent() to set the number on the calculation and setRatingName() to set the funny rating name
	-- NOTE: THIS IS CALLED BEFORE THE CALCULATION!!!
	return Function_Continue;
end

function onMoveCamera(focus)
	if focus == 'boyfriend' then
		-- called when the camera focus on boyfriend
	elseif focus == 'dad' then
		-- called when the camera focus on dad
	end
end


-- There are 14 values for each not 2 anymore!
-- Event notes hooks
function onEvent(name, eventParams, strumTime)
	-- event note triggered
	-- triggerEvent() calls this function!!

	-- print('Event triggered: ', name, eventParams);
end

function eventEarlyTrigger(name, eventParams, strumTime)
	--[[
	Here's a port of the Kill Henchmen early trigger but on Lua instead of Haxe:

	if name == 'Kill Henchmen'
		return 280;

	This makes the "Kill Henchmen" event be triggered 280 miliseconds earlier so that the kill sound is perfectly timed with the song
	]]--

	-- write your shit under this line, the new return value will override the ones hardcoded on the engine
end

function onEventPushed(name, eventParams, strumTime)
	-- Works like a preloader for events such for "Change Character"
end

--Added the values 1-14 like (name, value1, value2, etc..)
function onEventLegacy(name, etc.., strumTime)
	-- event note triggered
	-- triggerEventLegacy() calls this function!!

	-- print('Event triggered: ', name, eventParams);
end

--Added the values 1-14 like (name, value1, value2, etc..)
function eventEarlyTriggerLegacy(name, etc..., strumTime)
	--[[
	Here's a port of the Kill Henchmen early trigger but on Lua instead of Haxe:

	if name == 'Kill Henchmen'
		return 280;

	This makes the "Kill Henchmen" event be triggered 280 miliseconds earlier so that the kill sound is perfectly timed with the song
	]]--

	-- write your shit under this line, the new return value will override the ones hardcoded on the engine
end

--Added the values 1-14 like (name, value1, value2, etc..)
function onEventPushedLegacy(name, etc..., strumTime)
	-- Works like a preloader for events such for "Change Character"
end

-- Tween/Timer hooks
function onTweenCompleted(tag)
	-- A tween you called has been completed, value "tag" is it's tag
end

function onTimerCompleted(tag, loops, loopsLeft)
	-- A loop from a timer you called has been completed, value "tag" is it's tag
	-- loops = how many loops it will have done when it ends completely
	-- loopsLeft = how many are remaining
end

--SCE extra Doc functions or Functions not mentioned originally
function onSpawnNote(membersIndex, playerNumber, ID)
	--membersIndex of the strums
	--plyaerNumber of what strum number "playerNumber ? 0 : 1" -- haxe form
	--ID number ID of strum as in noteData
end

function onFocus()
	--function when focused on game
end

function onFocusPost()
	--function when focused on game but post
end

function onFocusLost()
	--function when un-focused on game
end

function onFocusLostPost()
	--function when un-focused on game but post
end

function update()
	--function like onUpdate but for kade comp and when started song!
end

function playerOneTurn()
	--Turn on musthitsection
end

function playerTwoTurn()
	--Turn when not on musthitsection
end

function playerThreeTurn()
	--Turn on gf's section
end

function playerFourTurn()
	--Turn on player4hitsection
end

function onMoveCamera(character)
	--On Character Bro
end

function onCameraMovement(char, usesNoteData, isOP, isGF, note, intensity1, intensity2)
	--Char = character 
	--usesNoteData is the character null with frames / has not frames so uses notes to move camera
	--isOP = is Dad the character
	--isGF = is the character GF
	--note = noteData
	--intensity1 = the first intensity used for XY of the cameraFollow
	--intensity2 - the second intensity used for XY of the cameraFollow 
end

function onGhostTap(key)
	--key = key as int for tapped key
end

function onKeyPress(key)
	--key = key as int form pressed
end

function onKeyRelease(key)
	--key = key as int for released key
end

function playerOneMissPress(direction, time)
	--direction as int 0-3 for acting as noteData
	--time = songPosition in time form
end

--All these functions work like opponentNoteHit/goodNoteHit --Except the (noteData, time) ones, type work with just songPosition time and noteData!
function dadPreNoteHit(noteData, isSus, noteType, dType)
end

function dadNoteHit(noteData, isSus, noteType, dType)
end

function playerTwoPreSing(noteData, time)
end

function playerTwoSing(noteData, time)
end

function bfPreNoteHit(noteData, isSus, noteType, dType)
end

function bfNoteHit(noteData, isSus, noteType, dType)
end

function playerOnePreSing(noteData, time)
end

function playerOneSing(noteData, time)
end