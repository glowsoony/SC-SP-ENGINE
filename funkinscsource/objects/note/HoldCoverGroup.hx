package objects.note;

class HoldCoverGroup extends FlxTypedSpriteGroup<HoldCoverSprite>
{
  public var enabled:Bool = true;
  public var isPlayer:Bool = false;
  public var canSplash:Bool = false;
  public var isReady(get, never):Bool;

  function get_isReady():Bool
  {
    if (PlayState.instance != null)
    {
      return (PlayState.instance.strumLineNotes != null
        && PlayState.instance.strumLineNotes.members.length > 0
        && !PlayState.instance.startingSong
        && !PlayState.instance.inCutscene
        && !PlayState.instance.inCinematic
        && PlayState.instance.generatedMusic);
    }
    return false;
  }

  public function new(enabled:Bool, isPlayer:Bool, canSplash:Bool = false)
  {
    this.enabled = enabled;
    this.isPlayer = isPlayer;
    this.canSplash = canSplash;
    super(0, 0, 4);
    for (i in 0...maxSize)
      addHolds(i);
  }

  public dynamic function setParent()
  {
    for (i in 0...maxSize)
    {
      if (PlayState.instance != null) this.members[i].parentStrum = PlayState.instance.strumLineNotes.members[isPlayer ? i + 4 : i];
    }
  }

  public dynamic function addHolds(i:Int)
  {
    final colors:Array<String> = ["Purple", "Blue", "Green", "Red"];
    final hcolor:String = colors[i];
    final hold:HoldCoverSprite = new HoldCoverSprite();
    hold.initFrames(i, hcolor);
    hold.initAnimations(i, hcolor);
    hold.boom = false;
    hold.isPlaying = false;
    hold.visible = false;
    hold.activatedSprite = enabled;
    hold.spriteId = '$hcolor-$i';
    hold.spriteIntID = i;
    this.add(hold);
  }

  public dynamic function spawnOnNoteHit(note:Note):Void
  {
    final noteData:Int = note.noteData;
    final isSus:Bool = note.isSustainNote;
    final isHoldEnd:Bool = note.isHoldEnd;
    if (enabled && isReady)
    {
      if (isSus)
      {
        this.members[noteData].affectSplash(HOLDING, noteData, note);
        if (isHoldEnd)
        {
          if (canSplash) this.members[noteData].affectSplash(SPLASHING, noteData);
          else
            this.members[noteData].affectSplash(DONE, noteData);
        }
      }
    }
  }

  public dynamic function despawnOnMiss(direction:Int, ?note:Note = null):Void
  {
    final noteData:Int = (note != null ? note.noteData : direction);
    if (enabled && isReady) this.members[noteData].affectSplash(STOP, noteData, note);
  }

  public dynamic function updateHold(elapsed:Float):Void
  {
    if (enabled && isReady) {}
  }
}
