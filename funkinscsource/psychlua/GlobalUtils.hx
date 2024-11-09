package psychlua;

class GlobalUtils
{
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
}
