package objects.note;

import flixel.util.FlxSignal;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSort;
import backend.CustomArrayGroup;

enum abstract CharacterStrumLine(String) from String to String
{
  var DAD = "Dad";
  var BF = "Boyfriend";
  var GF = "Girlfriend";
  var OTHER = "Other";
}

typedef SpawnSplashData =
{
  @:default(0)
  var currentDataIndex:Int;
  @:default(null)
  var targetNote:Note;
  @:default(false)
  var isPlayer:Bool;
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
  // Used in-game to control the scroll speed within a song
  public var scrollSpeed(default, set):Float = 1.0;

  function set_scrollSpeed(value:Float):Float
  {
    final ratio:Float = value / scrollSpeed; // funny word huh
    if (ratio != 1)
    {
      if (notes != null && notes.length > 0)
      {
        for (note in notes.members)
        {
          note.noteScrollSpeed = value;
          note.resizeByRatio(ratio);
        }
      }
      if (unspawnNotes != null && unspawnNotes.length > 0)
      {
        for (note in unspawnNotes.members)
        {
          note.noteScrollSpeed = value;
          note.resizeByRatio(ratio);
        }
      }
    }
    scrollSpeed = value;
    noteKillOffset = Math.max(Conductor.stepCrochet, 350 / scrollSpeed * playbackSpeed);
    return scrollSpeed;
  }

  public var notes:FlxTypedGroup<Note> = null;
  public var unspawnNotes:CustomArrayGroup<Note> = new CustomArrayGroup<Note>();
  public var isPixelNotes:Bool = false;

  public var allowOverrideCpuControl:Bool = true;
  public var cpuControlled:Bool = false;

  public var characterStrumlineType:CharacterStrumLine = DAD;
  public var strumLines:FlxTypedGroup<StrumLine> = new FlxTypedGroup<StrumLine>();
  public var strumsBlocked:Array<Bool> = [];

  public var limiter:Limiter = new Limiter();
  public var ghostTapping:Bool = ClientPrefs.data.ghostTapping;

  function set_cpuControlled(value:Bool):Bool
  {
    cpuControlled = value;
    if (PlayState.instance != null && allowOverrideCpuControl) cpuControlled = PlayState.instance.cpuControlled;
    return cpuControlled;
  }

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

  public function new(?characterStrumLineType:CharacterStrumLine = DAD)
  {
    holdCovers.enabled = !(PlayState.SONG == null
      || PlayState.SONG.options.disableHoldCovers
      || PlayState.SONG.options.notITG
      || !ClientPrefs.data.holdCoverPlay);
    holdCovers.canSplash = characterStrumLineType == BF;
    notes = new FlxTypedGroup<Note>();
    noteSplashes = new FlxTypedGroup<NoteSplash>();
    unspawnNotes.validTime = function(rate:Float = 1, ?ignoreMultSpeed:Bool = false):Bool {
      final firstMember:Note = unspawnNotes.members[0];
      if (firstMember != null) return (unspawnNotes.length > 0 && firstMember.validTime(rate, ignoreMultSpeed));
      return false;
    }
    calls.onDeleted = function(note:Note, unspawn:Bool) {
      invalidateNote(note, unspawn);
      calls.noteDeleted.dispatch(note, unspawn);
    }
    calls.onNotReady = function(note:Note) {
      note.visible = note.active = false;
      calls.noteNotReady.dispatch(note);
    }
    registerUnspawnedNotes = function() {
    }
    updateNotes = function(daNote:Note) {
    }
    invalidateNote = function(note:Note, unspawn:Bool) {
      if (note == null) return;
      note.invalidate();
      if (!unspawn) notes.remove(note, true);
      else
        unspawnNotes.remove(note);
      note.destroy();
      note = null;
    }
    super(0);
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
      if (notes != null && notes.exists && notes.active && updateNoteGroup) notes.update(elapsed);
      if (noteSplashes != null && notes.exists && notes.active && updateSplashGroup) noteSplashes.update(elapsed);
      if (holdCovers != null && holdCovers.exists && holdCovers.active && updateHoldCoverGroup) holdCovers.update(elapsed);
    }
    calls.onDestroyPost = function() {
      unspawnNotes.clear();
      if (notes != null) notes = null;
      if (noteSplashes != null) noteSplashes = null;
      if (holdCovers != null) holdCovers = null;
    }
    calls.onRevivePost = function() {
      if (notes != null) notes.revive();
      if (noteSplashes != null) noteSplashes.revive();
      if (holdCovers != null) holdCovers.revive();
    }
    calls.onKillPost = function() {
      if (notes != null) notes.kill();
      if (noteSplashes != null) noteSplashes.kill();
      if (holdCovers != null) holdCovers.kill();
    }
  }

  public var guitarHeroSustains:Bool = ClientPrefs.data.newSustainBehavior;

  public dynamic function updateHolds(elapsed:Float)
  {
    if (holdCovers != null) holdCovers.update(elapsed);
  }

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
    final dataIndex:Int = data.targetNote != null ? data.targetNote.noteData : data.currentDataIndex;
    final mustPress:Bool = (targetNote != null && targetNote.mustPress) ? true : data.isPlayer;
    final splash:NoteSplash = new NoteSplash(!mustPress);
    splash.babyArrow = members[dataIndex];
    if (targetNote != null) splash.spawnSplashNote(targetNote);
    else
      splash.spawnSplashNote(targetNote, dataIndex);
    if (ClientPrefs.data.splashAlphaAsStrumAlpha) splash.alpha = members[dataIndex].alpha;
    noteSplashes.add(splash);
  }

  public dynamic function missHoldCover(key:Int, ?note:Note)
  {
    if (holdCovers != null) holdCovers.despawnOnMiss(key, note);
  }

  public dynamic function spawnHoldCover(note:Note)
  {
    if (holdCovers != null) holdCovers.spawnOnNoteHit(note);
  }

  public dynamic function registerUnspawnedNotes() {}

  public dynamic function updateNotes(daNote:Note) {}

  public dynamic function createNotes():Array<Note>
    return [];

  public dynamic function generateStrums(xPos:Array<Float>, yPos:Array<Float>, player:Int, style:String, amount:Int)
  {
    if (xPos.length <= amount || yPos.length <= amount) return;
    for (i in 0...amount)
      add(createStrum(xPos[i], yPos[i], player, style, i));
  }

  public dynamic function createStrum(xPos:Float, yPos:Float, player:Int, style:String, i:Int):StrumArrow
  {
    final babyArrow:StrumArrow = new StrumArrow(xPos, yPos, i, player, style);
    babyArrow.downScroll = ClientPrefs.data.downScroll;
    babyArrow.texture = style;
    babyArrow.reloadNote(style);
    reloadPixel(babyArrow, style);

    if (PlayState.SONG != null && !PlayState.SONG.options.notITG)
    {
      babyArrow.loadLane();
      babyArrow.bgLane.updateHitbox();
      babyArrow.bgLane.scrollFactor.set();
    }
    #if SCEModchartingTools
    else
      babyArrow.loadLineSegment();
    #end
    return babyArrow;
  }

  public dynamic function reloadPixel(babyArrow:StrumArrow, style:String)
  {
    final isPixel:Bool = (style.contains('pixel') || babyArrow.daStyle.contains('pixel') || babyArrow.texture.contains('pixel'));
    babyArrow.containsPixelTexture = isPixel;
  }

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

  public dynamic function sortHitNotes(a:Note, b:Note):Int
  {
    if (a.lowPriority && !b.lowPriority) return 1;
    else if (!a.lowPriority && b.lowPriority) return -1;
    return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
  }

  var _updatedPosition:Float = 0;

  public dynamic function updatePressedKeys(key:Int, ?reasons:Bool)
  {
    final keyBool:Bool = (key > length);
    if (reasons || cpuControlled || key < 0 || keyBool) return;
    calls.onKeyPressedPre(key);

    if (Conductor.songPosition >= 0 && _updatedPosition <= 0) _updatedPosition = Conductor.songPosition;
    final _updatedLastPosition:Float = _updatedPosition;
    if (_updatedPosition >= 0) _updatedPosition = FlxG.sound.music.time + Conductor.offset;

    final plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
      final canHit:Bool = n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.allowNotesToHit && !n.tooLate && !n.wasGoodHit && !n.blockHit;
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
      calls.onPlayerNoteHit(funnyNote);
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
    final keyBool:Bool = (key > length);
    if (reasons || cpuControlled || key < 0 || keyBool) return;

    calls.onKeyReleasedPre(key);

    playStatic(key);

    calls.onKeyReleased(key);

    if (holdCovers != null
      && holdCovers.members[key].isAnimationNull()
      && !members[key].getLastAnimationPlayed().endsWith('p')) missHoldCover(key);
  }

  public dynamic function playConfirm(key:Int, time:Float, isSus:Bool = false)
  {
    final spr:StrumArrow = members[key];
    if (spr != null)
    {
      if (ClientPrefs.data.vanillaStrumAnimations)
      {
        if (isSus)
        {
          if (spr.animation.getByName('confirm-hold') != null) spr.holdConfirm();
        }
        else
        {
          if (spr.animation.getByName('confirm') != null) spr.playAnim('confirm', true);
        }
      }
      else
      {
        if (spr.animation.getByName('confirm') != null)
        {
          spr.playAnim('confirm', true);
          spr.resetAnim = time;
        }
      }
    }
  }

  public dynamic function playStatic(key:Int)
  {
    final spr:StrumArrow = members[key];
    if (spr != null && spr.animation.getByName('static') != null)
    {
      spr.playAnim('static', true);
      spr.resetAnim = 0;
    }
  }

  public dynamic function playPressed(key:Int)
  {
    final spr:StrumArrow = members[key];
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

  public dynamic function updateKeys(reasons:Bool)
  {
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

    if (reasons)
    {
      // rewritten inputs???
      for (n in notes)
      { // I can't do a filter here, that's kinda awesome
        var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.allowNotesToHit && !n.tooLate && !n.wasGoodHit && !n.blockHit);

        if (guitarHeroSustains) canHit = canHit && n.parent != null && n.parent.wasGoodHit;

        if (canHit && n.isSustainNote)
        {
          var released:Bool = !holdArray[n.noteData];

          if (!released) calls.onPlayerNoteHit(n);
        }
      }

      if (!holdArray.contains(true) || (PlayState.instance != null && PlayState.instance.endingSong)) calls.onNotHoldingKey();
      else
        calls.onHoldingKey();
    }

    // TO DO: Find a better way to handle controller inputs, this should work for now
    if ((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true)) for (i in 0...releaseArray.length)
      if (releaseArray[i] || strumsBlocked[i] == true) updateReleasedKeys(i);
  }

  public dynamic function invalidateNote(note:Note, unspawnedNotes:Bool):Void {}
}

