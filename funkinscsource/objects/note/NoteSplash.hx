package objects.note;

import flixel.system.FlxAssets.FlxShader;
import openfl.Assets;
import shaders.RGBPalette;
import shaders.RGBPixelShader.RGBPixelShaderReference;
import states.editors.NoteSplashEditorState;

typedef NoteSplashData =
{
  disabled:Bool,
  texture:String,
  useGlobalShader:Bool, // breaks r/g/b/a but makes it copy default colors for your custom note
  useRGBShader:Bool,
  useNoteRGB:Bool,
  antialiasing:Bool,
  a:Float,
  ?r:FlxColor,
  ?g:FlxColor,
  ?b:FlxColor
}

typedef RGB =
{
  r:Null<Int>,
  g:Null<Int>,
  b:Null<Int>
}

typedef NoteSplashAnim =
{
  name:String,
  prefix:String,
  noteData:Int,
  indices:Array<Int>,
  offsets:Array<Float>,
  fps:Array<Int>
}

typedef NoteSplashConfig =
{
  animations:Map<String, NoteSplashAnim>,
  scale:Float,
  allowRGB:Bool,
  allowPixel:Bool,
  rgb:Array<Null<RGB>>
}

class NoteSplash extends FunkinSCSprite
{
  private var _textureLoaded:String = null;

  public var skin:String;
  public var config(default, set):NoteSplashConfig;

  public static var defaultNoteSplash:String = "noteSplashes/noteSplashes";
  public static var configs:Map<String, NoteSplashConfig> = new Map();

  private var string1NoteSkin:String = null;
  private var string2NoteSkin:String = null;

  public var containedPixelTexture(get, never):Bool;

  function get_containedPixelTexture():Bool
  {
    var isPixel:Bool = (skin.contains('pixel') || babyArrow.texture.contains('pixel') || styleChoice.contains('pixel'));
    return isPixel;
  }

  public var opponentSplashes:Bool = false;
  public var styleChoice:String = '';

  public var noteDataMap:Map<Int, String> = new Map();
  public var rgbShader:RGBPixelShaderReference;

  public var babyArrow:StrumArrow;
  public var noteData:Int = 0;

  public var copyX:Bool = true;
  public var copyY:Bool = true;
  public var inEditor:Bool = false;

  public var neededOffsetCorrection:Bool = false;
  public var spawned:Bool = false;

  public function new(?x:Float, ?y:Float, ?splash:String, ?opponentSplashes:Bool = false)
  {
    super(x, y);

    this.opponentSplashes = opponentSplashes;

    if (splash == null) splash = getTexture(opponentSplashes);

    rgbShader = new RGBPixelShaderReference();
    shader = rgbShader.shader;
    loadSplash(splash, opponentSplashes);
  }

  public var maxAnims(default, set):Int = 0;

