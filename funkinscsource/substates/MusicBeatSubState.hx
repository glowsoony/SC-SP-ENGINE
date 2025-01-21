package substates;

import flixel.FlxSubState;
import backend.SBSEvent;
import backend.Conductor;
import haxe.ds.Either;
#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.LuaUtils;
import psychlua.HScript;
#end
#if (HSCRIPT_ALLOWED && HScriptImproved)
import codenameengine.scripting.Script as HScriptCode;
#end
#if HSCRIPT_ALLOWED
import scripting.*;
import crowplexus.iris.Iris;
#end

class MusicBeatSubState extends FlxSubState
{
  public function new()
  {
    super();
  }

  public var curSection:Int = 0;
  public var stepsToDo:Int = 0;

  public var lastBeat:Float = 0;
  public var lastStep:Float = 0;

  public var curStep:Int = 0;
  public var curBeat:Int = 0;

  public var curDecStep:Float = 0;
  public var curDecBeat:Float = 0;

  public var stepHitEvents:Array<SBSEvent> = [];
  public var beatHitEvents:Array<SBSEvent> = [];
  public var sectionHitEvents:Array<SBSEvent> = [];

  #if LUA_ALLOWED public var luaArray:Array<FunkinLua> = []; #end

  #if HSCRIPT_ALLOWED
  public var hscriptArray:Array<psychlua.HScript> = [];
  public var scHSArray:Array<scripting.SCScript> = [];

  #if HScriptImproved
  public var codeNameScripts:codenameengine.scripting.ScriptPack;
  #end
  #end
  public var controls(get, never):Controls;

  inline function get_controls():Controls
    return Controls.instance;

  override function create():Void
  {
    super.create();
  }

  public override function destroy():Void
  {
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
      LuaUtils.killShaders();
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
    super.destroy();
  }

  override function update(elapsed:Float)
  {
    if (!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;
    final oldStep:Int = curStep;

    updateCurStep();
    updateBeat();

    if (oldStep != curStep)
    {
      if (curStep > 0) stepHit();

      if (PlayState.SONG != null)
      {
        if (oldStep < curStep) updateSection();
        else
          rollbackSection();
      }
    }

    super.update(elapsed);
  }

  private function updateSection():Void
  {
    if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
    while (curStep >= stepsToDo)
    {
      curSection++;
      final beats:Float = getBeatsOnSection();
      stepsToDo += Math.round(beats * 4);
      sectionHit();
    }
  }

  private function rollbackSection():Void
  {
    if (curStep < 0) return;

    final lastSection:Int = curSection;
    curSection = 0;
    stepsToDo = 0;
    for (i in 0...PlayState.SONG.notes.length)
    {
      if (PlayState.SONG.notes[i] != null)
      {
        stepsToDo += Math.round(getBeatsOnSection() * 4);
        if (stepsToDo > curStep) break;

        curSection++;
      }
    }

    if (curSection > lastSection) sectionHit();
  }

  private function updateBeat():Void
  {
    curBeat = Math.floor(curStep / 4);
    curDecBeat = curDecStep / 4;
  }

  private function updateCurStep():Void
  {
    final lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
    final shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
    curDecStep = lastChange.stepTime + shit;
    curStep = Math.floor(lastChange.stepTime) + Math.floor(shit);
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

  public function addMultiSBSEvents(positions:Array<Int>, callBacks:Either<Void->Void, Array<Void->Void>>, type:SBS)
  {
    for (pos in 0...positions.length)
    {
      switch (callBacks)
      {
        case Left(func):
          addSBSEvent(positions[pos], func, type);
        case Right(funcs):
          addSBSEvent(positions[pos], funcs[pos], type);
      }
    }
  }

  public function removeMultiSBSEvents(events:Array<SBSEvent>)
  {
    for (event in events)
      removeSBSEvent(event);
  }

  public function getBeatsOnSection()
  {
    var val:Null<Float> = 4;
    if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
    return val == null ? 4 : val;
  }

  public function refresh()
  {
    sort(utils.SortUtil.byZIndex, flixel.util.FlxSort.ASCENDING);
  }

  #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
  public var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
  #end

  #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
  public function addTextToDebug(text:String, color:FlxColor, ?timeTaken:Float = 6)
  {
    if (luaDebugGroup != null)
    {
      final newText:psychlua.DebugLuaText = luaDebugGroup.recycle(psychlua.DebugLuaText);
      newText.text = text;
      newText.color = color;
      newText.disableTime = timeTaken;
      newText.alpha = 1;
      newText.setPosition(10, 8 - newText.height);

      luaDebugGroup.forEachAlive(function(spr:psychlua.DebugLuaText) {
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
    var newScript:HScript = new HScript(null, file, null, false, FlxG.state.subState);

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
          if (!(script is codenameengine.scripting.DummyScript))
          {
            codeNameScripts.add(script);

            // Set the things first
            script.set("SONG", PlayState.SONG);

            if (PlayState.instance == MusicBeatState.getState() && PlayState.instance.stage != null)
            {
              script.set("stageManager", backend.stage.Stage.instance);
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
    if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

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
    if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

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
    var returnVal:Dynamic = LuaUtils.Function_Continue;
    #if LUA_ALLOWED
    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

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
      if ((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll)
        && !excludeValues.contains(myValue)
        && !ignoreStops)
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
    var returnVal:Dynamic = LuaUtils.Function_Continue;

    #if HSCRIPT_ALLOWED
    if (exclusions == null) exclusions = new Array();
    if (excludeValues == null) excludeValues = new Array();
    excludeValues.push(LuaUtils.Function_Continue);

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
        if ((callValue == LuaUtils.Function_StopHScript || callValue == LuaUtils.Function_StopAll) && !ignoreStops) return callValue;
        if (callValue != null && !excludeValues.contains(callValue)) returnVal = callValue;
      }
    }
    #end

    return returnVal;
  }

  public function callOnHSI(funcToCall:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    var returnVal:Dynamic = LuaUtils.Function_Continue;

    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

    var len:Int = codeNameScripts.scripts.length;
    if (len < 1) return returnVal;

    for (script in codeNameScripts.scripts)
    {
      var myValue:Dynamic = script.active ? script.call(funcToCall, args) : null;
      if ((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll)
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
    var returnVal:Dynamic = LuaUtils.Function_Continue;

    #if HSCRIPT_ALLOWED
    if (exclusions == null) exclusions = new Array();
    if (excludeValues == null) excludeValues = new Array();
    excludeValues.push(LuaUtils.Function_Continue);

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
        if ((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll)
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
