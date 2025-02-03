package scfunkin.objects.note;

import flixel.util.FlxSignal;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSort;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import scfunkin.backend.misc.CustomArrayGroup;
import scfunkin.utils.tools.ICloneable;
import scfunkin.objects.ui.Character;

enum abstract CharacterStrumLine(String) from String to String
{
  var DAD = "DAD";
  var BF = "BF";
  var GF = "GF";
  var OTHER = "OTHER";
}

typedef SpawnSplashData =
{
  @:default(0)
  public var currentDataIndex:Int;

  @:default(null)
  public var targetNote:Note;

  @:default(false)
  public var isPlayer:Bool;
}

class Limiter
{
  public var noteLimit(default, set):Int;

  function set_noteLimit(value:Int):Int
  {
    noteLimit = value;
    setNoteLimit(strumLimit);
    return noteLimit;
  }

  public var splashLimit(default, set):Int;

  function set_splashLimit(value:Int):Int
  {
    splashLimit = value;
    setSplashLimit(splashLimit);
    return splashLimit;
  }

  public var strumLimit(default, set):Int;

  function set_strumLimit(value:Int):Int
  {
    strumLimit = value;
    setStrumLimit(strumLimit);
    return strumLimit;
  }

  public var holdCoverLimit(default, set):Int;

  function set_holdCoverLimit(value:Int):Int
  {
    holdCoverLimit = value;
    setHoldCoverLimit(holdCoverLimit);
    return holdCoverLimit;
  }

  public function new()
  {
    setNoteLimit = function(maxLimit:Int) {
    }
    setSplashLimit = function(maxLimit:Int) {
    }
    setStrumLimit = function(maxLimit:Int) {
    }
    setHoldCoverLimit = function(maxLimit:Int) {
    }
  }

  public dynamic function setNoteLimit(maxLimit:Int) {}

  public dynamic function setSplashLimit(maxLimit:Int) {}

  public dynamic function setStrumLimit(maxLimit:Int) {}

  public dynamic function setHoldCoverLimit(maxLimit:Int) {}
}

class StrumLine extends FlxTypedGroup<StrumArrow>
{
  public static var STRUM_X:Float = 49;
  public static var STRUM_X_MIDDLESCROLL:Float = -272;

  public var initialStrumLinePos:FlxPoint = new FlxPoint();
  public var strumLineName:String = "";

  public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();
  public var strumLineID:Int = 0;
  public var actualStrumLineID:Int = 0;

  // Used in-game to control the scroll speed within a song
  public var scrollSpeed(default, set):Float = 1.0;

  function set_scrollSpeed(value:Float):Float
  {
    final ratio:Float = value / scrollSpeed; // funny word huh
    if (ratio != 1)
    {
      for (noteGroup in [notes?.members ?? [], unspawnNotes?.members ?? []])
      {
        if (noteGroup == null || noteGroup.length < 1) continue;

        for (note in noteGroup)
        {
          note.noteScrollSpeed = value;
          note.resizeByRatio(value);
        }
      }
    }
    scrollSpeed = value;
    noteKillOffset = Math.max(Conductor.stepCrochet, 350 / scrollSpeed * playbackSpeed);
    return scrollSpeed;
  }

  public var notes:FlxTypedGroup<Note> = null;
  public var unspawnNotes:CustomArrayGroup<Note> = new CustomArrayGroup<Note>();
  public var loadedNotes:CustomArrayGroup<Note> = new CustomArrayGroup<Note>();
  public var isPixelNotes:Bool = false;
  public var cpuControlled:Bool = false;

  public var characterStrumlineType:CharacterStrumLine = DAD;
  public var strumsBlocked:Array<Bool> = [];

  public var limiter:Limiter = new Limiter();
  public var ghostTapping:Bool = ClientPrefs.data.ghostTapping;

  public var drawNotes:Bool = true;
  public var noteKillOffset:Float = 350;

  public var playbackSpeed(default, set):Float = 1;

  function set_playbackSpeed(value:Float):Float
  {
    final ratio:Float = playbackSpeed / value; // funny word huh
    if (ratio != 1)
    {
      for (note in notes.members)
        note.resizeByRatio(ratio);
      for (note in unspawnNotes.members)
        note.resizeByRatio(ratio);
    }
    playbackSpeed = value;
    return playbackSpeed;
  }

  public var calls:StrumLineCalls = new StrumLineCalls();

  public var drawSplashes:Bool = true;
  public var drawHoldCovers:Bool = true;

