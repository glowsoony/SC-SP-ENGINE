package scfunkin.utils.tools;

class CameraTools
{
  public static function createCamera():FlxCamera
  {
    final camera:FlxCamera = new FlxCamera();
    camera.bgColor.alpha = 0;
    return camera;
  }
}
