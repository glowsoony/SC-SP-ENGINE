package scfunkin.shaders;

import scfunkin.shaders.RGBPalette;

class RGBPixelShaderReference extends ShaderBase
{
  public var containsPixel:Bool = false;
  public var pixelSize:Float = 1;
  public var enabled(default, set):Bool = true;

  public function copyValues(tempShader:RGBPalette)
  {
    if (tempShader != null)
    {
      var rA:Array<Float> = [];
      var gA:Array<Float> = [];
      var bA:Array<Float> = [];
      for (i in 0...3)
      {
        rA.push(tempShader.shader.getFloatArray('r')[i]);
        gA.push(tempShader.shader.getFloatArray('g')[i]);
        bA.push(tempShader.shader.getFloatArray('b')[i]);
      }
      shader.setFloatArray('r', rA);
      shader.setFloatArray('g', gA);
      shader.setFloatArray('b', bA);
      shader.setFloat('mult', tempShader.shader.getFloat('mult'));
    }
    else
      enabled = false;

    if (containsPixel) pixelSize = 6;
    shader.setFloatArray('uBlocksize', [pixelSize, pixelSize]);
  }

  public function set_enabled(value:Bool)
  {
    enabled = value;
    shader.setFloat('mult', value ? 1 : 0);
    return value;
  }

  public function set_pixelAmount(value:Float)
  {
    pixelSize = value;
    shader.setFloatArray('uBlocksize', [value, value]);
    return value;
  }

  public function reset()
  {
    shader.setFloatArray('r', [0, 0, 0]);
    shader.setFloatArray('g', [0, 0, 0]);
    shader.setFloatArray('b', [0, 0, 0]);
  }

  public function new()
  {
    super('RGBPixel');
    reset();
    enabled = true;

    if (containsPixel) pixelSize = PlayState.daPixelZoom;
    else
      pixelSize = 1;
  }
}