  public function loadSplash(?splash:String, ?opponentSplashes:Bool = false)
  {
    config = null;
    maxAnims = 0;

    var stop:Bool = false;
    var splashSkin:String = splash;
    try
    {
      frames = Paths.getSparrowAtlas(splashSkin);
      this.skin = splashSkin;
    }
    catch (e)
    {
      splashSkin = getTexture(opponentSplashes);
      this.skin = splashSkin;
      try
      {
        frames = Paths.getSparrowAtlas(splashSkin);
      }
      catch (e)
      {
        splashSkin = defaultNoteSplash + getSplashSkinPostfix();
        this.skin = splashSkin; // Fail Safe
        try
        {
          frames = Paths.getSparrowAtlas(skin);
        }
        catch (e)
        {
          active = visible = false;
          stop = true;
        }
      }
    }

    var configPath:String = chooseSplashPathJson(skin);

    if (!stop && configPath != null && configPath.length > 0)
    {
      if (configs.exists(configPath))
      {
        this.config = configs.get(configPath);
        for (anim in this.config.animations)
        {
          if (anim.noteData % Note.colArray.length == 0) maxAnims++;
        }
        return;
      }
      else if (Paths.fileExists(configPath, TEXT))
      {
        var parseItem = Paths.getTextFromFile(configPath);
        if (parseItem != null)
        {
          var config:Dynamic = haxe.Json.parse(parseItem);

          if (config != null)
          {
            var tempConfig:NoteSplashConfig =
              {
                animations: new Map(),
                scale: config.scale,
                allowRGB: config.allowRGB,
                allowPixel: config.allowPixel,
                rgb: config.rgb
              }
            for (i in Reflect.fields(config.animations))
            {
              var anim:NoteSplashAnim = Reflect.field(config.animations, i);
              tempConfig.animations.set(i, anim);
              if (anim.noteData % Note.colArray.length == 0) maxAnims++;
            }

            this.config = tempConfig;
            configs.set(configPath, this.config);
            return;
          }
        }
      }
    }

    configPath = chooseSplashPathTxt(skin);

    // Splashes with no json
    var tempConfig:NoteSplashConfig = createConfig();
    var anim:String = 'note splash';
    var fps:Array<Null<Int>> = [22, 26];
    var offsets:Array<Array<Float>> = [[0, 0]];
    if (Paths.fileExists(configPath, TEXT)) // Backwards compatibility with 0.7 splash txts
    {
      var configFile:Array<String> = CoolUtil.listFromString(Paths.getTextFromFile('$path.txt'));
      if (configFile.length > 0)
      {
        anim = configFile[0];
        if (configFile.length > 1)
        {
          var framerates:Array<String> = configFile[1].split(' ');
          fps = [Std.parseInt(framerates[0]), Std.parseInt(framerates[1])];
          if (fps[0] == null) fps[0] = 22;
          if (fps[1] == null) fps[1] = 26;
          if (configFile.length > 2)
          {
            offsets = [];
            for (i in 2...configFile.length)
            {
              if (configFile[i].trim() != '')
              {
                var animOffs:Array<String> = configFile[i].split(' ');
                var x:Float = Std.parseFloat(animOffs[0]);
                var y:Float = Std.parseFloat(animOffs[1]);
                if (Math.isNaN(x)) x = 0;
                if (Math.isNaN(y)) y = 0;
                offsets.push([x, y]);
              }
            }
          }
        }
      }
    }
    var failedToFind:Bool = false;
    while (true)
    {
      for (v in Note.colArray)
      {
        if (!checkForAnim('$anim $v ${maxAnims + 1}'))
        {
          failedToFind = true;
          break;
        }
      }

      if (failedToFind) break;
      maxAnims++;
    }

    for (animNum in 0...maxAnims)
    {
      for (i => col in Note.colArray)
      {
        var data:Int = i % Note.colArray.length + (animNum * Note.colArray.length);
        var name:String = animNum > 0 ? '$col' + (animNum + 1) : col;
        var offset:Array<Float> = offsets[FlxMath.wrap(data, 0, Std.int(offsets.length - 1))];
        addAnimationToConfig(tempConfig, 1, name, '$anim $col ${animNum + 1}', fps, offset, [], data);
      }
    }
    this.config = tempConfig;
    configs.set(configPath, this.config);
  }

  function chooseSplashPathJson(newSkin:String):String
  {
    if (Paths.fileExists('images/noteSplashes/$newSkin.json', TEXT)) return 'images/noteSplashes/$newSkin.json';
    if (Paths.fileExists('images/$newSkin.json', TEXT)) return 'images/$newSkin.json';
    if (Paths.fileExists('$newSkin.json', TEXT)) return '$newSkin.json';
    Debug.logInfo('Failed to locate $newSkin.json, returning nothing');
    return null;
  }

  function chooseSplashPathTxt(newSkin:String):String
  {
    if (Paths.fileExists('images/noteSplashes/$newSkin.txt', TEXT)) return 'images/noteSplashes/$newSkin.txt';
    if (Paths.fileExists('images/$newSkin.txt', TEXT)) return 'images/$newSkin.txt';
    if (Paths.fileExists('$newSkin.txt', TEXT)) return '$newSkin.txt';
    Debug.logInfo('Failed to locate $newSkin.txt, returning nothing');
    return null;
  }

