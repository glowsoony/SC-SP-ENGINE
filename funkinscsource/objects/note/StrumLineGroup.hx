package objects.note;

import openfl.events.KeyboardEvent;

class StrumLineGroup extends FlxTypedGroup<StrumLine>
{
  public function new()
  {
    super(0);
    addKeyListener();
  }

  public function onKeyPress(event:KeyboardEvent)
  {
    if (this.length == 0) return;
    for (strumLine in this)
    {
      if (strumLine == null) continue;
      strumLine.onKeyPress(event);
    }
  }

  public function onKeyRelease(event:KeyboardEvent)
  {
    if (this.length == 0) return;
    for (strumLine in this)
    {
      if (strumLine == null) continue;
      strumLine.onKeyRelease(event);
    }
  }

  public function addKeyListener()
  {
    FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
  }

  public function removeKeyListener()
  {
    FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
  }

  override public function destroy()
  {
    removeKeyListener();
    super.destroy();
  }
}