  public var noteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();
  public var holdCovers:HoldCoverGroup = new HoldCoverGroup();
  public var controls:Controls = new Controls();

  public var characters:Array<Character> = [];

  public var modchartRendered:Bool = false;
  public var playNotes:Bool = false;
  public var isPlayer:Bool = false;
  public var staticColorStrums:Bool = false;

  public function new(?strumLineId:Int = -1, ?characterStrumLineType:CharacterStrumLine = DAD)
  {
    this.initialStrumLinePos.set(ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50);
    this.strumLineID = strumLineId;
    this.characterStrumlineType = characterStrumLineType;
    holdCovers.enabled = !(PlayState.SONG == null
      || PlayState.SONG.options.disableHoldCovers
      || PlayState.SONG.options.notITG
      || ClientPrefs.data.holdCoverPlay);
    holdCovers.canSplash = characterStrumLineType == BF;
    notes = new FlxTypedGroup<Note>();
    noteSplashes = new FlxTypedGroup<NoteSplash>();
    for (notes in [unspawnNotes, loadedNotes])
    {
      if (notes == null) continue;

      notes.validTime = function(rate:Float = 1, ?ignoreMultSpeed:Bool = false):Bool {
        final firstMember:Note = notes.members[0];
        if (firstMember == null) return false;
        return (notes.length > 0 && firstMember.validTime(rate, ignoreMultSpeed));
      }
    }
    calls.onDeleted = function(note:Note, unspawn:Bool = false) {
      invalidateNote(note, unspawn);
      calls.noteDeleted.dispatch(note, unspawn);
    }
    calls.onNotReady = function(note:Note) {
      note.visible = note.active = false;
      calls.noteNotReady.dispatch(note);
    }
    limiter.setNoteLimit = function(maxLimit:Int) {
      notes.maxSize = maxLimit;
    }
    limiter.setSplashLimit = function(maxLimit:Int) {
      noteSplashes.maxSize = maxLimit;
    }
    limiter.setStrumLimit = function(maxLimit:Int) {
      maxSize = maxLimit;
    }
    limiter.setHoldCoverLimit = function(maxLimit:Int) {
      holdCovers.maxSize = maxLimit;
    }
    final limitActionArray:Array<String> = ['note', 'strum', 'splash', 'holdCover'];
    for (limit in limitActionArray)
      Reflect.setProperty(limiter, limit + 'Limit', 0);
    calls.onDraw = function() {
    }
    calls.onDrawPost = function() {
      if (notes != null && notes.visible && notes.exists && drawNotes)
      {
        notes.cameras = cameras;
        notes.draw();
      }
      if (noteSplashes != null && noteSplashes.visible && noteSplashes.exists && drawSplashes)
      {
        noteSplashes.cameras = cameras;
        noteSplashes.draw();
      }
      if (holdCovers != null && holdCovers.visible && holdCovers.exists && drawHoldCovers)
      {
        holdCovers.cameras = cameras;
        holdCovers.draw();
      }
    }
    calls.onUpdate = function(elapsed) {
    }
    calls.onUpdatePost = function(elapsed) {
      if (notes != null && notes.exists && notes.active && updateNoteGroup)
      {
        notes.update(elapsed);
        if (handleHitNotes != null) handleHitNotes();
      }
      if (noteSplashes != null && noteSplashes.exists && noteSplashes.active && updateSplashGroup) noteSplashes.update(elapsed);
      if (holdCovers != null && holdCovers.exists && holdCovers.active && updateHoldCoverGroup) holdCovers.update(elapsed);
    }
    calls.onDestroyPost = function() {
      unspawnNotes.clear();
      for (object in [notes, noteSplashes, holdCovers])
        if (object != null) object = null;
      initialStrumLinePos = flixel.util.FlxDestroyUtil.destroy(initialStrumLinePos);
    }
    calls.onRevivePost = function() {
      for (object in [notes, noteSplashes, holdCovers])
        if (object != null) object.revive();
    }
    calls.onKillPost = function() {
      for (object in [notes, noteSplashes, holdCovers])
        if (object != null) object.kill();
    }
    calls.onClearNotesBefore = function(time:Float = 0, ?completelyClearNotes:Bool = false) {
      var i:Int = unspawnNotes.length - 1;
      while (i >= 0)
      {
        final daNote:Note = unspawnNotes.members[i];
        if (!completelyClearNotes)
        {
          if (daNote.strumTime - 350 < time) invalidateNote(daNote, true);
        }
        else
          invalidateNote(daNote, true);
        --i;
      }

      i = notes.length - 1;
      while (i >= 0)
      {
        final daNote:Note = notes.members[i];
        if (!completelyClearNotes)
        {
          if (daNote.strumTime - 350 < time) invalidateNote(daNote, false);
        }
        else
          invalidateNote(daNote, false);
        --i;
      }
      calls.clearNotesBefore.dispatch(time, completelyClearNotes);
    }
    calls.onIsPixel = function(daNote:Note) {
      isPixelNotes = daNote.noteSkin.contains('pixel');
      calls.noteIsPixel.dispatch(daNote);
    }

    calls.onNotHoldingKey = function() {
      for (character in characters)
        character.danceConditions(character.allowHoldTimer(), character.forcedToIdle);
    }

    createNotes = function(sectionsData:Array<SwagSection>, allowedSections:Array<Int> = null, limit:Float = 0, limitAllowed:Bool = false) {
      var unspawnNotes:Array<Note> = [];
      var daSection:Int = 0;
      var ghostNotesCaught:Int = 0;
      var daBpm:Float = Conductor.bpm;
      var oldNote:Note = null;
      for (section in sectionsData)
      {
        if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm) daBpm = section.bpm;

        var doSection:Bool = true;
        if (allowedSections != null) if (daSection < allowedSections[0] || daSection >= allowedSections[1]) doSection = false;
        if (doSection)
        {
          for (i in 0...section.sectionNotes.length)
          {
            final songNotes:Array<Dynamic> = section.sectionNotes[i];
            final spawnTime:Float = songNotes[0];
            final noteColumn:Int = Std.int(songNotes[1] % PlayState.SONG.totalColumns);
            final holdLength:Float = ClientPrefs.getGameplaySetting('sustainnotesactive')
              && !Math.isNaN(songNotes[2]) ? songNotes[2] : 0.0;
            final noteType:String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
            final noteStrumId:Int = songNotes[4];

            if (noteStrumId != strumLineId) continue;

            if (i != 0)
            {
              // CLEAR ANY POSSIBLE GHOST NOTES
              for (evilNote in unspawnNotes)
              {
                final matches:Bool = (noteColumn == evilNote.noteData && strumLineId == evilNote.strumLineID && evilNote.noteType == noteType);
                if (matches && Math.abs(spawnTime - evilNote.strumTime) == 0.0)
                {
                  if (evilNote.tail.length > 0)
                  {
                    for (tail in evilNote.tail)
                    {
                      tail.destroy();
                      unspawnNotes.remove(tail);
                    }
                  }
                  evilNote.destroy();
                  unspawnNotes.remove(evilNote);
                  ghostNotesCaught++;
                  // continue;
                }
              }
            }
            final swagNote:Note = new Note(
              {
                strumTime: spawnTime,
                noteData: noteColumn,
                isSustainNote: false,
                noteSkin: PlayState.SONG.options.arrowSkin,
                prevNote: oldNote,
                createdFrom: this,
                scrollSpeed: scrollSpeed,
                parentStrumline: this,
                inEditor: false
              });
            swagNote.realNoteData = songNotes[1];
            swagNote.clipToStrum = characterStrumlineType == BF;
            var altName:String = (section.altAnim
              || (section.playerAltAnim && characterStrumlineType == BF)
              || (section.CPUAltAnim && characterStrumlineType == DAD)) ? '-alt' : '';
            var isPixelNote:Bool = (swagNote.texture.contains('pixel') || swagNote.noteSkin.contains('pixel'));
            swagNote.setupNote(strumLineId, actualStrumLineID, daSection, noteType);
            if (swagNote.noteType != 'GF Sing') swagNote.gfNote = (section.gfSection && characterStrumlineType == BF);
            if (altName == '' && swagNote.noteType == 'Alt Animation') altName = '-alt';
            swagNote.animSuffix = altName;
            swagNote.containsPixelTexture = isPixelNote;
            swagNote.sustainLength = holdLength;
            swagNote.dType = section.dType;
            swagNote.scrollFactor.set();
            swagNote.bpm = daBpm;

            var pushNotes:Bool = !(spawnTime > limit && limitAllowed); // should prevent people from editing audio to end the song early to cheat on leaderboard
            if (pushNotes) unspawnNotes.push(swagNote);

            final curStepCrochet:Float = 60 / daBpm * 1000 / 4.0;
            final roundSus:Int = Math.round(swagNote.sustainLength / curStepCrochet);
            if (roundSus != 0)
            {
              for (susNote in 0...roundSus)
              {
                oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

                final sustainNote:Note = new Note(
                  {
                    strumTime: spawnTime + (curStepCrochet * susNote),
                    noteData: noteColumn,
                    isSustainNote: true,
                    noteSkin: PlayState.SONG.options.arrowSkin,
                    prevNote: oldNote,
                    createdFrom: this,
                    scrollSpeed: scrollSpeed,
                    parentStrumline: this,
                    inEditor: false
                  });
                var isPixelNoteSus:Bool = (sustainNote.texture.contains('pixel')
                  || sustainNote.noteSkin.contains('pixel')
                  || oldNote.texture.contains('pixel')
                  || oldNote.noteSkin.contains('pixel'));
                sustainNote.clipToStrum = swagNote.clipToStrum;
                sustainNote.realNoteData = swagNote.realNoteData;
                sustainNote.setupNote(swagNote.strumLineID, swagNote.actualStrumLineID, swagNote.noteSection, swagNote.noteType);
                sustainNote.animSuffix = swagNote.animSuffix;
                if (sustainNote.noteType != 'GF Sing') sustainNote.gfNote = swagNote.gfNote;
                sustainNote.dType = swagNote.dType;
                sustainNote.containsPixelTexture = isPixelNoteSus;
                if (pushNotes) sustainNote.parent = swagNote;
                sustainNote.scrollFactor.set();
                sustainNote.bpm = swagNote.bpm;
                if (pushNotes)
                {
                  unspawnNotes.push(sustainNote);
                  swagNote.tail.push(sustainNote);
                }

                // After everything loads
                var isNotePixel:Bool = isPixelNoteSus;
                oldNote.containsPixelTexture = isNotePixel;
                sustainNote.correctionOffset = swagNote.height / 2;
                if (!isNotePixel)
                {
                  if (oldNote.isSustainNote)
                  {
                    oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
                    oldNote.scale.y /= playbackSpeed;
                    oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
                  }

                  if (ClientPrefs.data.downScroll) sustainNote.correctionOffset = 0;
                }
                else if (oldNote.isSustainNote)
                {
                  oldNote.scale.y /= playbackSpeed;
                  oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
                }

                if (characterStrumlineType == BF) sustainNote.x += FlxG.width / 2; // general offset
                else if (ClientPrefs.data.middleScroll)
                {
                  sustainNote.x += 310;
                  if (noteColumn > 1) // Up and Right
                    sustainNote.x += FlxG.width / 2 + 25;
                }
              }
            }

            if (characterStrumlineType == BF) swagNote.x += FlxG.width / 2; // general offset
            else if (ClientPrefs.data.middleScroll)
            {
              swagNote.x += 310;
              if (noteColumn > 1) // Up and Right
                swagNote.x += FlxG.width / 2 + 25;
            }
            oldNote = swagNote;
          }
        }
        daSection += 1;
      }
      return unspawnNotes;
    }