  function getTexture(?opponentSplashes:Bool = false, ?note:Note = null):String
  {
    var finalSplashSkin:String = null;
    if (PlayState.instance != null)
    {
      if (ClientPrefs.getGameplaySetting('opponent')
        && !ClientPrefs.data.middleScroll) styleChoice = opponentSplashes ? PlayState.instance.bfStrumStyle : PlayState.instance.dadStrumStyle;
      else
        styleChoice = opponentSplashes ? PlayState.instance.bfStrumStyle : PlayState.instance.dadStrumStyle;

      string1NoteSkin = "noteSplashes-" + styleChoice;
      string2NoteSkin = "notes/noteSplashes-" + styleChoice;
    }
    var firstPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string1NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string1NoteSkin.png'));
    var secondPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string2NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string2NoteSkin.png'));
    if (note != null && note.noteSplashData.texture != null) finalSplashSkin = note.noteSplashData.texture;
    else
    {
      if (firstPath) finalSplashSkin = "noteSplashes-" + styleChoice;
      else if (secondPath) finalSplashSkin = "notes/noteSplashes-" + styleChoice;
      else if (PlayState.SONG != null)
      {
        if (PlayState.SONG.options.splashSkin != null
          && PlayState.SONG.options.splashSkin.length > 0) finalSplashSkin = PlayState.SONG.options.splashSkin;
        else
          finalSplashSkin = PlayState.SONG.options.disableSplashRGB ? 'noteSplashes_vanilla' : defaultNoteSplash + getSplashSkinPostfix();
      }
    }
    if (finalSplashSkin == null) finalSplashSkin = defaultNoteSplash + getSplashSkinPostfix();
    return finalSplashSkin;
  }

  public dynamic function spawnSplashNote(?x:Float = 0, ?y:Float = 0, ?note:Note, ?noteData:Null<Int>, ?randomize:Bool = true)
  {
    if (note != null && note.noteSplashData.disabled) return;

    aliveTime = 0;

    if (!inEditor
      && getTexture(this.opponentSplashes, note) != null) loadSplash(getTexture(this.opponentSplashes, note), this.opponentSplashes);

    setPosition(x, y);

    if (babyArrow != null) setPosition(babyArrow.x - Note.swagWidth * 0.95,
      babyArrow.y - Note.swagWidth); // To prevent it from being misplaced for one game tick

    if (note != null) noteData = note.noteData;

    if (randomize && maxAnims > 1) noteData = noteData % Note.colArray.length + (FlxG.random.int(0, maxAnims - 1) * Note.colArray.length);

    this.noteData = noteData;
    var anim:String = playDefaultAnim();

    var anim:String = null;
    function playDefaultAnim(playAnim:Bool = true)
    {
      var animation:String = noteDataMap.get(noteData);
      if (animation != null && this.animation.exists(animation))
      {
        if (playAnim) this.animation.play(animation);
        anim = animation;
      }
      else
        visible = false;
    }

    playDefaultAnim();

    var tempShader:RGBPalette = null;
    if (config.allowRGB)
    {
      Note.initializeGlobalRGBShader(noteData % Note.colArray.length);

      if (inEditor
        || (note == null || note.noteSplashData.useRGBShader)
        && (PlayState.SONG == null || !PlayState.SONG.options.disableSplashRGB))
      {
        tempShader = new RGBPalette();
        // If Note RGB is enabled:
        if ((note == null || !note.noteSplashData.useGlobalShader) || inEditor)
        {
          var colors = config.rgb;
          if (colors != null)
          {
            for (i in 0...colors.length)
            {
              if (i > 2) break;

              var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData % Note.colArray.length];
              if (PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[noteData % Note.colArray.length];
              var rgb = colors[i];
              if (rgb == null)
              {
                if (i == 0) tempShader.r = arr[0];
                else if (i == 1) tempShader.g = arr[1];
                else if (i == 2) tempShader.b = arr[2];
                continue;
              }

              var r:Null<Int> = rgb.r;
              var g:Null<Int> = rgb.g;
              var b:Null<Int> = rgb.b;

              if (r == null || Math.isNaN(r) || r < 0) r = arr[0];
              if (g == null || Math.isNaN(g) || g < 0) g = arr[1];
              if (b == null || Math.isNaN(b) || b < 0) b = arr[2];

              var color:FlxColor = FlxColor.fromRGB(r, g, b);
              if (i == 0) tempShader.r = color;
              else if (i == 1) tempShader.g = color;
              else if (i == 2) tempShader.b = color;
            }
          }
          else
          {
            tempShader.copyValues(Note.globalRgbShaders[noteData % Note.colArray.length]);
            if (note != null && note.noteSplashData.useNoteRGB) tempShader = note.rgbShader.parent;
          }

          if (note != null)
          {
            if (note.noteSplashData.r != -1) tempShader.r = note.noteSplashData.r;
            if (note.noteSplashData.g != -1) tempShader.g = note.noteSplashData.g;
            if (note.noteSplashData.b != -1) tempShader.b = note.noteSplashData.b;
          }
        }
        else
          tempShader.copyValues(Note.globalRgbShaders[noteData % Note.colArray.length]);
      }
    }
    if (config.allowPixel) rgbShader.containsPixel = containedPixelTexture || PlayState.isPixelStage;
    if (!config.allowPixel) rgbShader.containsPixel = false;
    rgbShader.copyValues(tempShader);
    if (!config.allowPixel) rgbShader.pixelSize = 1;

    offset.set(10, 10);
    var conf:NoteSplashAnim = config.animations.get(anim);
    var offsets:Array<Float> = [0, 0];
    if (conf != null) offsets = conf.offsets;

    if (offsets != null)
    {
      offset.x += offsets[0];
      offset.y += offsets[1];
    }
    animation.finishCallback = function(name:String) {
      kill();
      spawned = false;
    };

    if (!ClientPrefs.data.splashAlphaAsStrumAlpha) alpha = ClientPrefs.data.splashAlpha;
    if (note != null) alpha = note.noteSplashData.a;

    antialiasing = ClientPrefs.data.antialiasing;
    if (note != null) antialiasing = note.noteSplashData.antialiasing;
    if ((PlayState.isPixelStage && config.allowPixel) || containedPixelTexture) antialiasing = false;

    var minFps:Int = 22;
    var maxFps:Int = 26;
    if (conf != null)
    {
      minFps = conf.fps[0];
      if (minFps < 0) minFps = 0;
      maxFps = conf.fps[1];
      if (maxFps < 0) maxFps = 0;
    }

    if (animation.curAnim != null) animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
    spawned = true;
  }

