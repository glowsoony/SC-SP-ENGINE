package psychlua;

import flixel.group.*; // Need all group items lol.
import flixel.FlxBasic;
import group.FlxSkewedSpriteGroup;

/**
 * Custom class made by me! -glow / editied and revised because of Ryiuu
 */
class GroupFunctions
{
  public static function implement(funk:FunkinLua)
  {
    funk.set("makeLuaSpriteGroup", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0) {
      tag = tag.replace('.', '');
      LuaUtils.findToDestroy(tag);
      final group:FlxSpriteGroup = new FlxSpriteGroup(x, y, maxSize);
      if (funk.isStageLua && !funk.preloading) Stage.instance.swagBacks.set(tag, group);
      else
        MusicBeatState.getVariables("Group").set(tag, group);
    });

    funk.set("makeLuaSkewedSpriteGroup", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0) {
      tag = tag.replace('.', '');
      LuaUtils.findToDestroy(tag);
      final group:FlxSkewedSpriteGroup = new FlxSkewedSpriteGroup(x, y, maxSize);
      if (funk.isStageLua && !funk.preloading) Stage.instance.swagBacks.set(tag, group);
      else
        MusicBeatState.getVariables("Group").set(tag, group);
    });

    funk.set('groupInsertSprite', function(tag:String, obj:String, pos:Int = 0, ?removeFromGroup:Bool = true) {
      final group:FlxSpriteGroup = LuaUtils.getObjectLoop(tag);
      if (group == null)
      {
        FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
        return false;
      }

      final object:FlxBasic = LuaUtils.getObjectLoop(obj);
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
      final group:FlxSkewedSpriteGroup = LuaUtils.getObjectLoop(tag);
      if (group == null)
      {
        FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
        return false;
      }

      final object:FlxBasic = LuaUtils.getObjectLoop(obj);
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
      final group:FlxSpriteGroup = LuaUtils.getObjectLoop(tag);
      if (group == null)
      {
        FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
        return false;
      }

      final object:FlxBasic = LuaUtils.getObjectLoop(obj);
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
      final group:FlxSkewedSpriteGroup = LuaUtils.getObjectLoop(tag);
      if (group == null)
      {
        FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
        return false;
      }

      final object:FlxBasic = LuaUtils.getObjectLoop(obj);
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
      final group:FlxSpriteGroup = LuaUtils.getObjectLoop(tag);
      if (group == null)
      {
        FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
        return false;
      }

      final object:FlxBasic = LuaUtils.getObjectLoop(obj);
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
      final group:FlxSkewedSpriteGroup = LuaUtils.getObjectLoop(tag);
      if (group == null)
      {
        FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
        return false;
      }

      final object:FlxBasic = LuaUtils.getObjectLoop(obj);
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
      final group:FlxSpriteGroup = LuaUtils.getObjectLoop(tag);
      final cameras:Array<FlxCamera> = [];
      for (i in 0...cams.length)
      {
        cameras.push(LuaUtils.cameraFromString(cams[i]));
      }
      if (group != null && cameras != null) group.cameras = cameras;
    });

    funk.set('setSkewedSpriteGroupCameras', function(tag:String, cams:Array<String> = null) {
      final group:FlxSpriteGroup = LuaUtils.getObjectLoop(tag);
      final cameras:Array<FlxCamera> = [];
      for (i in 0...cams.length)
      {
        cameras.push(LuaUtils.cameraFromString(cams[i]));
      }
      if (group != null && cameras != null) group.cameras = cameras;
    });

    funk.set('setSpriteGroupCamera', function(tag:String, cam:String = null) {
      final group:FlxSpriteGroup = LuaUtils.getObjectLoop(tag);
      if (group != null && cam != null) group.camera = LuaUtils.cameraFromString(cam);
    });

    funk.set('setSkewedSpriteGroupCamera', function(tag:String, cam:String = null) {
      final group:FlxSpriteGroup = LuaUtils.getObjectLoop(tag);
      if (group != null && cam != null) group.camera = LuaUtils.cameraFromString(cam);
    });
  }
}