class StrumLineCalls
{
  // Note Direct Calls / Spawn Note Calls
  public var noteIsPixel:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

  public dynamic function onIsPixel(note:Note) {}

  public var noteHit:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

  public dynamic function onHit(note:Note) {}

  public var noteMissed:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

  public dynamic function onMissed(daNote:Note) {}

  public var noteNotReady:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

  public dynamic function onNotReady(daNote:Note) {}

  public var noteDeleted:FlxTypedSignal<(Note, Bool) -> Void> = new FlxTypedSignal<(Note, Bool) -> Void>();

  public dynamic function onDeleted(note:Note, unspawn:Bool) {}

  public var clearNotesBefore:FlxTypedSignal<(Float, Bool) -> Void> = new FlxTypedSignal<(Float, Bool) -> Void>();

  public dynamic function onClearNotesBefore(time:Float, completelyClear:Bool) {}

  public var clearNotesAfter:FlxTypedSignal<Float->Void> = new FlxTypedSignal<Float->Void>();

  public dynamic function onClearNotesAfter(time:Float) {}

  public var spawnNoteLua:FlxTypedSignal<(notes:FlxTypedGroup<Note>,
      dunceNote:Note) -> Void> = new FlxTypedSignal<(notes:FlxTypedGroup<Note>, dunceNote:Note) -> Void>();