    charactersDance = function() {
    }

    final splash:NoteSplash = new NoteSplash(characterStrumLineType == DAD);
    noteSplashes.add(splash);
    splash.alpha = 0.000001; // cant make it invisible or it won't allow precaching
    super(0);
  }

  public dynamic function charactersDance() {}

  public dynamic function handleHitNotes()
  {
    notes.forEachAlive(function(daNote:Note) {
      if (characterStrumlineType == BF)
      {
        daNote.canBeHit = (daNote.strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * daNote.lateHitMult)
          && daNote.strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * daNote.earlyHitMult));

        if (daNote.strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !daNote.wasGoodHit) daNote.tooLate = true;
      }
      else
      {
        daNote.canBeHit = false;

        if (!daNote.wasGoodHit && daNote.strumTime <= Conductor.songPosition)
        {
          if (!daNote.isSustainNote || (daNote.prevNote.wasGoodHit && !daNote.ignoreNote)) daNote.wasGoodHit = true;
        }
      }
    });
  }

  public function copyNotes():Array<Note>
    return loadedNotes.members = unspawnNotes.members.copy();

  public var guitarHeroSustains:Bool = ClientPrefs.data.newSustainBehavior;

  public dynamic function setHoldCoverParents(amount:Int)
  {
    if (holdCovers != null)
    {
      for (i in 0...amount)
      {
        holdCovers.addHold(i);
        holdCovers.members[i].parentStrum = members[i];
      }
    }
  }

  override public function draw()
  {
    calls.onDraw();
    super.draw();
    calls.onDrawPost();
  }

  public var updateNoteGroup:Bool = true;
  public var updateSplashGroup:Bool = true;
  public var updateHoldCoverGroup:Bool = true;

  override public function update(elapsed:Float):Void
  {
    calls.onUpdate(elapsed);
    super.update(elapsed);
    calls.onUpdatePost(elapsed);
  }

  public dynamic function spawnSplash(data:SpawnSplashData)
  {
    if (data == null) return;
    final targetNote:Note = data.targetNote;
    final dataIndex:Int = targetNote != null ? targetNote.noteData : data.currentDataIndex;
    final mustPress:Bool = (characterStrumlineType != null && characterStrumlineType == BF) ? true : data.isPlayer;
    final strum:StrumArrow = members[dataIndex % members.length];
    final splash:NoteSplash = noteSplashes.recycle(NoteSplash);
    splash.opponentSplashes = !mustPress;
    splash.babyArrow = strum;
    if (targetNote != null) splash.spawnSplashNote(targetNote);
    else
      splash.spawnSplashNote(strum.x, strum.y, targetNote, dataIndex);
    if (ClientPrefs.data.splashAlphaAsStrumAlpha) splash.alpha = members[dataIndex].alpha;
    noteSplashes.add(splash);
  }

  public dynamic function missHoldCover(key:Int, ?note:Note)
    if (holdCovers != null) holdCovers.despawnOnMiss(key, note);

  public dynamic function spawnHoldCover(note:Note)
    if (holdCovers != null) holdCovers.spawnOnNoteHit(note);

  public dynamic function registerUnspawnedNotes()
  {
    if (!unspawnNotes.isFirstValid()) return;
    while (unspawnNotes.validTime(playbackSpeed))
    {
      final dunceNote:Note = unspawnNotes.byIndex(0);
      notes.insert(0, dunceNote);
      dunceNote.spawned = true;

      calls.onSpawnNoteLua(notes, dunceNote);
      calls.onSpawnNoteHx(dunceNote);

      unspawnNotes.spliceIndexOf(dunceNote, 1);

      calls.onSpawnNoteLuaPost(notes, dunceNote);
      calls.onSpawnNoteHxPost(dunceNote);
    }
  }

  public dynamic function updateNote(daNote:Note)
  {
    final strum:StrumArrow = members[daNote.noteData % members.length];
    if (daNote.allowStrumFollow) daNote.followStrumArrow(strum, playbackSpeed);

    calls.onIsPixel(daNote);
    calls.onHit(daNote);

    if (daNote.allowNoteToHit && daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumArrow(strum);
    // Kill extremely late notes and cause misses

    if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
    {
      if (ClientPrefs.data.vanillaStrumAnimations)
      {
        if ((daNote.isSustainNote && daNote.isHoldEnd)
          || (!daNote.isSustainNote && characterStrumlineType == DAD)) strum.playAnim('static', true);
      }

      calls.onMissed(daNote);
      if (daNote.allowDeleteAndMiss) invalidateNote(daNote, false);
    }
  }

  public dynamic function updateNotes(ready:Bool = false)
  {
    if (!ready)
    {
      notes.forEachAlive(function(daNote:Note) calls.onNotReady(daNote));
      return;
    }
    notes.forEachAlive(function(daNote:Note) {
      updateNote(daNote);
    });
  }

  public dynamic function createNotes(sectionsData:Array<SwagSection>, allowedSections:Array<Int> = null, limit:Float = 0,
      limitAllowed:Bool = false):Array<Note>
    return [];

  public dynamic function setStrumStyle(style:String, ?index:Int = -1)
  {
    if (index < 0)
    {
      for (i in 0...index)
      {
        members[i].reloadNote(style);
        reloadPixel(members[i], style);
      }
    }
    else
    {
      members[index].reloadNote(style);
      reloadPixel(members[index], style);
    }
  }

  public dynamic function generateStrums(player:Int, style:String, amount:Int, ?xPos:Array<Float> = null, ?yPos:Array<Float> = null)
  {
    if (xPos != null && xPos.length != amount || yPos != null && yPos.length != amount) return;
    if (xPos == null)
    {
      xPos = [];
      final TRUE_STRUM_X:Float = style.contains('pixel') ? initialStrumLinePos.x + (ClientPrefs.data.middleScroll ? 3 : 2) : initialStrumLinePos.x;
      for (posAmount in 0...amount)
        xPos.push(TRUE_STRUM_X);
    }
    if (yPos == null)
    {
      yPos = [];
      for (posAmount in 0...amount)
        yPos.push(initialStrumLinePos.y);
    }

    for (strumIndex in 0...amount)
      add(createStrum(xPos[strumIndex], yPos[strumIndex], player, style, strumIndex));
  }

  public dynamic function createStrum(xPos:Float, yPos:Float, player:Int, style:String, i:Int):StrumArrow
  {
    final babyArrow:StrumArrow = new StrumArrow(xPos, yPos, i, player, style);
    babyArrow.downScroll = ClientPrefs.data.downScroll;
    babyArrow.texture = style;
    babyArrow.reloadNote(style);
    reloadPixel(babyArrow, style);

    if (player == 0) babyArrow.middlePosition();
    babyArrow.playerPosition();
    return babyArrow;
  }

  public dynamic function reloadPixel(babyArrow:StrumArrow, style:String):Bool
    return babyArrow.containsPixelTexture = (style.contains('pixel') || babyArrow.daStyle.contains('pixel') || babyArrow.texture.contains('pixel'));

  override public function kill()
  {
    calls.onKill();
    super.kill();
    calls.onKillPost();
  }

  override public function revive()
  {
    calls.onRevive();
    super.revive();
    calls.onRevivePost();
  }

  override public function destroy()
  {
    calls.onDestroy();
    super.destroy();
    calls.onDestroyPost();
    calls.clearFunctions();
  }

  public function onKeyPress(event:KeyboardEvent):Void
  {
    final eventKey:FlxKey = event.keyCode;
    final key:Int = PlayState.getKeyFromEvent(keysArray, eventKey);
    if (controls.controllerMode || key <= -1) return;
    #if debug
    // Prevents crash specifically on debug without needing to try catch shit
    @:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
    #end
    if (!FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) return;
    updatePressedKeys(key);
    calls.onKeyPressEvent(key);
  }

  public function onKeyRelease(event:KeyboardEvent):Void
  {
    final eventKey:FlxKey = event.keyCode;
    final key:Int = PlayState.getKeyFromEvent(keysArray, eventKey);
    if (controls.controllerMode || key <= -1) return;
    updateReleasedKeys(key);
    calls.onKeyReleaseEvent(key);
  }

  public dynamic function canKeyActionUpdate():Bool
    return true;

  public dynamic function sortHitNotes(a:Note, b:Note):Int
  {
    if (a.lowPriority && !b.lowPriority) return 1;
    else if (!a.lowPriority && b.lowPriority) return -1;
    return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
  }

  public var _updatedPosition:Float = 0;
  public var playKeys:Bool = false;

  public dynamic function updatePressedKeys(key:Int, ?reasons:Bool)
  {
    if (cpuControlled || !playKeys || !canKeyActionUpdate()) return;

    final keyBool:Bool = (key > length);
    if (key < 0 || keyBool) return;

    final ret:Dynamic = calls.onKeyPressedPre(key);
    if (ret == scfunkin.utils.LuaUtil.Function_Stop) return;

    if (Conductor.songPosition >= 0 && _updatedPosition <= 0) _updatedPosition = Conductor.songPosition;
    final _updatedLastPosition:Float = _updatedPosition;
    if (_updatedPosition >= 0) _updatedPosition = FlxG.sound.music.time + Conductor.offset;

    final plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
      final canHit:Bool = n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.allowNoteToHit && !n.tooLate && !n.wasGoodHit && !n.blockHit;
      return canHit && !n.isSustainNote && n.noteData == key;
    });
    plrInputNotes.sort(sortHitNotes);

    if (plrInputNotes.length != 0)
    { // slightly faster than doing `> 0` lol
      var funnyNote:Note = plrInputNotes[0]; // front note

      if (plrInputNotes.length > 1)
      {
        var doubleNote:Note = plrInputNotes[1];

        if (doubleNote.noteData == funnyNote.noteData)
        {
          // if the note has a 0ms distance (is on top of the current note), kill it
          if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0
            && doubleNote.allowDeleteAndMiss) invalidateNote(doubleNote, false);
          else if (doubleNote.strumTime < funnyNote.strumTime)
          {
            // replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
            funnyNote = doubleNote;
          }
        }
      }
      calls.onNoteKeyHit(funnyNote);
    }
    else
    {
      calls.onGhostTap(key);
      if (!ghostTapping) calls.onMissPress(key);
    }

    _updatedPosition = _updatedLastPosition;

    if (strumsBlocked[key] != true) playPressed(key);
    calls.onKeyPressed(key);
  }

  public dynamic function updateReleasedKeys(key:Int, ?reasons:Bool)
  {
    if (cpuControlled || !playKeys || !canKeyActionUpdate()) return;

    final keyBool:Bool = (key > length);
    if (key < 0 || keyBool) return;

    final ret:Dynamic = calls.onKeyReleasedPre(key);
    if (ret == scfunkin.utils.LuaUtil.Function_Stop) return;

    playStatic(key);

    calls.onKeyReleased(key);

    if (holdCovers != null
      && holdCovers.members[key % holdCovers.members.length].isAnimationNull()
      && !members[key % members.length].getLastAnimationPlayed().endsWith('p')) missHoldCover(key);
  }

  public dynamic function playConfirm(key:Int, time:Float = -1, isSus:Bool = false)
  {
    final spr:StrumArrow = members[key % members.length];
    if (spr == null) return;
    if (ClientPrefs.data.vanillaStrumAnimations)
    {
      if (isSus && spr.animation.getByName('confirm-hold') != null) spr.holdConfirm();
      else if (spr.animation.getByName('confirm') != null) spr.playAnim('confirm', true);
    }
    else if (spr.animation.getByName('confirm') != null)
    {
      spr.playAnim('confirm', true);
      if (time != -1) spr.resetAnim = time;
    }
  }

  public dynamic function playStatic(key:Int)
  {
    final spr:StrumArrow = members[key % members.length];
    if (spr != null && spr.animation.getByName('static') != null)
    {
      spr.playAnim('static', true);
      spr.resetAnim = 0;
    }
  }

  public dynamic function playPressed(key:Int)
  {
    final spr:StrumArrow = members[key % members.length];
    if (spr != null
      && spr.animation.curAnim.name != 'confirm'
      && spr.animation.curAnim.name != 'confirm-hold'
      && spr.animation.getByName('pressed') != null)
    {
      spr.playAnim('pressed', true);
      spr.resetAnim = 0;
    }
  }

  public var keysArray:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

  public dynamic function canHoldKey():Bool
    return true;

  public dynamic function updateKeys()
  {
    if (cpuControlled || !playKeys) return;

    // HOLDING
    var holdArray:Array<Bool> = [];
    var pressArray:Array<Bool> = [];
    var releaseArray:Array<Bool> = [];
    for (key in keysArray)
    {
      holdArray.push(controls.pressed(key));
      pressArray.push(controls.justPressed(key));
      releaseArray.push(controls.justReleased(key));
    }

    // TO DO: Find a better way to handle controller inputs, this should work for now
    if (controls.controllerMode && pressArray.contains(true)) for (i in 0...pressArray.length)
      if (pressArray[i] && strumsBlocked[i] != true) updatePressedKeys(i);

    if (canHoldKey())
    {
      // rewritten inputs???
      for (n in notes)
      { // I can't do a filter here, that's kinda awesome
        var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.allowNoteToHit && !n.tooLate && !n.wasGoodHit && !n.blockHit);

        if (guitarHeroSustains) canHit = canHit && n.parent != null && n.parent.wasGoodHit;

        if (canHit && n.isSustainNote)
        {
          var released:Bool = !holdArray[n.noteData];

          if (!released) calls.onNoteKeyHit(n);
        }
      }

      if (!holdArray.contains(true)) calls.onNotHoldingKey();
      else
        calls.onHoldingKey();
    }

    // TO DO: Find a better way to handle controller inputs, this should work for now
    if ((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true)) for (i in 0...releaseArray.length)
      if (releaseArray[i] || strumsBlocked[i] == true) updateReleasedKeys(i);
  }

  public dynamic function invalidateNote(note:Note, unspawnedNotes:Bool):Void
  {
    if (note == null) return;
    note.invalidate();
    if (!unspawnedNotes) notes.remove(note, true);
    else
      unspawnNotes.remove(note);
  }
}

