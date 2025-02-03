package scfunkin.backend.ui;

class PsychUICheckBoxTest extends FlxSpriteGroup
{
  public static final CLICK_EVENT = 'checkbox_click';

  public var name:String;
  public var box:FlxSprite;
  public var line:FlxSprite;
  public var text:FlxText;
  public var label(get, set):String;

  public var checked(default, set):Bool = false;
  public var onClick:Void->Void = null;

  public function new(x:Float, y:Float, label:String, ?textWid:Int = 100, ?callback:Void->Void)
  {
    super(x, y);

    box = new FlxSprite();
    line = new FlxSprite();
    boxGraphic();
    add(box);
    add(line);

    text = new FlxText(box.width + 4, 0, textWid, label);
    text.y += box.height / 2 - text.height / 2;
    add(text);

    this.onClick = callback;
  }

  public function boxGraphic()
  {
    box.loadGraphic(Paths.image('ui/CheckBoxes'), true, 150, 150);
    box.animation.add('true', [0, 1, 2, 3, 4], 12, false);
    box.animation.add('false', [4, 3, 2, 1, 0], 12, false);
    box.animation.play('false');

    line.loadGraphic(Paths.image('ui/CheckBoxLines'), true, 150, 150);
    line.animation.add('true', [0, 1, 2, 3, 4], 12, false);
    line.animation.add('false', [4, 3, 2, 1, 0], 12, false);
    line.animation.play('false');
  }

  public var broadcastCheckBoxEvent:Bool = true;

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.mouse.justPressed)
    {
      var screenPos:FlxPoint = getScreenPosition(null, camera);
      var mousePos:FlxPoint = FlxG.mouse.getViewPosition(camera);
      if ((mousePos.x >= screenPos.x && mousePos.x < screenPos.x + width)
        && (mousePos.y >= screenPos.y && mousePos.y < screenPos.y + height))
      {
        checked = !checked;
        if (onClick != null) onClick();
        if (broadcastCheckBoxEvent) PsychUIEventHandler.event(CLICK_EVENT, this);
      }
    }
  }

  function set_checked(v:Any)
  {
    var v:Bool = (v != null && v != false);
    box.animation.play(Std.string(v));
    line.animation.play(Std.string(v));
    return (checked = v);
  }

  function get_label():String
  {
    return text.text;
  }

  function set_label(v:String):String
  {
    return (text.text = v);
  }
}
