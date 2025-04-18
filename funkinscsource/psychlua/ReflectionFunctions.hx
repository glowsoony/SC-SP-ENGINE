package psychlua;

import Type.ValueType;
import haxe.Constraints;
import substates.GameOverSubstate;
import objects.Character;
import lime.app.Application;

//
// Functions that use a high amount of Reflections, which are somewhat CPU intensive
// These functions are held together by duct tape
//
class ReflectionFunctions
{
  static final instanceStr:Dynamic = "##PSYCHLUA_STRINGTOOBJ";

  public static function implement(funk:FunkinLua)
  {
    funk.set("getProperty", function(variable:String, ?allowMaps:Bool = false) {
      var split:Array<String> = variable.split('.');
      if (Stage.instance.swagBacks.exists(split[0]))
      {
        return Stage.instance.getPropertyObject(variable);
      }
      if (split.length > 1)
      {
        if (FunkinLua.lua_Custom_Shaders.exists(split[0])) return FunkinLua.lua_Custom_Shaders.get(split[0]).hget(split[1]);
        return LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split, true, allowMaps), split[split.length - 1], allowMaps);
      }
      return LuaUtils.getVarInArray(LuaUtils.getTargetInstance(), variable, allowMaps);
    });
    funk.set("setProperty", function(variable:String, value:Dynamic, allowMaps:Bool = false, ?allowInstances:Bool = false) {
      var split:Array<String> = variable.split('.');
      if (Stage.instance.swagBacks.exists(split[0]))
      {
        Stage.instance.setPropertyObject(variable, allowInstances ? parseSingleInstance(value) : value);
        return value;
      }
      if (split.length > 1)
      {
        if (FunkinLua.lua_Custom_Shaders.exists(split[0]))
        {
          FunkinLua.lua_Custom_Shaders.get(split[0]).hset(split[1], value);
          return value;
        }
        LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split, true, allowMaps), split[split.length - 1], allowInstances ? parseSingleInstance(value) : value,
          allowMaps);
        return value;
      }
      LuaUtils.setVarInArray(LuaUtils.getTargetInstance(), variable, allowInstances ? parseSingleInstance(value) : value, allowMaps);
      return value;
    });
    funk.set("getPropertyFromClass", function(classVar:String, variable:String, ?allowMaps:Bool = false) {
      classVar = checkForOldClassVars(classVar);

      var myClass:Dynamic = Type.resolveClass(classVar);
      if (myClass == null)
      {
        FunkinLua.luaTrace('getPropertyFromClass: Class $classVar not found', false, false, FlxColor.RED);
        return null;
      }

      var split:Array<String> = variable.split('.');
      if (split.length > 1)
      {
        var obj:Dynamic = LuaUtils.getVarInArray(myClass, split[0], allowMaps);
        for (i in 1...split.length - 1)
          obj = LuaUtils.getVarInArray(obj, split[i], allowMaps);

        return LuaUtils.getVarInArray(obj, split[split.length - 1], allowMaps);
      }
      return LuaUtils.getVarInArray(myClass, variable, allowMaps);
    });
    funk.set("setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic, ?allowMaps:Bool = false, ?allowInstances:Bool = false) {
      classVar = checkForOldClassVars(classVar);

      var myClass:Dynamic = Type.resolveClass(classVar);
      if (myClass == null)
      {
        FunkinLua.luaTrace('setPropertyFromClass: Class $classVar not found', false, false, FlxColor.RED);
        return null;
      }

      var split:Array<String> = variable.split('.');
      if (split.length > 1)
      {
        var obj:Dynamic = LuaUtils.getVarInArray(myClass, split[0], allowMaps);
        for (i in 1...split.length - 1)
          obj = LuaUtils.getVarInArray(obj, split[i], allowMaps);

        LuaUtils.setVarInArray(obj, split[split.length - 1], allowInstances ? parseSingleInstance(value) : value, allowMaps);
        return value;
      }
      LuaUtils.setVarInArray(myClass, variable, allowInstances ? parseSingleInstance(value) : value, allowMaps);
      return value;
    });
    funk.set("getPropertyFromGroup", function(group:String, index:Int, variable:Dynamic, ?allowMaps:Bool = false) {
      var split:Array<String> = group.split('.');
      var realObject:Dynamic = null;
      if (split.length > 1) realObject = LuaUtils.getPropertyLoop(split, true, allowMaps);
      else
        realObject = Reflect.getProperty(LuaUtils.getTargetInstance(), group);

      var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
      if (groupOrArray != null)
      {
        switch (Type.typeof(groupOrArray))
        {
          case TClass(Array): // Is Array
            var leArray:Dynamic = realObject[index];
            if (leArray != null)
            {
              var result:Dynamic = null;
              if (Type.typeof(variable) == ValueType.TInt) result = leArray[variable];
              else
                result = LuaUtils.getGroupStuff(leArray, variable, allowMaps);
              return result;
            }
            FunkinLua.luaTrace('getPropertyFromGroup: Object #$index from group: $group doesn\'t exist!', false, false, FlxColor.RED);
          default: // Is Group
            var result:Dynamic = LuaUtils.getGroupStuff(realObject.members[index], variable, allowMaps);
            return result;
        }
      }

      FunkinLua.luaTrace('getPropertyFromGroup: Group/Array $group doesn\'t exist!', false, false, FlxColor.RED);
      return null;
    });
    funk.set("setPropertyFromGroup",
      function(group:String, index:Int, variable:Dynamic, value:Dynamic, ?allowMaps:Bool = false, ?allowInstances:Bool = false) {
        var split:Array<String> = group.split('.');
        var realObject:Dynamic = null;
        if (split.length > 1) realObject = LuaUtils.getPropertyLoop(split, true, allowMaps);
        else
          realObject = Reflect.getProperty(LuaUtils.getTargetInstance(), group);

        if (realObject != null)
        {
          switch (Type.typeof(realObject))
          {
            case TClass(Array): // Is Array
              var leArray:Dynamic = realObject[index];
              if (leArray != null)
              {
                if (Type.typeof(variable) == ValueType.TInt)
                {
                  leArray[variable] = allowInstances ? parseSingleInstance(value) : value;
                  return value;
                }
                LuaUtils.setGroupStuff(leArray, variable, allowInstances ? parseSingleInstance(value) : value, allowMaps);
              }
            default: // Is Group
              LuaUtils.setGroupStuff(realObject.members[index], variable, allowInstances ? parseSingleInstance(value) : value, allowMaps);
          }
        }
        else
          FunkinLua.luaTrace('setPropertyFromGroup: Group/Array $group doesn\'t exist!', false, false, FlxColor.RED);
        return value;
      });
    funk.set("addToGroup", function(group:String, tag:String, ?index:Int = -1) {
      var obj:FlxSprite = LuaUtils.getObjectDirectly(tag);
      if (obj == null || obj.destroy == null)
      {
        FunkinLua.luaTrace('addToGroup: Object $tag is not valid!', false, false, FlxColor.RED);
        return;
      }

      var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
      if (groupOrArray == null)
      {
        FunkinLua.luaTrace('addToGroup: Group/Array $group is not valid!', false, false, FlxColor.RED);
        return;
      }

      if (index < 0)
      {
        switch (Type.typeof(groupOrArray))
        {
          case TClass(Array): // Is Array
            groupOrArray.push(obj);

          default: // Is Group
            groupOrArray.add(obj);
        }
      }
      else
        groupOrArray.insert(index, obj);
    });
    funk.set("removeFromGroup", function(group:String, ?index:Int = -1, ?tag:String = null, ?destroy:Bool = true) {
      var obj:FlxSprite = null;
      if (tag != null)
      {
        obj = LuaUtils.getObjectDirectly(tag);
        if (obj == null || obj.destroy == null)
        {
          FunkinLua.luaTrace('removeFromGroup: Object $tag is not valid!', false, false, FlxColor.RED);
          return;
        }
      }

      var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
      if (groupOrArray == null)
      {
        FunkinLua.luaTrace('removeFromGroup: Group/Array $group is not valid!', false, false, FlxColor.RED);
        return;
      }

      switch (Type.typeof(groupOrArray))
      {
        case TClass(Array): // Is Array
          if (obj == null) obj = groupOrArray.members[index];
          groupOrArray.remove(obj, true);
          if (destroy) obj.destroy();

        default: // Is Group
          if (obj != null)
          {
            groupOrArray.remove(obj);
            if (destroy) obj.destroy();
          }
          else
            groupOrArray.remove(groupOrArray[index]);
      }
    });

    funk.set("callMethod", function(funcToRun:String, ?args:Array<Dynamic> = null) {
      var parent:Dynamic = PlayState.instance;
      var split:Array<String> = funcToRun.split('.');
      var varParent:Dynamic = MusicBeatState.variableMap(split[0].trim()).get(split[0].trim());
      if (varParent != null)
      {
        split.shift();
        funcToRun = split.join('.').trim();
        parent = varParent;
      }

      if (funcToRun.length > 0)
      {
        return callMethodFromObject(parent, funcToRun, parseInstances(args));
      }
      return Reflect.callMethod(null, parent, parseInstances(args));
    });
    funk.set("callMethodFromClass", function(className:String, funcToRun:String, ?args:Array<Dynamic> = null) {
      return callMethodFromObject(Type.resolveClass(className), funcToRun, parseInstances(args));
    });

    funk.set("createInstance", function(variableToSave:String, className:String, ?args:Array<Dynamic> = null) {
      variableToSave = variableToSave.trim().replace('.', '');
      if (MusicBeatState.variableMap(variableToSave).get(variableToSave) == null)
      {
        if (args == null) args = [];
        var myType:Dynamic = Type.resolveClass(className);

        if (myType == null)
        {
          FunkinLua.luaTrace('createInstance: Class $className not found.', false, false, FlxColor.RED);
          return false;
        }

        var obj:Dynamic = Type.createInstance(myType, parseInstances(args));
        if (obj != null) MusicBeatState.getVariables("Instance").set(variableToSave, obj);
        else
          FunkinLua.luaTrace('createInstance: Failed to create $variableToSave, arguments are possibly wrong.', false, false, FlxColor.RED);

        return (obj != null);
      }
      else
        FunkinLua.luaTrace('createInstance: Variable $variableToSave is already being used and cannot be replaced!', false, false, FlxColor.RED);
      return false;
    });
    funk.set("addInstance", function(objectName:String, ?inFront:Bool = false) {
      var savedObj:Dynamic = MusicBeatState.variableMap(objectName).get(objectName);
      if (savedObj != null)
      {
        var obj:Dynamic = savedObj;
        if (inFront) LuaUtils.getTargetInstance().add(obj);
        else
        {
          if (!PlayState.instance.isDead) PlayState.instance.insert(PlayState.instance.members.indexOf(LuaUtils.getLowestCharacterPlacement()), obj);
          else
            GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), obj);
        }
      }
      else
        FunkinLua.luaTrace('addInstance: Can\'t add what doesn\'t exist~ ($objectName)', false, false, FlxColor.RED);
    });
    // Code by LarryFrosty
    funk.set("removeInstance", function(objectName:String, destroy:Bool = true, ?type:String = "Custom") {
      if (MusicBeatState.getVariables("Instance").get(objectName))
      {
        var obj:Dynamic = MusicBeatState.getVariables("Instance").get(objectName);
        LuaUtils.getTargetInstance().remove(obj, true);
        if (destroy)
        {
          obj.kill();
          obj.destroy();
          MusicBeatState.getVariables("Instance").remove(objectName);
        }
      }
      else
        FunkinLua.luaTrace('removeInstance: Variable $objectName does not exist and cannot be removed!');
    });
    funk.set("instanceArg", function(instanceName:String, ?className:String = null) {
      var retStr:String = '$instanceStr::$instanceName';
      if (className != null) retStr += '::$className';
      return retStr;
    });
  }

  static function parseInstances(args:Array<Dynamic>)
  {
    if (args == null) return [];
    for (i in 0...args.length)
      args[i] = parseSingleInstance(args[i]);
    return args;
  }

  public static function parseSingleInstance(arg:Dynamic)
  {
    var argStr:String = cast arg;
    if (argStr != null && argStr.length > instanceStr.length)
    {
      final index:Int = argStr.indexOf('::');
      if (index > -1)
      {
        argStr = argStr.substring(index + 2);
        // trace('Op1: $argStr');
        final lastIndex:Int = argStr.lastIndexOf('::');
        final split:Array<String> = (lastIndex > -1) ? argStr.substring(0, lastIndex).split('.') : argStr.split('.');
        arg = (lastIndex > -1) ? Type.resolveClass(argStr.substring(lastIndex + 2)) : PlayState.instance;
        for (j in 0...split.length)
          arg = LuaUtils.getVarInArray(arg, split[j].trim());
      }
    }
    return arg;
  }

  static function callMethodFromObject(classObj:Dynamic, funcStr:String, args:Array<Dynamic>)
  {
    var split:Array<String> = funcStr.split('.');
    var funcToRun:Function = null;
    var obj:Dynamic = classObj;
    if (obj == null)
    {
      return null;
    }

    for (i in 0...split.length)
    {
      obj = LuaUtils.getVarInArray(obj, split[i].trim());
    }

    funcToRun = cast obj;
    return funcToRun != null ? Reflect.callMethod(obj, funcToRun, args) : null;
  }

  static function checkForOldClassVars(classVar:String)
  {
    switch (classVar)
    {
      case "NoteSplash":
        classVar = "objects.note.NoteSplash";
      case "Note":
        classVar = "objects.note.Note";
      case "StrumNote", "StrumArrow":
        classVar = "objects.note.StrumArrow";
      case "ClientPrefs":
        classVar = "backend.ClientPrefs";
      case "Conductor":
        classVar = "backend.Conductor";
      case "LoadingState":
        classVar = "states.LoadingState";
      #if LUA_ALLOWED
      case "FunkinLua":
        classVar = "psychlua.FunkinLua";
      #end
      case "PlayState":
        classVar = "states.PlayState";
    }
    return classVar;
  }
}
