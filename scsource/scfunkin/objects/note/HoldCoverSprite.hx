package scfunkin.objects.note;

import openfl.Assets;
import scfunkin.objects.note.Note;
import scfunkin.shaders.RGBPalette;
import scfunkin.shaders.RGBPixelShader.RGBPixelShaderReference;
import scfunkin.utils.LuaUtil;

// Most of the Original code from Mr.Bruh (mr.bruh69)
// Ported to haxe and edited by me (glowsoony)

typedef HoldCoverData =
{
  texture:String,
  useRGBShader:Bool,
  r:FlxColor,
  g:FlxColor,
  b:FlxColor,
  a:Int
}

enum abstract HoldCoverStep(String) to String from String
{
  var STOP = 'Stop';
  var DONE = 'Done';
  var HOLDING = 'Holding';
  var SPLASHING = 'Splashing';
}

class HoldCoverSprite extends FunkinSCSprite
{
  public var boom:Bool = false;
  public var isPlaying:Bool = false;
  public var activatedSprite:Bool = true;
  public var useRGBShader:Bool = false;

  public var rgbShader:RGBPixelShaderReference;
  public var spriteId:String = "";
  public var spriteIntID:Int = -1;
  public var skin:String = "";
  public var coverData:HoldCoverData =
    {
      texture: null,
      useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.getSongData('options').disableSplashRGB == true) : true,
      r: -1,
      g: -1,
      b: -1,
      a: 1
    }
  public var offsetX:Float = 0;
  public var offsetY:Float = 0;
  public var parentStrum:StrumArrow;

  public dynamic function initShader(noteData:Int)
  {
    rgbShader = new RGBPixelShaderReference();
    shader = rgbShader.shader;
  }

  public dynamic function initFrames(i:Int, hcolor:String)
  {
    var holdCoverSkin:String = "holdCover";
    var changeHoldCover:Bool = false;
    var holdCoverSkinNonRGB:Bool = false;
    if (PlayState.SONG != null)
    {
      // Check Stuff
      changeHoldCover = (PlayState.SONG.getSongData('options').holdCoverSkin != null
        && PlayState.SONG.getSongData('options').holdCoverSkin != "default"
        && PlayState.SONG.getSongData('options').holdCoverSkin != "holdCover"
        && PlayState.SONG.getSongData('options').holdCoverSkin != "");

      holdCoverSkinNonRGB = PlayState.SONG.getSongData('options').disableHoldCoversRGB;

      // Before replace
      holdCoverSkin = (changeHoldCover ? PlayState.SONG.getSongData('options').holdCoverSkin : 'holdCover');
    }
    this.skin = holdCoverSkin;

    final foundFirstPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/HoldNoteEffect/RGB/$holdCoverSkin$hcolor.png', IMAGE))
      || #end Assets.exists(Paths.getPath('images/HoldNoteEffect/RGB/$holdCoverSkin$hcolor.png', IMAGE));
    final foundSecondPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/HoldNoteEffect/$holdCoverSkin$hcolor.png', IMAGE))
      || #end Assets.exists(Paths.getPath('images/HoldNoteEffect/$holdCoverSkin$hcolor.png', IMAGE));
    final foundThirdPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$holdCoverSkin$hcolor.png',
      TEXT)) || #end Assets.exists(Paths.getPath('images/$holdCoverSkin$hcolor.png', TEXT));

    if (frames == null)
    {
      if (foundFirstPath)
      {
        this.frames = Paths.getSparrowAtlas(holdCoverSkinNonRGB ? 'HoldNoteEffect/$holdCoverSkin$hcolor' : 'HoldNoteEffect/RGB/$holdCoverSkin$hcolor');
        if (!holdCoverSkinNonRGB) this.initShader(i);
      }
      else if (foundSecondPath) this.frames = Paths.getSparrowAtlas('HoldNoteEffect/$holdCoverSkin$hcolor');
      else if (foundThirdPath) this.frames = Paths.getSparrowAtlas('$holdCoverSkin$hcolor');
      else
        this.frames = Paths.getSparrowAtlas('HoldNoteEffect/holdCover$hcolor');
    }
  }

  public dynamic function initAnimations(i:Int, hcolor:String)
  {
    this.animation.addByPrefix(Std.string(i), 'holdCover$hcolor', 24, true);
    this.animation.addByPrefix(Std.string(i) + 'p', 'holdCoverEnd$hcolor', 24, false);
  }

  public dynamic function shaderCopy(noteData:Int, note:Note)
  {
    this.antialiasing = ClientPrefs.data.antialiasing;
    if (skin.contains('pixel') || !ClientPrefs.data.antialiasing) this.antialiasing = false;
    var tempShader:RGBPalette = null;
    if ((note == null || this.coverData.useRGBShader)
      && (PlayState.SONG == null || !PlayState.SONG.getSongData('options').disableHoldCoversRGB))
    {
      // If Splash RGB is enabled:
      if (note != null)
      {
        if (this.coverData.r != -1) note.rgbShader.r = this.coverData.r;
        if (this.coverData.g != -1) note.rgbShader.g = this.coverData.g;
        if (this.coverData.b != -1) note.rgbShader.b = this.coverData.b;
        tempShader = note.rgbShader.parent;
      }
      else
        tempShader = Note.globalRgbShaders[noteData];
    }
    rgbShader.containsPixel = (skin.contains('pixel') || PlayState.isPixelStage);
    rgbShader.copyValues(tempShader);
  }

  public dynamic function affectSplash(splashStep:HoldCoverStep, ?noteData:Int = -1, ?note:Note = null)
  {
    if (noteData == -1 && note == null) return;
    switch (splashStep)
    {
      // Stop
      case STOP:
        shaderCopy(noteData, note);
        isPlaying = boom = visible = false;
        animation.stop();
      // Done
      case DONE:
        isPlaying = boom = visible = false;
      // While Holding
      case HOLDING:
        shaderCopy(noteData, note);
        visible = true;
        if (!isPlaying) playAnim(Std.string(noteData));
      // When splash happens
      case SPLASHING:
        isPlaying = false;
        boom = true;
        playAnim(Std.string(noteData) + 'p');
    }
  }

  override public function update(elapsed)
  {
    super.update(elapsed);
    if (parentStrum != null) setPosition(parentStrum.x - 110 + offsetX, parentStrum.y - 100 + offsetY);
    if (this.boom && this.isAnimationFinished()) this.visible = this.boom = false;
  }
}
