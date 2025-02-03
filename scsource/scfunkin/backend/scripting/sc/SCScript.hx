package scfunkin.backend.scripting.sc;

import scfunkin.backend.scripting.sc.base.HScriptSC;

class SCScript extends flixel.FlxBasic
{
  public var hsCode:HScriptSC;

  public function new()
  {
    super();
  }

  public function loadScript(path:String, ?parent:Any = null)
  {
    hsCode = new HScriptSC(path, parent);
    presetScript();
  }

  public function callFunc(func:String, ?args:Array<Dynamic>):SCCall
  {
    if (hsCode == null || !active || !exists) return null;
    if (args == null) args = [];
    return hsCode.call(func, args);
  }

  public function executeFunc(func:String = null, args:Array<Dynamic> = null):SCCall
  {
    if (hsCode == null || !active || !exists) return null;
    return hsCode.call(func, args);
  }

  public function setVar(key:String, value:Dynamic):Void
  {
    if (hsCode == null || !active || !exists) return;
    hsCode.set(key, value, false);
  }

  public function getVar(key:String):Dynamic
  {
    if (hsCode == null || !active || !exists) return false;
    return hsCode.get(key);
  }

  public function existsVar(key:String):Bool
  {
    if (hsCode == null || !active || !exists) return false;
    return hsCode.exists(key);
  }

