package options.ui;

class UIToggle extends FlxSpriteGroup
{
  public var name:String;
  public var boxBG:FlxSprite;
  public var box:FlxSprite;
  public var line:FlxSprite;
  public var text:FlxText;
  public var label(get, set):String;
  public var key:String;

  public var checked(default, set):Bool = false;
  public var onClick:Void->Void = null;

  public var isSelected:Bool = false;

  public function new(x:Float, y:Float, label:String, ?textWid:Int = 100, ?callback:Void->Void)
  {
    super(x, y);

    boxBG = new FlxSprite();
    box = new FlxSprite();
    line = new FlxSprite();
    boxGraphic();
    boxBG.visible = false;
    add(boxBG);
    add(box);
    add(line);

    text = new FlxText(box.width + 4, 0, textWid, label);
    text.y += box.height / 2 - text.height / 2;
    add(text);

    this.onClick = callback;
  }

  public function boxGraphic()
  {
    boxBG.loadGraphic(Paths.image('ui/CheckBoxBG'), true, 150, 150);
    boxBG.animation.add('true', [0, 1, 2, 3, 4], 12, false);
    boxBG.animation.add('false', [4, 3, 2, 1, 0], 12, false);
    boxBG.animation.play('false');
    boxBG.antialiasing = ClientPrefs.data.antialiasing;

    box.loadGraphic(Paths.image('ui/CheckBox'), true, 150, 150);
    box.animation.add('true', [0, 1, 2, 3, 4], 12, false);
    box.animation.add('false', [4, 3, 2, 1, 0], 12, false);
    box.animation.play('false');
    box.antialiasing = ClientPrefs.data.antialiasing;

    line.loadGraphic(Paths.image('ui/CheckBoxLine'), true, 150, 150);
    line.animation.add('true', [0, 1, 2, 3, 4], 12, false);
    line.animation.add('false', [4, 3, 2, 1, 0], 12, false);
    line.animation.play('false');
    line.antialiasing = ClientPrefs.data.antialiasing;
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.mouse.justPressed || (utils.GeneralUtils.keyJustPressed(key) && isSelected))
    {
      var screenPos:FlxPoint = getScreenPosition(null, camera);
      var mousePos:FlxPoint = FlxG.mouse.getViewPosition(camera);
      if ((mousePos.x >= screenPos.x && mousePos.x < screenPos.x + width)
        && (mousePos.y >= screenPos.y && mousePos.y < screenPos.y + height))
      {
        checked = !checked;
        if (onClick != null) onClick();
      }
    }
  }

  function set_checked(v:Any)
  {
    var v:Bool = (v != null && v != false);
    box.animation.play(Std.string(v));
    line.animation.play(Std.string(v));
    boxBG.animation.play(Std.string(v));
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
