package options.ui;

class UIArrow extends FlxSpriteGroup
{
  public var name:String;
  public var arrowBG:AttachedSprite;
  public var arrow:FlxSprite;
  public var key:String;
  public var isSelected:Bool = false;
  public var onPressed:Void->Void;

  public function new(x:Float, y:Float, key:String = null, onPressed:Void->Void = null)
  {
    if (onPressed != null) this.onPressed = onPressed;
    super(x, y);

    arrowBG = new AttachedSprite('ui/ArrowBG');
    arrowBG.visible = false;
    add(arrowBG);

    arrow = new FlxSprite().loadGraphic(Paths.image('ui/Arrow'));
    arrow.antialiasing = ClientPrefs.data.antialiasing;
    add(arrow);

    arrowBG.sprTracker = arrow;
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    var screenPos:FlxPoint = getScreenPosition(null, camera);
    var mousePos:FlxPoint = FlxG.mouse.getViewPosition(camera);
    if (FlxG.mouse.justPressed || (isSelected && utils.GeneralUtils.keyJustPressed(key)))
    {
      if ((mousePos.x >= screenPos.x && mousePos.x < screenPos.x + width)
        && (mousePos.y >= screenPos.y && mousePos.y < screenPos.y + height))
      {
        if (onPressed != null) onPressed();
      }
    }
  }
}
