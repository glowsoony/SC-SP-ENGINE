package scfunkin.utils;

import openfl.display.BlendMode;
import scfunkin.utils.*;

enum abstract AffixType(String) from String to String
{
  var NONE = 'None';
  var SUFFIXED = 'Suffixed';
  var PREFIXED = 'Prefixed';
  var CIRCUMFIXED = 'Circumfixed';
  var FORMATTED_SUFFIX = 'Formatted Suffix';
  var FORMATTED_PREFIX = 'Formatted Prefix';
  var FORMATTED_CIRCUMFIX = 'Formatted Circumfix';
}

class GenericUtil
{
  public static function transformSpriteColor(sprite:FlxSprite, colors:Array<Int>)
    sprite.setColorTransform(colors[0], colors[1], colors[2], colors[3], colors[4], colors[5], colors[6]);

  public static function formatVariableOption(tag:String, option:AffixType = NONE, ?suffix:String = null, ?prefix:String = null):String
  {
    final originalTag:String = tag;
    var externalSuffix:String = suffix == null ? '' : suffix;
    var externalPrefix:String = prefix == null ? '' : prefix;
    switch (option)
    {
      case NONE:
        final finalTag:String = originalTag;
        return finalTag;
      case SUFFIXED, FORMATTED_SUFFIX:
        final finalTag:String = option == FORMATTED_SUFFIX ? formatVariable(suffix + originalTag) : suffix + originalTag;
        return finalTag;
      case PREFIXED, FORMATTED_PREFIX:
        final finalTag:String = option == FORMATTED_PREFIX ? formatVariable(originalTag + prefix) : originalTag + prefix;
        return finalTag;
      case CIRCUMFIXED, FORMATTED_CIRCUMFIX:
        final finalTag:String = option == FORMATTED_CIRCUMFIX ? formatVariable(suffix + originalTag + prefix) : suffix + originalTag + prefix;
        return finalTag;
      default:
        return "";
    }
    return null;
  }

  public static function formatVariable(tag:String)
    return tag.trim().replace(' ', '_').replace('.', '');

  public static function checkVariable(start:String, end:String, formatType:String = "both")
  {
    formatType = formatType.toLowerCase();
    if (!start.startsWith(end))
    {
      switch (formatType)
      {
        case "both", "both-reverse":
          switch (formatType)
          {
            case "both":
              start = formatVariable(end + start);
            case "both-reverse":
              start = formatVariable(start + end);
          }
        case "endformat-start":
          start = formatVariable(end) + start;
        case "end-startformat":
          start = end + formatVariable(start);
        case "startformat-end":
          start = formatVariable(start) + end;
        case "start-formatend":
          start = start + formatVariable(end);
      }
      return start;
    }
    return formatVariable(start);
  }

  public static function getBuildTarget():String
  {
    #if windows
    #if x86_BUILD
    return 'windows_x86';
    #else
    return 'windows';
    #end
    #elseif linux
    return 'linux';
    #elseif mac
    return 'mac';
    #elseif hl
    return 'hashlink';
    #elseif (html5 || emscripten || nodejs || winjs || electron)
    return 'browser';
    #elseif android
    return 'android';
    #elseif webos
    return 'webos';
    #elseif tvos
    return 'tvos';
    #elseif watchos
    return 'watchos';
    #elseif air
    return 'air';
    #elseif flash
    return 'flash';
    #elseif (ios || iphonesim)
    return 'ios';
    #elseif neko
    return 'neko';
    #elseif switch
    return 'switch';
    #else
    return 'unknown';
    #end
  }

  // buncho string stuffs
  public static function getTweenTypeByString(?type:String = '')
  {
    switch (type.toLowerCase().trim())
    {
      case 'backward':
        return FlxTweenType.BACKWARD;
      case 'looping', 'loop':
        return FlxTweenType.LOOPING;
      case 'persist':
        return FlxTweenType.PERSIST;
      case 'pingpong':
        return FlxTweenType.PINGPONG;
    }
    return FlxTweenType.ONESHOT;
  }