class StrumLineCalls
{
  // Note Direct Calls / Spawn Note Calls
  public var noteIsPixel:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onIsPixel:Note->Void = null;

  public var noteHit:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onHit:Note->Void = null;

  public var noteMissed:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onMissed:Note->Void = null;

  public var noteNotReady:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onNotReady:Note->Void = null;

  public var noteDeleted:FlxTypedSignal<(Note, Bool) -> Void> = new FlxTypedSignal();
  public var onDeleted:(Note, Bool) -> Void = null;

  public var clearNotesBefore:FlxTypedSignal<(Float, Bool) -> Void> = new FlxTypedSignal();
  public var onClearNotesBefore:(Float, Bool) -> Void = null;

  public var clearNotesAfter:FlxTypedSignal<Float->Void> = new FlxTypedSignal();
  public var onClearNotesAfter:Float->Void = null;

  public var spawnNoteLua:FlxTypedSignal<(notes:FlxTypedGroup<Note>, dunceNote:Note) -> Void> = new FlxTypedSignal();
  public var onSpawnNoteLua:(FlxTypedGroup<Note>, Note) -> Void = null;

  public var spawnNoteHx:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onSpawnNoteHx:Note->Void = null;

  public var spawnNoteLuaPost:FlxTypedSignal<(notes:FlxTypedGroup<Note>, dunceNote:Note) -> Void> = new FlxTypedSignal();
  public var onSpawnNoteLuaPost:(FlxTypedGroup<Note>, Note) -> Void = null;

