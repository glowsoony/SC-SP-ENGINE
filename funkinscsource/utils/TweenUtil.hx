package utils;

import flixel.tweens.FlxTween.FlxTweenManager;

class TweenUtil
{
  public static function pauseTween(tween:FlxTween):Void
  {
    if (tween != null)
    {
      tween.active = false;
    }
  }

  public static function resumeTween(tween:FlxTween):Void
  {
    if (tween != null)
    {
      tween.active = true;
    }
  }

  public static function createTween(manager:FlxTweenManager, Object:Dynamic, Values:Dynamic, Duration:Float, ?Options:TweenOptions):FlxTween
  {
    var tween:FlxTween = manager.tween(Object, Values, Duration, Options);
    tween.manager = manager;
    return tween;
  }

  public static function createTweenNum(manager:FlxTweenManager, FromValue:Float, ToValue:Float, Duration:Float = 1, ?Options:TweenOptions,
      ?TweenFunction:Float->Void):FlxTween
  {
    var tween:FlxTween = manager.num(FromValue, ToValue, Duration, Options, TweenFunction);
    tween.manager = manager;
    return tween;
  }

  public static function pauseTweensOf(Object:Dynamic, ?FieldPaths:Array<String>):Void
  {
    @:privateAccess
    FlxTween.globalManager.forEachTweensOf(Object, FieldPaths, pauseTween);
  }

  public static function resumeTweensOf(Object:Dynamic, ?FieldPaths:Array<String>):Void
  {
    @:privateAccess
    FlxTween.globalManager.forEachTweensOf(Object, FieldPaths, resumeTween);
  }
}