  public function presetScript()
  {
    if (hsCode == null || !active || !exists) return;

    for (k => e in ScriptPreset.scriptPresetVariables())
      setVar(k, e);

    setVar("disableScript", () -> {
      active = false;
    });
    setVar("__script__", this);

    setVar("playDadSing", true);
    setVar("playBFSing", true);

    // Functions & Variables
    setVar('setVar', function(name:String, value:Dynamic, ?type:String = "Custom") {
      MusicBeatState.getVariables(type).set(name, scfunkin.backend.scripting.psych.functions.ReflectionFunctions.parseInstances(value));
    });
    setVar('getVar', function(name:String, ?type:String = "Custom") {
      var result:Dynamic = null;
      if (MusicBeatState.getVariables(type).exists(name)) result = MusicBeatState.getVariables(type).get(name);
      return result;
    });
    setVar('removeVar', function(name:String, ?type:String = "Custom") {
      if (MusicBeatState.getVariables(type).exists(name))
      {
        MusicBeatState.getVariables(type).remove(name);
        return true;
      }
      return false;
    });
    setVar('debugPrint', function(text:String, ?color:FlxColor = null) {
      if (color == null) color = FlxColor.WHITE;
      if (PlayState.instance == FlxG.state) PlayState.instance.addTextToDebug(text, color);
      else
        Debug.logInfo(text);
    });
    setVar('getModSetting', function(saveTag:String, ?modName:String = null) {
      if (modName == null)
      {
        if (hsCode.modFolder == null)
        {
          PlayState.instance.addTextToDebug('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', FlxColor.RED);
          return null;
        }
        modName = hsCode.modFolder;
      }
      return scfunkin.utils.LuaUtil.getModSetting(saveTag, modName);
    });

    // Keyboard & Gamepads
    setVar('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
    setVar('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
    setVar('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

    setVar('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
    setVar('anyGamepadPressed', function(name:String) FlxG.gamepads.anyPressed(name));
    setVar('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

    setVar('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return 0.0;

      return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    });
    setVar('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return 0.0;

      return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    });
    setVar('gamepadJustPressed', function(id:Int, name:String) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return false;

      return Reflect.getProperty(controller.justPressed, name) == true;
    });
    setVar('gamepadPressed', function(id:Int, name:String) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return false;

      return Reflect.getProperty(controller.pressed, name) == true;
    });
    setVar('gamepadReleased', function(id:Int, name:String) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return false;

      return Reflect.getProperty(controller.justReleased, name) == true;
    });

    setVar('keyJustPressed', function(name:String = '') {
      name = name.toLowerCase();
      switch (name)
      {
        case 'left':
          return Controls.instance.NOTE_LEFT_P;
        case 'down':
          return Controls.instance.NOTE_DOWN_P;
        case 'up':
          return Controls.instance.NOTE_UP_P;
        case 'right':
          return Controls.instance.NOTE_RIGHT_P;
        default:
          return Controls.instance.justPressed(name);
      }
      return false;
    });
    setVar('keyPressed', function(name:String = '') {
      name = name.toLowerCase();
      switch (name)
      {
        case 'left':
          return Controls.instance.NOTE_LEFT;
        case 'down':
          return Controls.instance.NOTE_DOWN;
        case 'up':
          return Controls.instance.NOTE_UP;
        case 'right':
          return Controls.instance.NOTE_RIGHT;
        default:
          return Controls.instance.pressed(name);
      }
      return false;
    });
    setVar('keyReleased', function(name:String = '') {
      name = name.toLowerCase();
      switch (name)
      {
        case 'left':
          return Controls.instance.NOTE_LEFT_R;
        case 'down':
          return Controls.instance.NOTE_DOWN_R;
        case 'up':
          return Controls.instance.NOTE_UP_R;
        case 'right':
          return Controls.instance.NOTE_RIGHT_R;
        default:
          return Controls.instance.justReleased(name);
      }
      return false;
    });

    #if LUA_ALLOWED
    setVar('doLua', function(code:String = null, instance:String = "PLAYSTATE", preloading:Bool = false, scriptName:String = 'unknown') {
      if (code != null) new scfunkin.backend.scripting.psych.FunkinLua(code, instance, preloading, scriptName);
    });
    #end

    setVar('buildTarget', scfunkin.utils.GenericUtil.getBuildTarget());
    setVar('customSubstate', scfunkin.states.substates.scripting.CustomSubstate.instance);
    setVar('customSubstateName', scfunkin.states.substates.scripting.CustomSubstate.name);
    setVar('Function_Stop', scfunkin.utils.LuaUtil.Function_Stop);
    setVar('Function_Continue', scfunkin.utils.LuaUtil.Function_Continue);
    setVar('Function_StopLua', scfunkin.utils.LuaUtil.Function_StopLua); // doesnt do much cuz HScript has a lower priority than Lua
    setVar('Function_StopHScript', scfunkin.utils.LuaUtil.Function_StopHScript);
    setVar('Function_StopAll', scfunkin.utils.LuaUtil.Function_StopAll);

    setVar('setAxes', function(axes:String) return flixel.util.FlxAxes.fromString(axes));

    if (scfunkin.states.PlayState.instance == FlxG.state)
    {
      setVar('addBehindGF', scfunkin.states.PlayState.instance.addBehindGF);
      setVar('addBehindDad', scfunkin.states.PlayState.instance.addBehindDad);
      setVar('addBehindBF', scfunkin.states.PlayState.instance.addBehindBF);
    }

    setVar('setVarFromClass', function(instance:String, variable:String, value:Dynamic) {
      Reflect.setProperty(Type.resolveClass(instance), variable, value);
    });

    setVar('getVarFromClass', function(instance:String, variable:String) {
      Reflect.getProperty(Type.resolveClass(instance), variable);
    });

    setVar('parseJson', function(directory:String, ?ignoreMods:Bool = false):{} {
      var parseJson:{} = {};
      final funnyPath:String = directory + '.json';
      final jsonContents:String = Paths.getTextFromFile(funnyPath, ignoreMods);
      final realPath:String = (ignoreMods ? '' : Paths.modFolders(Mods.currentModDirectory)) + '/' + funnyPath;
      final jsonExists:Bool = Paths.fileExists(realPath, null, ignoreMods);
      if (jsonContents != null || jsonExists) parseJson = haxe.Json.parse(jsonContents);
      else if (!jsonExists && PlayState.chartingMode)
      {
        parseJson = {};
        if (scfunkin.states.PlayState.instance != null && scfunkin.states.PlayState.instance == FlxG.state)
        {
          scfunkin.states.PlayState.instance.addTextToDebug('parseJson: "' + realPath + '" doesn\'t exist!', 0xff0000, 6);
        }
      }
      return parseJson;
    });
  }

  override public function destroy()
  {
    hsCode.destroy();
    super.destroy();
  }
}