  public var spawnNoteHxPost:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onSpawnNoteHxPost:Note->Void = null;

  // Input Calls
  public var keyPressedPre:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onKeyPressedPre:Int->Dynamic = null;

  public var keyPressed:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onKeyPressed:Int->Void = null;

  public var keyReleasedPre:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onKeyReleasedPre:Int->Dynamic = null;

  public var keyReleased:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onKeyReleased:Int->Void = null;

  public var ghostTap:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onGhostTap:Int->Void = null;

  public var noteMissPress:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onMissPress:Int->Void = null;

  // StrumLine PlayState Calls
  public var noteKeyHit:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onNoteKeyHit:Note->Void = null;

  public var notHoldingKey:FlxSignal;
  public var onNotHoldingKey:Void->Void = null;

  public var holdingKey:FlxSignal;
  public var onHoldingKey:Void->Void = null;

  // Actual Interally Use StrumLine Calls
  public var draw:FlxSignal;
  public var onDraw:Void->Void = null;

  public var drawPost:FlxSignal;
  public var onDrawPost:Void->Void = null;

  public var update:FlxSignal;
  public var onUpdate:Float->Void;

  public var updatePost:FlxSignal;
  public var onUpdatePost:Float->Void;

  public var revive:FlxSignal;
  public var onRevive:Void->Void = null;

