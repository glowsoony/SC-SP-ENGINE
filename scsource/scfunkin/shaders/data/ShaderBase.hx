package scfunkin.shaders.data;

import openfl.utils.Assets;

class ShaderBase
{
  public var shader:FlxRuntimeShader;
  public var id:String = null;
  public var tweens:Array<FlxTween> = [];

  public function new(file:String, ?ignorePref:Bool = false)
  {
    if (!ClientPrefs.data.shaders && !ignorePref)
    {
      shader = new FlxRuntimeShader();
      return;
    }
    shader = new FlxRuntimeShader(getCode(Paths.shaderFragment(file)), getCode(Paths.shaderVertex(file)));
  }

  public function canUpdate():Bool
    return true;

  public function update(elapsed:Float) {}

  public function getShader():FlxRuntimeShader
    return shader;

  public function destroy()
    shader = null;

  public function getCode(path:String):String
    return #if MODS_ALLOWED FileSystem.exists(path) ? File.getContent(path) : null #else Assets.exists(path) ? Assets.getText(path) : null #end;
}
