package scfunkin.objects.note;

class HoldCoverGroup extends FlxTypedGroup<HoldCoverSprite>
{
  public var enabled:Bool = true;
  public var canSplash:Bool = false;
  public var isReady(get, never):Bool;

  function get_isReady():Bool
  {
    if (PlayState.instance != null)
    {
      return (!PlayState.instance.startingSong && !PlayState.instance.inCutscene && !PlayState.instance.inCinematic && PlayState.instance.generatedMusic);
    }
    return false;
  }

  public function new()
  {
    super(0);
  }

  public dynamic function setParentAndCreate(strumLine:StrumLine, amount:Int)
  {
    for (i in 0...amount)
    {
      addHold(i);
      this.members[i].parentStrum = strumLine.members[i];
    }
  }

  public var colors:Array<String> = ["Purple", "Blue", "Green", "Red"];

  public dynamic function addHold(i:Int)
  {
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