  public var revivePost:FlxSignal;
  public var onRevivePost:Void->Void = null;

  public var kill:FlxSignal;
  public var onKill:Void->Void = null;

  public var killPost:FlxSignal;
  public var onKillPost:Void->Void = null;

  public var destroy:FlxSignal;
  public var onDestroy:Void->Void = null;

  public var destroyPost:FlxSignal;
  public var onDestroyPost:Void->Void = null;

  public var keyPressEvent:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onKeyPressEvent:Int->Void;

  public var keyReleaseEvent:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onKeyReleaseEvent:Int->Void;

  public function new()
    clearFunctions(); // Functions need to be activated first.

  public function clearFunctions()
  {
    onIsPixel = function(note) {
    }
    onHit = function(note) {
    }
    onMissed = function(note) {
    }
    onNotReady = function(note) {
    }
    onDeleted = function(note, unspawn) {
    }
    onClearNotesBefore = function(time, completely) {
    }
    onClearNotesAfter = function(time) {
    }
    onSpawnNoteLua = function(notes, dunceNote) {
    }
    onSpawnNoteHx = function(note) {
    }
    onSpawnNoteLuaPost = function(notes, dunceNote) {
    }
    onSpawnNoteHxPost = function(note) {
    }
    onKeyPressedPre = function(key):Dynamic {
      return null;
    }
    onKeyPressed = function(key) {
    }
    onKeyReleasedPre = function(key):Dynamic {
      return null;
    }
    onKeyReleased = function(key) {
    }
    onGhostTap = function(key) {
    }
    onMissPress = function(key) {
    }
    onNoteKeyHit = function(note) {
    }
    onNotHoldingKey = function() {
    }
    onHoldingKey = function() {
    }
    onDraw = function() {
    }
    onDrawPost = function() {
    }
    onUpdate = function(elapsed) {
    }
    onUpdatePost = function(elapsed) {
    }
    onRevive = function() {
    }
    onRevivePost = function() {
    }
    onKill = function() {
    }
    onKillPost = function() {
    }
    onDestroy = function() {
    }
    onDestroyPost = function() {
    }
    onKeyReleaseEvent = function(key) {
    }
    onKeyPressEvent = function(key) {
    }
  }
}
