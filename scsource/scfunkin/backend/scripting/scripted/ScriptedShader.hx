package scfunkin.backend.scripting.scripted;

class ScriptedShader extends scfunkin.shaders.data.ShaderBase
{
  public var updateShader:Float->Void = null;
  public var canShaderUpdate:Bool = true;

  public function new(shader:String, ?ignorePref:Bool = false)
    super(shader, ignorePref);

  override public function update(elapsed:Float)
    if (updateShader != null) updateShader(elapsed);

  override public function canUpdate():Bool
    return canShaderUpdate;
}