  public static function getTweenEaseByString(?ease:String = '')
  {
    switch (ease.toLowerCase().trim())
    {
      case 'backin':
        return EaseUtil.backIn;
      case 'backinout':
        return EaseUtil.backInOut;
      case 'backout':
        return EaseUtil.backOut;
      case 'backoutin':
        return EaseUtil.backOutIn;
      case 'bounce':
        return EaseUtil.bounce;
      case 'bouncein':
        return EaseUtil.bounceIn;
      case 'bounceinout':
        return EaseUtil.bounceInOut;
      case 'bounceout':
        return EaseUtil.bounceOut;
      case 'bounceoutin':
        return EaseUtil.bounceOutIn;
      case 'bell':
        return EaseUtil.bell;
      case 'circin':
        return EaseUtil.circIn;
      case 'circinout':
        return EaseUtil.circInOut;
      case 'circout':
        return EaseUtil.circOut;
      case 'circoutin':
        return EaseUtil.circOutIn;
      case 'cubein':
        return EaseUtil.cubeIn;
      case 'cubeinout':
        return EaseUtil.cubeInOut;
      case 'cubeout':
        return EaseUtil.cubeOut;
      case 'cubeoutin':
        return EaseUtil.cubeOutIn;
      case 'elasticin':
        return EaseUtil.elasticIn;
      case 'elasticinout':
        return EaseUtil.elasticInOut;
      case 'elasticout':
        return EaseUtil.elasticOut;
      case 'elasticoutin':
        return EaseUtil.elasticOutIn;
      case 'expoin':
        return EaseUtil.expoIn;
      case 'expoinout':
        return EaseUtil.expoInOut;
      case 'expoout':
        return EaseUtil.expoOut;
      case 'expooutin':
        return EaseUtil.expoOutIn;
      case 'inverse':
        return EaseUtil.inverse;
      case 'instant':
        return EaseUtil.instant;
      case 'pop':
        return EaseUtil.pop;
      case 'popelastic':
        return EaseUtil.popElastic;
      case 'pulse':
        return EaseUtil.pulse;
      case 'pulseelastic':
        return EaseUtil.pulseElastic;
      case 'quadin':
        return EaseUtil.quadIn;
      case 'quadinout':
        return EaseUtil.quadInOut;
      case 'quadout':
        return EaseUtil.quadOut;
      case 'quadoutin':
        return EaseUtil.quadOutIn;
      case 'quartin':
        return EaseUtil.quartIn;
      case 'quartinout':
        return EaseUtil.quartInOut;
      case 'quartout':
        return EaseUtil.quartOut;
      case 'quartoutin':
        return EaseUtil.quartOutIn;
      case 'quintin':
        return EaseUtil.quintIn;
      case 'quintinout':
        return EaseUtil.quintInOut;
      case 'quintout':
        return EaseUtil.quintOut;
      case 'quintoutin':
        return EaseUtil.quintOutIn;
      case 'sinein':
        return EaseUtil.sineIn;
      case 'sineinout':
        return EaseUtil.sineInOut;
      case 'sineout':
        return EaseUtil.sineOut;
      case 'sineoutin':
        return EaseUtil.sineOutIn;
      case 'spike':
        return EaseUtil.spike;
      case 'smoothstepin':
        return EaseUtil.smoothStepIn;
      case 'smoothstepinout':
        return EaseUtil.smoothStepInOut;
      case 'smoothstepout':
        return EaseUtil.smoothStepOut;
      case 'smootherstepin':
        return EaseUtil.smootherStepIn;
      case 'smootherstepinout':
        return EaseUtil.smootherStepInOut;
      case 'smootherstepout':
        return EaseUtil.smootherStepOut;
      case 'tap':
        return EaseUtil.tap;
      case 'tapelastic':
        return EaseUtil.tapElastic;
      case 'tri':
        return EaseUtil.tri;
    }
    return EaseUtil.linear;
  }

  public static function blendModeFromString(blend:String):BlendMode
  {
    switch (blend.toLowerCase().trim())
    {
      case 'add':
        return ADD;
      case 'alpha':
        return ALPHA;
      case 'darken':
        return DARKEN;
      case 'difference':
        return DIFFERENCE;
      case 'erase':
        return ERASE;
      case 'hardlight':
        return HARDLIGHT;
      case 'invert':
        return INVERT;
      case 'layer':
        return LAYER;
      case 'lighten':
        return LIGHTEN;
      case 'multiply':
        return MULTIPLY;
      case 'overlay':
        return OVERLAY;
      case 'screen':
        return SCREEN;
      case 'shader':
        return SHADER;
      case 'subtract':
        return SUBTRACT;
    }
    return NORMAL;
  }

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

  public static function isReflect(isG:Bool = true, place:Dynamic, vari:String, ?value:Dynamic):Dynamic
  {
    final isSetResult:Bool = (!isG && Reflect.getProperty(place, vari) != null);
    if (isSetResult) Reflect.setProperty(place, vari, value);
    return (isG ? Reflect.getProperty(place, vari) != null : isSetResult);
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
