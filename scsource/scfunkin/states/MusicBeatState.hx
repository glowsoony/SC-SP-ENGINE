package scfunkin.states;

import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.transition.TransitionData;
import flixel.addons.transition.Transition;
import scfunkin.objects.misc.PsychCamera;
import scfunkin.backend.events.SBSEvent;
import scfunkin.play.Conductor;
import scfunkin.play.Conductor.ConductorUpdater;
import haxe.ds.Either;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.*;
#else
import scfunkin.backend.scripting.psych.HScript;
#end
import scfunkin.utils.*;
#if (HSCRIPT_ALLOWED && HScriptImproved)
import scfunkin.backend.scripting.codename.Script as HScriptCode;
#end
#if HSCRIPT_ALLOWED
import scfunkin.backend.scripting.sc.*;
import scfunkin.backend.scripting.ScriptType;
import crowplexus.iris.Iris;
#end

class MusicBeatState extends flixel.addons.transition.FlxTransitionableState
{
  public var curSection(get, never):Int;

  function get_curSection():Int
    return updater.curSection;

  public var stepsToDo(get, never):Int;

  function get_stepsToDo():Int
    return updater.stepsToDo;

  public var curStep(get, never):Int;

  function get_curStep():Int
    return updater.curStep;

  public var curBeat(get, never):Int;

  function get_curBeat():Int
    return updater.curBeat;

  public var curDecStep(get, never):Float;

  function get_curDecStep():Float
    return updater.curDecStep;

  public var curDecBeat(get, never):Float;

  function get_curDecBeat():Float
    return updater.curDecBeat;

  public var controls(get, never):Controls;

  public static var subStates:Array<MusicBeatSubState> = [];

  // Cause OVERRIDE
  public static var disableNextTransIn:Bool = false;
  public static var disableNextTransOut:Bool = false;

  public var enableTransIn:Bool = true;
  public var enableTransOut:Bool = true;

  var transOutRequested:Bool = false;
  var finishedTransOut:Bool = false;

  public static var divideCameraZoom:Bool = true;
  public static var changedZoom:Float = 1;

  public var stepHitEvents:Array<SBSEvent> = [];
  public var beatHitEvents:Array<SBSEvent> = [];
  public var sectionHitEvents:Array<SBSEvent> = [];

  #if LUA_ALLOWED public var luaArray:Array<FunkinLua> = []; #end

  #if HSCRIPT_ALLOWED
  public var hscriptArray:Array<scfunkin.backend.scripting.psych.HScript> = [];
  public var scHSArray:Array<scfunkin.backend.scripting.sc.SCScript> = [];

  #if HScriptImproved
  public var codeNameScripts:scfunkin.backend.scripting.codename.ScriptPack;
  #end
  #end
  private function get_controls()
  {
    return Controls.instance;
  }

  public var updater:ConductorUpdater = new ConductorUpdater();

  override public function destroy()
  {
    if (subStates != null)
    {
      while (subStates.length > 5)
      {
        var subState:MusicBeatSubState = subStates[0];
        if (subState != null)
        {
          Debug.logTrace('Destroying Substates!');
          subStates.remove(subState);
          subState.destroy();
        }
        subState = null;
      }

      subStates.resize(0);
    }
    variables = [];
    #if LUA_ALLOWED
    if (luaArray != null)
    {
      for (lua in luaArray)
      {
        lua.call('onDestroy', []);
        lua.stop();
      }
      luaArray = null;
      FunkinLua.customFunctions.clear();
      LuaUtil.killShaders();
    }
    #end

    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    if (luaDebugGroup != null)
    {
      remove(luaDebugGroup);
      luaDebugGroup.destroy();
    }
    #end

    #if HSCRIPT_ALLOWED
    if (hscriptArray != null)
    {
      for (script in hscriptArray)
        if (script != null)
        {
          var ny:Dynamic = script.get('onDestroy');
          if (ny != null && Reflect.isFunction(ny)) ny();
          script.destroy();
        }
      hscriptArray = null;
    }

    if (scHSArray != null)
    {
      for (script in scHSArray)
        if (script != null)
        {
          script.executeFunc('onDestroy');
          script.destroy();
        }
      scHSArray = null;
    }

    #if HScriptImproved
    if (codeNameScripts != null)
    {
      for (script in codeNameScripts.scripts)
        if (script != null)
        {
          script.call('onDestroy');
          script.destroy();
        }
      codeNameScripts = null;
    }
    #end
    #end
    Conductor.stepHit.remove(stepHit);
    Conductor.beatHit.remove(beatHit);
    Conductor.sectionHit.remove(sectionHit);
    super.destroy();
  }

