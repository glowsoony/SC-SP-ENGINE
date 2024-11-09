package objects.note;

import flixel.util.FlxSignal.FlxTypedSignal;
import backend.CustomArrayGroup;

class Strumline extends FlxSpriteGroup
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
  public var strumLineNotes:FlxTypedGroup<StrumArrow> = new FlxTypedGroup<StrumArrow>();
  public var isPixelNotes:Bool = false;

  public var allowOverrideCpuControl:Bool = true;
  public var cpuControlled:Bool = false;

  function set_cpuControlled(value:Bool):Bool
  {
    cpuControlled = value;
    if (PlayState.instance != null && allowOverrideCpuControl) cpuControlled = PlayState.instance.cpuControlled;
    return cpuControlled;
  }

  public var noteHit:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
  public var noteMissed:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
  public var noteDeleted:FlxTypedSignal<(Note, Bool) -> Void> = new FlxTypedSignal<(Note, Bool) -> Void>();
  public var noteNotReady:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

  public function new(x:Float, y:Float, noteLimit:Int = 0, strumLimit:Int = 0)
  {
    notes = new FlxTypedGroup<Note>(noteLimit);
    strumLineNotes = new FlxTypedGroup<StrumArrow>(strumLimit);
    noteDeleted.add((daNote:Note, isUnspawn:Bool) -> {
      invalidateNote(daNote, isUnspawn);
    });
    noteNotReady.add((daNote:Note) -> {
      daNote.canBeHit = false;
      daNote.wasGoodHit = false;
    });
    add(strumLineNotes);
    add(notes);
    super(x, y);
  }

  public dynamic function setTextureMember(member:Int, texture:String):String
    return strumLineNotes.members[member].texture = texture;

  public dynamic function setTexture(texture:String)
  {
    for (strum in strumLineNotes.members)
      strum.texture = texture;
  }

  public var spawnNoteLua:FlxTypedSignal<(notes:FlxTypedGroup<Note>,
      dunceNote:Note) -> Void> = new FlxTypedSignal<(notes:FlxTypedGroup<Note>, dunceNote:Note) -> Void>();
  public var spawnNoteHx:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

  public var spawnNoteLuaPost:FlxTypedSignal<(notes:FlxTypedGroup<Note>,
      dunceNote:Note) -> Void> = new FlxTypedSignal<(notes:FlxTypedGroup<Note>, dunceNote:Note) -> Void>();
  public var spawnNoteHxPost:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

  public dynamic function registerUnspawnedNotes()
  {
    if (unspawnNotes.isFirstValid())
    {
      while (unspawnNotes.validTime(playbackRate))
      {
        final dunceNote:Note = unspawnNotes.byIndex(0);
        notes.insert(0, dunceNote);
        dunceNote.spawned = true;

        spawnNoteLua.dispatch(notes, dunceNote);
        spawnNoteHx.dispath(dunceNote);

        unspawnNotes.spliceIndexOf(dunceNote, 1);

        spawnNoteLuaPost.dispatch(notes, dunceNote);
        spawnNoteHxPost.dispath(dunceNote);
      }
    }
  }

  public var noteIsPixel:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

  public dynamic function updateNoteData(playbackRate:Float, noteKillOffset:Float)
  {
    if (notes.length > 0)
    {
      notes.forEachAlive(function(daNote:Note) {
        final strum:StrumArrow = strumLineNotes.members[daNote.noteData];
        if (daNote.allowStrumFollow) daNote.followStrumArrow(strum, daNote.noteScrollSpeed / playbackRate);

        noteIsPixel.dispatch(daNote);
        noteHit.dispatch(daNote);

        if (daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumArrow(strum);

        // Kill extremely late notes and cause misses

        if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
        {
          if (ClientPrefs.data.vanillaStrumAnimations)
          {
            if (!daNote.mustPress)
            {
              if ((daNote.isSustainNote && daNote.isHoldEnd) || !daNote.isSustainNote) strum.playAnim('static', true);
            }
            else
            {
              if (daNote.isSustainNote && daNote.isHoldEnd) strum.playAnim('static', true);
            }
          }

          noteMissed.dispatch(daNote);
          if (daNote.allowDeleteAndMiss) noteDeleted.dispatch(daNote, false);
        }
      });
    }
    else
      notes.forEachAlive(function(daNote:Note) noteNotReady.distpatch(daNote));
  }

  override public function destroy()
  {
    unspawnNotes.clear();
    notes = null;
    for (signal in [
      noteHit,
      noteMissed,
      noteDeleted,
      noteNotReady,
      spawnNoteLua,
      spawnNoteHx,
      spawnNoteLuaPost,
      spawnNoteHxPost,
      noteIsPixel
    ])
    {
      signal.removeAll();
      signal.cancel();
    }
    super.destroy();
  }

  public function invalidateNote(note:Note, unspawnedNotes:Bool):Void
  {
    if (note == null) return;
    note.ignoreNote = true;
    note.active = false;
    note.visible = false;
    note.kill();
    if (!unspawnedNotes) notes.remove(note, true);
    else
      unspawnNotes.remove(note);
    note.destroy();
    note = null;
  }
}
