package objects.note;

import flixel.util.FlxSignal.FlxTypedSignal;
import backend.CustomArrayGroup;

class StrumLine extends FlxTypedGroup<StrumArrow>
{
  // Used in-game to control the scroll speed within a song
  public var scrollSpeed(default, set):Float = 1.0;
  public var allowScrollSpeedOverride:Bool = true;

  function set_scrollSpeed(value:Float):Float
  {
    var overrideSpeed:Float = PlayState.instance?.songSpeed ?? 1.0;
    scrollSpeed = allowScrollSpeedOverride ? overrideSpeed : value;
    return allowScrollSpeedOverride ? overrideSpeed : value;
  }

  public var notes:FlxTypedGroup<Note> = null;
  public var unspawnNotes:CustomArrayGroup<Note> = new CustomArrayGroup<Note>();
  public var isPixelNotes:Bool = false;

  public var allowOverrideCpuControl:Bool = true;
  public var cpuControlled:Bool = false;

  function set_cpuControlled(value:Bool):Bool
  {
    cpuControlled = value;
    if (PlayState.instance != null && allowOverrideCpuControl) cpuControlled = PlayState.instance.cpuControlled;
    return cpuControlled;
  }

  public var drawNotes:Bool = !((PlayState.SONG != null && PlayState.SONG.options.notITG) && ClientPrefs.getGameplaySetting('modchart'));
  public var noteKillOffset(default, set):Float = 350;

  function set_noteKillOffset(value:Float):Float
  {
    noteKillOffset = value;
    if (noteKillOffset != (noteKillOffset / scrollSpeed)) noteKillOffset /= scrollSpeed;
    return noteKillOffset;
  }

  public var playbackSpeed:Float = 1;
  public var calls:StrumLineCalls = new StrumLineCalls();

  public function new(strumLimit:Int = 0, noteLimit:Int = 0)
  {
    notes = new FlxTypedGroup<Note>(noteLimit);
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
    super(strumLimit);
  }

  public override function draw()
  {
    super.draw();
    if (drawNotes)
    {
      notes.cameras = cameras;
      notes.draw();
    }
  }

  public dynamic function setTextureStrumMember(member:Int, texture:String):String
    return members[member].texture = texture;

  public dynamic function setTexture(texture:String)
  {
    for (strum in members)
      strum.reloadNote(texture);

    for (note in notes)
      note.reloadNote(texture);
  }

  public dynamic function registerUnspawnedNotes()
  {
    if (unspawnNotes.isFirstValid())
    {
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
  }

  override public function destroy()
  {
    unspawnNotes.clear();
    calls.clear();
    notes = null;
    super.destroy();
  }

  public function invalidateNote(note:Note, unspawnedNotes:Bool):Void
  {
    note.invalidate();
    if (!unspawnedNotes) notes.remove(note, true);
    else
      unspawnNotes.remove(note);
    note.destroy();
    note = null;
  }
}

class StrumLineCalls
{
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

  public function new()
  {
    clearFunctions(); // Functions need to be activated first.
  }

  public function clearSignals()
  {
    noteHit.destroy();
    noteMissed.destroy();
    noteNotReady.destroy();
    spawnNoteLua.destroy();
    spawnNoteHx.destroy();
    spawnNoteLuaPost.destroy();
    spawnNoteHxPost.destroy();
    noteIsPixel.destroy();
    noteDeleted.destroy();
    clearNotesBefore.destroy();
    clearNotesAfter.destroy();
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
  }

  public function clear()
  {
    clearSignals();
    clearFunctions();
  }
}