  var _psychCameraInitialized:Bool = false;

  public static var time:Float = 0.5;

  public var variables:Map<String, Map<String, Dynamic>> = [
    // For video sprites objects
    "Video" => new Map<String, scfunkin.objects.misc.VideoSprite>(),
    // For text type objects
    "Text" => new Map<String, flixel.text.FlxText>(),
    // For camera type objects
    "Camera" => new Map<String, flixel.FlxCamera>(),
    // For character type objects
    "Character" => new Map<String, scfunkin.objects.ui.Character>(),
    // For icon type objects
    "Icon" => new Map<String, scfunkin.objects.ui.HealthIcon>(),
    // For sound type objects
    "Sound" => new Map<String, flixel.sound.FlxSound>(),
    // For graphic, animated, image objects
    "Graphic" => new Map<String, flixel.FlxSprite>(),
    // For tweens
    "Tween" => new Map<String, flixel.tweens.FlxTween>(),
    // For timers
    "Timer" => new Map<String, flixel.util.FlxTimer>(),
    // For custom variables set with setVar/getVar
    "Custom" => [],
    // For instance objects
    "Instance" => [],
    // For shaders objects
    "Shader" => [],
    // For save objects
    "Save" => new Map<String, flixel.util.FlxSave>(),
    // For group objects
    "Group" => [],
    // For strumlines
    "StrumLine" => new Map<String, scfunkin.objects.note.StrumLine>()
  ];

  override function create()
  {
    destroySubStates = false;
    FlxG.mouse.visible = true;
    var skip:Bool = FlxTransitionableState.skipNextTransOut;
    #if MODS_ALLOWED Mods.updatedOnState = false; #end

    if (!_psychCameraInitialized) initPsychCamera();

    Conductor.stepHit.add(stepHit);
    Conductor.beatHit.add(beatHit);
    Conductor.sectionHit.add(sectionHit);

    super.create();
    if (!skip)
    {
      openSubState(new IndieDiamondTransSubState(time, true, FlxG.camera.zoom));
    }
    FlxTransitionableState.skipNextTransOut = false;
    timePassedOnState = 0;
  }

  public function initPsychCamera():PsychCamera
  {
    var camera = new PsychCamera();
    FlxG.cameras.reset(camera);
    FlxG.cameras.setDefaultDrawTarget(camera, true);
    _psychCameraInitialized = true;
    return camera;
  }

  public static var timePassedOnState:Float = 0;

