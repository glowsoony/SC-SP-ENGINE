package scfunkin.backend.scripting.psych.functions;

import flixel.group.*; // Need all group items lol.
import flixel.FlxBasic;
import scfunkin.objects.group.FlxSkewedSpriteGroup;

/**
 * Custom class made by me! -glow / editied and revised because of Ryiuu
 */
class GroupFunctions
{
  public static function implement(funk:FunkinLua)
  {
    funk.set("makeLuaSpriteGroup", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0) {
      tag = tag.replace('.', '');
      LuaUtil.findToDestroy(tag);
      final group:FlxSpriteGroup = new FlxSpriteGroup(x, y, maxSize);
      if (funk.isStageLua && !funk.preloading) Stage.instance.swagBacks.set(tag, group);
      else
        MusicBeatState.getVariables("Group").set(tag, group);
    });

    funk.set("makeLuaSkewedSpriteGroup", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0) {
      tag = tag.replace('.', '');
      LuaUtil.findToDestroy(tag);
      final group:FlxSkewedSpriteGroup = new FlxSkewedSpriteGroup(x, y, maxSize);
      if (funk.isStageLua && !funk.preloading) Stage.instance.swagBacks.set(tag, group);
      else
        MusicBeatState.getVariables("Group").set(tag, group);
    });

    funk.set('groupInsertSprite', function(tag:String, obj:String, pos:Int = 0, ?removeFromGroup:Bool = true) {
      final group:FlxSpriteGroup = LuaUtil.getObjectLoop(tag);
      if (group == null)
      {
        FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
        return false;
      }

      final object:FlxBasic = LuaUtil.getObjectLoop(obj);
      if (object != null)
      {
        final newObject:FlxSprite = cast(object, FlxSprite);
        if (newObject != null)
        {
          if (removeFromGroup) group.remove(newObject, true);
          group.insert(pos, newObject);
          return true;
        }
      }
      return false;
    });

    funk.set('groupInsertSkewedSprite', function(tag:String, obj:String, pos:Int = 0, ?removeFromGroup:Bool = true) {
      final group:FlxSkewedSpriteGroup = LuaUtil.getObjectLoop(tag);
      if (group == null)
      {
        FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
        return false;
      }

      final object:FlxBasic = LuaUtil.getObjectLoop(obj);
      if (object != null)
      {
        final newObject:FlxSkewed = cast(object, FlxSkewed);
        if (newObject != null)
        {
          if (removeFromGroup) group.remove(newObject, true);
          group.insert(pos, newObject);
          return true;
        }
      }
      return false;
    });

    funk.set('groupRemoveSprite', function(tag:String, obj:String, splice:Bool = false) {
      final group:FlxSpriteGroup = LuaUtil.getObjectLoop(tag);
      if (group == null)
      {
        FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
        return false;
      }

      final object:FlxBasic = LuaUtil.getObjectLoop(obj);
      if (object != null)
      {
        final newObject:FlxSprite = cast(object, FlxSprite);
        if (newObject != null)
        {
          group.remove(newObject, splice);
          return true;
        }
      }
      return false;
    });

    funk.set('groupRemoveSkewedSprite', function(tag:String, obj:String, splice:Bool = false) {
      final group:FlxSkewedSpriteGroup = LuaUtil.getObjectLoop(tag);
      if (group == null)
      {
        FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
        return false;
      }

      final object:FlxBasic = LuaUtil.getObjectLoop(obj);
      if (object != null)
      {
        var newObject:FlxSkewed = cast(object, FlxSkewed);
        if (newObject != null)
        {
          group.remove(newObject, splice);
          return true;
        }
      }
      return false;
    });

    funk.set('groupAddSprite', function(tag:String, obj:String) {
      final group:FlxSpriteGroup = LuaUtil.getObjectLoop(tag);
      if (group == null)
      {
        FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
        return false;
      }

      final object:FlxBasic = LuaUtil.getObjectLoop(obj);
      if (object != null)
      {
        final newObject:FlxSprite = cast(object, FlxSprite);
        if (newObject != null)
        {
          group.add(newObject);
          return true;
        }
      }
      return false;
    });

    funk.set('groupAddSkewedSprite', function(tag:String, obj:String) {
      final group:FlxSkewedSpriteGroup = LuaUtil.getObjectLoop(tag);
      if (group == null)
      {
        FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
        return false;
      }

      final object:FlxBasic = LuaUtil.getObjectLoop(obj);
      if (object != null)
      {
        final newObject:FlxSkewed = cast(object, FlxSkewed);
        if (newObject != null)
        {
          group.add(newObject);
          return true;
        }
      }
      return false;
    });

    funk.set('setSpriteGroupCameras', function(tag:String, cams:Array<String> = null) {
      final group:FlxSpriteGroup = LuaUtil.getObjectLoop(tag);
      final cameras:Array<FlxCamera> = [];
      for (i in 0...cams.length)
      {
        cameras.push(LuaUtil.cameraFromString(cams[i]));
      }
      if (group != null && cameras != null) group.cameras = cameras;
    });

    funk.set('setSkewedSpriteGroupCameras', function(tag:String, cams:Array<String> = null) {
      final group:FlxSpriteGroup = LuaUtil.getObjectLoop(tag);
      final cameras:Array<FlxCamera> = [];
      for (i in 0...cams.length)
      {
        cameras.push(LuaUtil.cameraFromString(cams[i]));
      }
      if (group != null && cameras != null) group.cameras = cameras;
    });

    funk.set('setSpriteGroupCamera', function(tag:String, cam:String = null) {
      final group:FlxSpriteGroup = LuaUtil.getObjectLoop(tag);
      if (group != null && cam != null) group.camera = LuaUtil.cameraFromString(cam);
    });

    funk.set('setSkewedSpriteGroupCamera', function(tag:String, cam:String = null) {
      final group:FlxSpriteGroup = LuaUtil.getObjectLoop(tag);
      if (group != null && cam != null) group.camera = LuaUtil.cameraFromString(cam);
    });
  }
}