  public function playDefaultAnim()
  {
    var anim:String = noteDataMap.get(noteData);
    if (anim != null && animation.exists(anim)) animation.play(anim, true);

    return anim;
  }

  public static function getSplashSkinPostfix()
  {
    var skin:String = '';
    if (ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin) skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '-');
    return skin;
  }

  function checkForAnim(anim:String)
  {
    var animFrames = [];
    @:privateAccess
    animation.findByPrefix(animFrames, anim); // adds valid frames to animFrames

    return animFrames.length > 0;
  }

  var aliveTime:Float = 0;

  static var buggedKillTime:Float = 0.5; // automatically kills note splashes if they break to prevent it from flooding your HUD

  override function update(elapsed:Float)
  {
    if (spawned)
    {
      aliveTime += elapsed;
      if (animation.curAnim == null && aliveTime >= buggedKillTime)
      {
        kill();
        spawned = false;
      }
    }

    if (babyArrow != null)
    {
      if (copyX) x = babyArrow.x - Note.swagWidth * 0.95;

      if (copyY) y = babyArrow.y - Note.swagWidth;
    }
    super.update(elapsed);
  }

  public static function createConfig():NoteSplashConfig
  {
    return {
      animations: new Map(),
      scale: 1,
      allowRGB: true,
      allowPixel: true,
      rgb: null
    }
  }

  public static function addAnimationToConfig(config:NoteSplashConfig, scale:Float, name:String, prefix:String, fps:Array<Int>, offsets:Array<Float>,
      indices:Array<Int>, noteData:Int):NoteSplashConfig
  {
    if (config == null) config = createConfig();
    config.animations.set(name,
      {
        name: name,
        noteData: noteData,
        prefix: prefix,
        indices: indices,
        offsets: offsets,
        fps: fps
      });
    config.scale = scale;
    return config;
  }

  function set_config(value:NoteSplashConfig):NoteSplashConfig
  {
    if (value == null) value = createConfig();

    @:privateAccess
    animation.clearAnimations();
    noteDataMap.clear();

    for (i in value.animations)
    {
      var key:String = i.name;
      if (i.prefix.length > 0)
      {
        if (i.indices != null && i.indices.length > 0 && key != null && key.length > 0) animation.addByIndices(key, i.prefix, i.indices, "", i.fps[1], false);
        else
          animation.addByPrefix(key, i.prefix, i.fps[1], false);
        noteDataMap.set(i.noteData, key);
      }
    }
    scale.set(value.scale, value.scale);
    return config = value;
  }

  function set_maxAnims(value:Int)
  {
    if (value > 0) noteData = Std.int(FlxMath.wrap(noteData, 0, (value * Note.colArray.length) - 1));
    else
      noteData = 0;
    return maxAnims = value;
  }
}