  public dynamic function onSpawnNoteLua(notes:FlxTypedGroup<Note>, dunceNote:Note) {}

  public var spawnNoteHx:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

  public dynamic function onSpawnNoteHx(dunceNote:Note) {}

  public var spawnNoteLuaPost:FlxTypedSignal<(notes:FlxTypedGroup<Note>,
      dunceNote:Note) -> Void> = new FlxTypedSignal<(notes:FlxTypedGroup<Note>, dunceNote:Note) -> Void>();

  public dynamic function onSpawnNoteLuaPost(notes:FlxTypedGroup<Note>, dunceNote:Note) {}

  public var spawnNoteHxPost:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

  public dynamic function onSpawnNoteHxPost(dunceNote:Note) {}

  // Input Calls
  public var keyPressedPre:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

  public dynamic function onKeyPressedPre(key:Int) {}

  public var keyPressed:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

  public dynamic function onKeyPressed(key:Int) {}

  public var keyReleasedPre:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

  public dynamic function onKeyReleasedPre(key:Int) {}

  public var keyReleased:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

  public dynamic function onKeyReleased(key:Int) {}

  public var ghostTap:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

  public dynamic function onGhostTap(key:Int) {}

  public var noteMissPress:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

  public dynamic function onMissPress(key:Int) {}

  // StrumLine PlayState Calls
  public var playerNoteHit:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

  public dynamic function onPlayerNoteHit(note:Note) {}

  public var cpuNoteHit:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

  public dynamic function onCpuNoteHit(note:Note) {}

  public var notHoldingKey:FlxSignal;

  public dynamic function onNotHoldingKey() {}

  public var holdingKey:FlxSignal;

  public dynamic function onHoldingKey() {}

  // Actual Interally Use StrumLine Calls
  public var draw:FlxSignal;

  public dynamic function onDraw() {}

  public var drawPost:FlxSignal;

  public dynamic function onDrawPost() {}

  public var update:FlxSignal;

  public dynamic function onUpdate(elapsed:Float) {}

  public var updatePost:FlxSignal;

  public dynamic function onUpdatePost(elapsed:Float) {}

  public var revive:FlxSignal;

  public dynamic function onRevive() {}

  public var revivePost:FlxSignal;

  public dynamic function onRevivePost() {}

  public var kill:FlxSignal;

  public dynamic function onKill() {}

  public var killPost:FlxSignal;

  public dynamic function onKillPost() {}

  public var destroy:FlxSignal;

  public dynamic function onDestroy() {}

  public var destroyPost:FlxSignal;

  public dynamic function onDestroyPost() {}

  public function new()
  {
    clearFunctions(); // Functions need to be activated first.
  }

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
    onKeyPressedPre = function(key) {
    }
    onKeyPressed = function(key) {
    }
    onKeyReleasedPre = function(key) {
    }
    onKeyReleased = function(key) {
    }
    onGhostTap = function(key) {
    }
    onMissPress = function(key) {
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
  }
}