  override function update(elapsed:Float)
  {
    timePassedOnState += elapsed;
    updater.update(elapsed);
    if (FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;
    super.update(elapsed);
  }

  public static function switchState(nextState:FlxState = null, ?time:Float = 0.75)
  {
    if (nextState == null) nextState = FlxG.state;
    if (nextState == FlxG.state)
    {
      resetState();
      return;
    }

    if (FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
    else
      startTransition(nextState, time);
    FlxTransitionableState.skipNextTransIn = false;
  }

  public static function resetState()
  {
    if (FlxTransitionableState.skipNextTransIn) FlxG.resetState();
    else
      startTransition();
    FlxTransitionableState.skipNextTransIn = false;
  }

  // Custom made Trans in
  public static function startTransition(nextState:FlxState = null, ?time:Float = 0.5)
  {
    if (nextState == null) nextState = FlxG.state;

    FlxG.state.openSubState(new IndieDiamondTransSubState(time, false, FlxG.camera.zoom));
    if (nextState == FlxG.state) IndieDiamondTransSubState.finishCallback = function() FlxG.resetState();
    else
      IndieDiamondTransSubState.finishCallback = function() FlxG.switchState(nextState);
  }

  public static function getState():MusicBeatState
  {
    return cast(FlxG.state, MusicBeatState);
  }

  public function getNoteSkinPostfix()
  {
    var skin:String = '';
    if (ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin) skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
    return skin;
  }

  public function stepHit():Void
  {
    if (stepHitEvents != null && stepHitEvents.length > 0)
    {
      for (func in stepHitEvents)
      {
        if (func != null && curStep >= func.position)
        {
          func.callBack();
          stepHitEvents.remove(func);
        }
      }
    }
    if (curStep % 4 == 0) beatHit();
  }

  public function beatHit():Void
  {
    if (beatHitEvents != null && beatHitEvents.length > 0)
    {
      for (func in beatHitEvents)
      {
        if (func != null && curBeat >= func.position)
        {
          func.callBack();
          beatHitEvents.remove(func);
        }
      }
    }
  }

  public function sectionHit():Void
  {
    if (sectionHitEvents != null && sectionHitEvents.length > 0)
    {
      for (func in sectionHitEvents)
      {
        if (func != null && curSection >= func.position)
        {
          func.callBack();
          sectionHitEvents.remove(func);
        }
      }
    }
  }

  public function addSBSEvent(position:Int, callBack:Void->Void, sbsType:SBS)
  {
    final event:SBSEvent = new SBSEvent(position, callBack, sbsType);
    switch (sbsType)
    {
      case "SECTION", "section", "sec":
        sectionHitEvents.push(event);
      case "STEP", "step":
        stepHitEvents.push(event);
      case "BEAT", "beat":
        beatHitEvents.push(event);
    }
  }

  public function removeSBSEvent(event:SBSEvent)
  {
    switch (event.sbsType)
    {
      case "SECTION":
        sectionHitEvents.remove(event);
      case "STEP":
        stepHitEvents.remove(event);
      case "BEAT":
        beatHitEvents.remove(event);
    }
  }

  public function addMultiSBSEvents(positions:Array<Int>, callBacks:Array<Void->Void>, type:SBS)
  {
    if (callBacks.length == 1)
    {
      for (pos in 0...positions.length)
        addSBSEvent(positions[pos], callBacks[0], type);
      return;
    }
    for (pos in 0...positions.length)
      addSBSEvent(positions[pos], callBacks[pos], type);
  }

  public function removeMultiSBSEvents(events:Array<SBSEvent>)
  {
    for (event in events)
      removeSBSEvent(event);
  }

  public function getBeatsOnSection()
  {
    var val:Null<Float> = 4;
    if (PlayState.SONG != null
      && PlayState.SONG.getSongData('notes')[curSection] != null) val = PlayState.SONG.getSongData('notes')[curSection].sectionBeats;
    return val == null ? 4 : val;
  }

  public function refresh()
    sort(scfunkin.utils.SortUtil.byZIndex, flixel.util.FlxSort.ASCENDING);

  public static function getVariables(type:String)
    return getState().variables.get(type);

  public static function variableObj(obj:String, ?types:Array<String> = null):Dynamic
  {
    if (types == null) types = grabDefaultTypes();
    for (varType in 0...types.length - 1)
    {
      if (getVariables(types[varType]).exists(obj)) return getVariables(types[varType]).get(obj);
    }
    return null;
  }

  // All things related to variables the variable.
  public static function variableMap(obj:String, ?types:Array<String> = null)
  {
    if (types == null) types = grabDefaultTypes();
    for (varType in 0...types.length - 1)
    {
      if (getVariables(types[varType]).exists(obj)) return getVariables(types[varType]);
    }
    return null;
  }

  public static function findVariable(obj:String, ?types:Array<String> = null):{found:Bool, type:String}
  {
    if (types == null) types = grabDefaultTypes();
    for (varType in 0...types.length - 1)
    {
      if (getVariables(types[varType]).exists(obj)) return {found: true, type: types[varType]};
    }
    return {found: false, type: ""};
  }

  public static function findVariableObj(obj:String, ?types:Array<String> = null):Bool
  {
    if (types == null) types = grabDefaultTypes();
    return findVariable(obj, types).found;
  }

  public static function getVariableType(obj:String, ?types:Array<String> = null):String
  {
    if (types == null) types = grabDefaultTypes();
    return findVariable(obj, types).type;
  }

  public static function grabDefaultTypes():Array<String>
  {
    var list:Array<String> = [];
    for (key in getState().variables.keys())
      list.push(key);
    return list;
  }

  #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
  public var luaDebugGroup:FlxTypedGroup<scfunkin.objects.ui.scripting.DebugLuaText>;
  #end

  #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
  public function addTextToDebug(text:String, color:FlxColor, ?timeTaken:Float = 6)
  {
    if (luaDebugGroup != null)
    {
      final newText:scfunkin.objects.ui.scripting.DebugLuaText = luaDebugGroup.recycle(scfunkin.objects.ui.scripting.DebugLuaText);
      newText.text = text;
      newText.color = color;
      newText.disableTime = timeTaken;
      newText.alpha = 1;
      newText.setPosition(10, 8 - newText.height);

      luaDebugGroup.forEachAlive(function(spr:scfunkin.objects.ui.scripting.DebugLuaText) {
        spr.y += newText.height + 2;
      });
      luaDebugGroup.add(newText);
    }

    Sys.println(text);
  }
  #end

  #if LUA_ALLOWED
  public function startLuasNamed(luaFile:String, ?defaultState:String = 'PLAYSTATE')
  {
    var scriptFilelua:String = luaFile + '.lua';
    #if MODS_ALLOWED
    var luaToLoad:String = Paths.modFolders(scriptFilelua);
    if (!FileSystem.exists(luaToLoad)) luaToLoad = Paths.getSharedPath(scriptFilelua);

    if (FileSystem.exists(luaToLoad))
    #elseif sys
    var luaToLoad:String = Paths.getSharedPath(scriptFilelua);
    if (OpenFlAssets.exists(luaToLoad))
    #end
    {
      for (script in luaArray)
        if (script.scriptName == luaToLoad) return false;

      addScript(luaToLoad, LUA, defaultState, ['PLAYSTATE', false]);
      return true;
    }
    return false;
  }
  #end

  #if HSCRIPT_ALLOWED
  public function startHScriptsNamed(scriptFile:String, ?defaultState:String = 'PLAYSTATE')
  {
    for (extn in CoolUtil.haxeExtensions)
    {
      var scriptFileHx:String = scriptFile + '.$extn';
      #if MODS_ALLOWED
      var scriptToLoad:String = Paths.modFolders(scriptFileHx);
      if (!FileSystem.exists(scriptToLoad)) scriptToLoad = Paths.getSharedPath(scriptFileHx);
      #else
      var scriptToLoad:String = Paths.getSharedPath(scriptFileHx);
      #end

      if (FileSystem.exists(scriptToLoad))
      {
        if (Iris.instances.exists(scriptToLoad)) return false;

        addScript(scriptToLoad, IRIS, defaultState);
        return true;
      }
    }
    return false;
  }

  public function initHScript(file:String)
  {
    final times:Float = Date.now().getTime();
    var newScript:HScript = new HScript(null, file);

    try
    {
      newScript.parse(true);
      newScript.run('onCreate');
      hscriptArray.push(newScript);
      Debug.logInfo('initialized Hscript interp successfully: $file (${Std.int(Date.now().getTime() - times)}ms)');
    }
    catch (e:crowplexus.hscript.Expr.Error)
    {
      newScript.errorCaught(e);
      newScript.destroy();
    }
  }

  public function startSCHSNamed(scriptFileHx:String)
  {
    #if MODS_ALLOWED
    var scriptToLoad:String = Paths.modFolders(scriptFileHx);
    if (!FileSystem.exists(scriptToLoad)) scriptToLoad = Paths.getSharedPath(scriptFileHx);
    #else
    var scriptToLoad:String = Paths.getSharedPath(scriptFileHx);
    #end

    if (FileSystem.exists(scriptToLoad))
    {
      for (script in scHSArray)
        if (script.hsCode.path == scriptToLoad) return false;

      addScript(scriptToLoad, SC);
      return true;
    }
    return false;
  }

  public function initSCHS(file:String)
  {
    var newScript:SCScript = null;
    try
    {
      var times:Float = Date.now().getTime();
      newScript = new SCScript();
      newScript.loadScript(file);
      newScript.executeFunc('onCreate');
      scHSArray.push(newScript);
      Debug.logInfo('initialized SCHScript interp successfully: $file (${Std.int(Date.now().getTime() - times)}ms)');
    }
    catch (e:Dynamic)
    {
      var script:SCScript = null;
      for (scripts in scHSArray)
        if (scripts.hsCode.path == file) script = scripts;
      if (script != null) script.destroy();
    }
  }

  #if HScriptImproved
  public function startHSIScriptsNamed(scriptFile:String)
  {
    for (extn in CoolUtil.haxeExtensions)
    {
      var scriptFileHx:String = scriptFile + '.$extn';
      #if MODS_ALLOWED
      var scriptToLoad:String = Paths.modFolders(scriptFileHx);
      if (!FileSystem.exists(scriptToLoad)) scriptToLoad = Paths.getSharedPath(scriptFileHx);
      #else
      var scriptToLoad:String = Paths.getSharedPath(scriptFileHx);
      #end

      if (FileSystem.exists(scriptToLoad))
      {
        for (script in codeNameScripts.scripts)
          if (script.fileName == scriptToLoad) return false;
        addScript(scriptToLoad, CODENAME);
        return true;
      }
    }
    return false;
  }

  public function initHSIScript(scriptFile:String)
  {
    try
    {
      var times:Float = Date.now().getTime();
      #if (HSCRIPT_ALLOWED && HScriptImproved)
      for (ext in CoolUtil.haxeExtensions)
      {
        if (scriptFile.toLowerCase().contains('.$ext'))
        {
          Debug.logInfo('INITIALIZED SCRIPT: ' + scriptFile);
          var script = HScriptCode.create(scriptFile);
          if (!(script is scfunkin.backend.scripting.codename.DummyScript))
          {
            codeNameScripts.add(script);

            // Set the things first
            script.set("SONG", PlayState.SONG);

            if (PlayState.instance == getState() && PlayState.instance.stage != null)
            {
              script.set("stageManager", scfunkin.play.stage.Stage.instance);
              // Difference between "Stage" and "gameStageAccess" is that "Stage" is the main class while "gameStageAccess" is the current "Stage" of this class.
              script.set("gameStageAccess", PlayState.instance.stage);
            }

            // Then CALL SCRIPT
            script.load();
            script.call('onCreate');
          }
        }
      }
      #end
      Debug.logInfo('initialized hscript-improved interp successfully: $scriptFile (${Std.int(Date.now().getTime() - times)}ms)');
    }
    catch (e)
    {
      Debug.logError('Error on loading Script!' + e);
    }
  }
  #end
  #end
  // Script stuff
  public function callOnAllHS(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtil.Function_Continue];

    var result:Dynamic = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
    if (result == null || excludeValues.contains(result)) result = callOnHSI(funcToCall, args, ignoreStops, exclusions, excludeValues);
    if (result == null || excludeValues.contains(result)) result = callOnSCHS(funcToCall, args, ignoreStops, exclusions, excludeValues);
    return result;
  }

  public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtil.Function_Continue];

