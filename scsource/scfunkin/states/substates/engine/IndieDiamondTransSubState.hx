package scfunkin.states.substates.engine;

import flixel.FlxSubState;
import scfunkin.shaders.IndieDiamondTransShader;

class IndieDiamondTransSubState extends MusicBeatSubState
{
  public static var finishCallback:Void->Void;

  private var tween:FlxTween = null;
  var shader:IndieDiamondTransShader;

  var fadeInState:Bool = true;

  var rect:FlxSprite;

  public static var placedZoom:Float;
  public static var divideZoom:Bool = true; // Divide = true, multiple = false

  var duration:Float;

  public function new(duration:Float, fadeInState:Bool, zoom:Float)
  {
    this.duration = duration;
    this.fadeInState = fadeInState;
    if (placedZoom > 0) placedZoom = zoom;
    super();
  }

  var cameraTrans:FlxCamera = null;

  override public function create()
  {
    cameraTrans = new FlxCamera();
    cameraTrans.bgColor.alpha = 0;

    FlxG.cameras.add(cameraTrans, false);

    var width:Int = divideZoom ? Std.int(FlxG.width / Math.max(camera.zoom, 0.001)) : Std.int(FlxG.width * Math.max(camera.zoom, 0.001));
    var height:Int = divideZoom ? Std.int(FlxG.height / Math.max(camera.zoom, 0.001)) : Std.int(FlxG.width * Math.max(camera.zoom, 0.001));

    shader = new IndieDiamondTransShader();

    shader.progress.value = [0.0];
    shader.reverse.value = [false];

    rect = new FlxSprite(0, 0);
    rect.makeGraphic(1, 1, 0xFF000000);
    rect.scale.set(width + 400, height + 400);
    rect.scrollFactor.set();
    rect.shader = shader;
    rect.visible = false;
    rect.cameras = [cameraTrans];
    rect.updateHitbox();
    rect.screenCenter(X);
    add(rect);

    rect.visible = true;
    shader.progress.value = [0.0];
    shader.reverse.value = [fadeInState ? true : false];

    tween = FlxTween.num(0.0, 1.0, duration,
      {
        ease: FlxEase.linear,
        onComplete: function(_) {
          new FlxTimer().start(duration, function(twn:FlxTimer) {
            if (fadeInState) close();
            else
            {
              if (finishCallback != null)
              {
                finishCallback();
              }
            }
          });
        }
      }, function(num:Float) {
        shader.progress.value = [num];
      });

    super.create();

    cameras = [cameraTrans];
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);
  }

  override function destroy()
  {
    if (tween != null)
    {
      tween.cancel();
    }
    super.destroy();
  }
}
