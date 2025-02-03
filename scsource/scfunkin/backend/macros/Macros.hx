package scfunkin.backend.macros;

#if macro
import haxe.macro.*;
import haxe.macro.Expr;

/**
 * Macros containing additional help functions to expand HScript capabilities.
 */
class Macros
{
  public static function inclusiveMacro()
  {
    for (inc in [
      // FLIXEL
      "flixel.util",
      "flixel.ui",
      "flixel.tweens",
      "flixel.tile",
      "flixel.text",
      "flixel.system",
      "flixel.sound",
      "flixel.path",
      "flixel.math",
      "flixel.input",
      "flixel.group",
      "flixel.graphics",
      "flixel.effects",
      "flixel.animation",
      // FLIXEL ADDONS
      "flixel.addons.api",
      "flixel.addons.display",
      "flixel.addons.effects",
      "flixel.addons.ui",
      "flixel.addons.plugin",
      "flixel.addons.text",
      "flixel.addons.tile",
      "flixel.addons.transition",
      "flixel.addons.util",
      // OTHER LIBRARIES & STUFF
      #if (VIDEOS_ALLOWED && hxvlc) "hxvlc.flixel", "hxvlc.openfl", #end
      #if flxsoundfilters "flixel.sound.filters.effects", "flixel.sound.filters.extensions", #end
      // BASE HAXE
      "DateTools",
      "EReg",
      "Lambda",
      "StringBuf",
      "haxe.crypto",
      "haxe.display",
      "haxe.exceptions",
      "haxe.extern",

      "scfunkin",
      "scfunkin.backend",
      "scfunkin.debug",
      "scfunkin.objects",
      "scfunkin.play",
      "scfunkin.shaders",
      "scfunkin.states",
      "scfunkin.utils",
      "scfunkin.vslice"
    ])
      Compiler.include(inc);

    if (Context.defined("sys"))
    {
      for (inc in ["sys", "openfl.net"])
        Compiler.include(inc);
    }

    if (Context.defined("FunkinModchart"))
    {
      Compiler.include('modchart', true, ['modchart.standalone.adapters']);
      Compiler.include("modchart.standalone.adapters." + haxe.macro.Context.definedValue("FM_ENGINE").toLowerCase());
    }

    // Macro fixes
    Compiler.allowPackage('flash');
    Compiler.include('my.pack');

    // Include these
    Compiler.include('flixel', true, [
      'flixel.addons.editors.spine.*',
      'flixel.addons.nape.*',
      'flixel.system.macros.*'
    ]);
  }
}
#end