    var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
    if (result == null || excludeValues.contains(result))
    {
      result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
      if (result == null || excludeValues.contains(result)) result = callOnHSI(funcToCall, args, ignoreStops, exclusions, excludeValues);
      if (result == null || excludeValues.contains(result)) result = callOnSCHS(funcToCall, args, ignoreStops, exclusions, excludeValues);
    }
    return result;
  }

  public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    var returnVal:Dynamic = LuaUtil.Function_Continue;
    #if LUA_ALLOWED
    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtil.Function_Continue];

    var arr:Array<FunkinLua> = [];
    for (script in luaArray)
    {
      if (script.closed)
      {
        arr.push(script);
        continue;
      }

      if (exclusions.contains(script.scriptName)) continue;

      var myValue:Dynamic = script.call(funcToCall, args);
      if ((myValue == LuaUtil.Function_StopLua || myValue == LuaUtil.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
      {
        returnVal = myValue;
        break;
      }

      if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;

      if (script.closed) arr.push(script);
    }

    if (arr.length > 0) for (script in arr)
      luaArray.remove(script);
    #end
    return returnVal;
  }

  public function callOnHScript(funcToCall:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    var returnVal:Dynamic = LuaUtil.Function_Continue;

    #if HSCRIPT_ALLOWED
    if (exclusions == null) exclusions = new Array();
    if (excludeValues == null) excludeValues = new Array();
    excludeValues.push(LuaUtil.Function_Continue);

    var len:Int = hscriptArray.length;
    if (len < 1) return returnVal;
    for (script in hscriptArray)
    {
      @:privateAccess
      if (script == null || !script.exists(funcToCall) || exclusions.contains(script.origin)) continue;

      var callValue:Dynamic = script.run(funcToCall, args);
      if (callValue == null) continue;

      if (!excludeValues.contains(callValue))
      {
        if ((callValue == LuaUtil.Function_StopHScript || callValue == LuaUtil.Function_StopAll) && !ignoreStops) return callValue;
        if (callValue != null && !excludeValues.contains(callValue)) returnVal = callValue;
      }
    }
    #end

    return returnVal;
  }

  public function callOnHSI(funcToCall:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    var returnVal:Dynamic = LuaUtil.Function_Continue;

    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtil.Function_Continue];

    var len:Int = codeNameScripts.scripts.length;
    if (len < 1) return returnVal;

    for (script in codeNameScripts.scripts)
    {
      var myValue:Dynamic = script.active ? script.call(funcToCall, args) : null;
      if ((myValue == LuaUtil.Function_StopHScript || myValue == LuaUtil.Function_StopAll)
        && !excludeValues.contains(myValue)
        && !ignoreStops)
      {
        returnVal = myValue;
        break;
      }
      if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;
    }
    #end

    return returnVal;
  }

  public function callOnSCHS(funcToCall:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    var returnVal:Dynamic = LuaUtil.Function_Continue;

    #if HSCRIPT_ALLOWED
    if (exclusions == null) exclusions = new Array();
    if (excludeValues == null) excludeValues = new Array();
    excludeValues.push(LuaUtil.Function_Continue);

    var len:Int = scHSArray.length;
    if (len < 1) return returnVal;
    for (script in scHSArray)
    {
      if (script == null || !script.existsVar(funcToCall) || exclusions.contains(script.hsCode.path)) continue;

      try
      {
        var callValue = script.callFunc(funcToCall, args);
        var myValue:Dynamic = callValue.funcReturn;

        // compiler fuckup fix
        if ((myValue == LuaUtil.Function_StopHScript || myValue == LuaUtil.Function_StopAll)
          && !excludeValues.contains(myValue)
          && !ignoreStops)
        {
          returnVal = myValue;
          break;
        }
        if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;
      }
      catch (e:Dynamic)
      {
        addTextToDebug('ERROR (${script.hsCode.path}: $funcToCall) - $e', FlxColor.RED);
      }
    }
    #end

    return returnVal;
  }

  public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    if (exclusions == null) exclusions = [];
    setOnLuas(variable, arg, exclusions);
    setOnHScript(variable, arg, exclusions);
    setOnHSI(variable, arg, exclusions);
    setOnSCHS(variable, arg, exclusions);
  }

  public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if LUA_ALLOWED
    if (exclusions == null) exclusions = [];
    for (script in luaArray)
    {
      if (exclusions.contains(script.scriptName)) continue;

      script.set(variable, arg);
    }
    #end
  }

  public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if HSCRIPT_ALLOWED
    if (exclusions == null) exclusions = [];
    for (script in hscriptArray)
    {
      if (exclusions.contains(script.origin)) continue;

      script.set(variable, arg);
    }
    #end
  }

  public function setOnHSI(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (exclusions == null) exclusions = [];
    for (script in codeNameScripts.scripts)
    {
      if (exclusions.contains(script.fileName)) continue;

      script.set(variable, arg);
    }
    #end
  }

  public function setOnSCHS(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if HSCRIPT_ALLOWED
    if (exclusions == null) exclusions = [];
    for (script in scHSArray)
    {
      if (exclusions.contains(script.hsCode.path)) continue;

      script.setVar(variable, arg);
    }
    #end
  }

  public function getOnScripts(variable:String, arg:String, exclusions:Array<String> = null)
  {
    if (exclusions == null) exclusions = [];
    getOnLuas(variable, arg, exclusions);
    getOnHScript(variable, exclusions);
    getOnHSI(variable, exclusions);
    getOnSCHS(variable, exclusions);
  }

  public function getOnLuas(variable:String, arg:String, exclusions:Array<String> = null)
  {
    #if LUA_ALLOWED
    if (exclusions == null) exclusions = [];
    for (script in luaArray)
    {
      if (exclusions.contains(script.scriptName)) continue;

      script.get(variable, arg);
    }
    #end
  }

  public function getOnHScript(variable:String, exclusions:Array<String> = null)
  {
    #if HSCRIPT_ALLOWED
    if (exclusions == null) exclusions = [];
    for (script in hscriptArray)
    {
      if (exclusions.contains(script.origin)) continue;

      script.get(variable);
    }
    #end
  }

  public function getOnHSI(variable:String, exclusions:Array<String> = null)
  {
    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (exclusions == null) exclusions = [];
    for (script in codeNameScripts.scripts)
    {
      if (exclusions.contains(script.fileName)) continue;

      script.get(variable);
    }
    #end
  }

  public function getOnSCHS(variable:String, exclusions:Array<String> = null)
  {
    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (exclusions == null) exclusions = [];
    for (script in scHSArray)
    {
      if (exclusions.contains(script.hsCode.path)) continue;

      script.getVar(variable);
    }
    #end
  }

  public function searchLuaVar(variable:String, arg:String, result:Bool)
  {
    #if LUA_ALLOWED
    for (script in luaArray)
    {
      if (script.get(variable, arg) == result)
      {
        return result;
      }
    }
    #end
    return !result;
  }

  public function addScript(file:String, type:ScriptType = CODENAME, ?defaultState:String = 'PLAYSTATE', ?externalArguments:Array<Dynamic> = null)
  {
    if (externalArguments == null) externalArguments = [];
    switch (type)
    {
      case CODENAME:
        initHSIScript(file);
      case IRIS:
        initHScript(file);
      case SC:
        initSCHS(file);
      case LUA:
        final state:String = (externalArguments[0] != null && externalArguments[0].length > 0) ? externalArguments[0] : defaultState;
        final preload:Bool = externalArguments[1] != null ? externalArguments[1] : false;
        new FunkinLua(file, state, preload);
    }
  }
}
