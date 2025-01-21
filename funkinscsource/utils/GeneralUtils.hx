package utils;

class GeneralUtils
{
  public static function transformSpriteColor(sprite:FlxSprite, colors:Array<Int>)
    sprite.setColorTransform(colors[0], colors[1], colors[2], colors[3], colors[4], colors[5], colors[6]);

  public static function keyJustPressed(key:String):Bool
  {
    if (key == null) return false;
    return Reflect.getProperty(FlxG.keys.justPressed, key);
  }

  public static function keyPressed(key:String):Bool
  {
    if (key == null) return false;
    return Reflect.getProperty(FlxG.keys.pressed, key);
  }

  public static function keyJustReleased(key:String):Bool
  {
    if (key == null) return false;
    return Reflect.getProperty(FlxG.keys.justReleased, key);
  }

  public static function keyReleased(key:String):Bool
  {
    if (key == null) return false;
    return Reflect.getProperty(FlxG.keys.released, key);
  }

  public static function reflectSet(place:Dynamic, vari:String, value:Dynamic)
    Reflect.setProperty(place, vari, value);

  public static function reflectGet(place:Dynamic, vari:String):Dynamic
    return Reflect.getProperty(place, vari);

  public static function isReflect(isG:Bool = true, place:Dynamic, vari:String, ?value:Dynamic):Dynamic
  {
    final isSetResult:Bool = (!isG && reflectGet(place, vari) != null);
    if (isSetResult) reflectSet(place, vari, value);
    return (isG ? reflectGet(place, vari) != null : isSetResult);
  }

  public static function getPropertySplit(instance:Dynamic, variable:String)
  {
    final split:Array<String> = variable.split('.');
    if (split.length > 1)
    {
      var refelectedItem:Dynamic = null;

      refelectedItem = split[0];

      for (i in 1...split.length - 1)
      {
        refelectedItem = Reflect.getProperty(refelectedItem, split[i]);
      }
      return Reflect.getProperty(refelectedItem, split[split.length - 1]);
    }
    return Reflect.getProperty(instance, variable);
  }

  public static function setPropertySplit(instance:Dynamic, variable:String, value:Dynamic)
  {
    final split:Array<String> = variable.split('.');
    if (split.length > 1)
    {
      var refelectedItem:Dynamic = null;

      refelectedItem = split[0];

      for (i in 1...split.length - 1)
      {
        refelectedItem = Reflect.getProperty(refelectedItem, split[i]);
      }
      return Reflect.setProperty(refelectedItem, split[split.length - 1], value);
    }
    return Reflect.setProperty(instance, variable, value);
  }
}
