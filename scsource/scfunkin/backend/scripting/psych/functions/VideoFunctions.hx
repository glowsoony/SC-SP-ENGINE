package scfunkin.backend.scripting.psych.functions;

import scfunkin.objects.misc.VideoSprite;
import scfunkin.states.substates.GameOverSubstate;

#if (VIDEOS_ALLOWED && hxvlc)
class VideoFunctions
{
  // Code by DMMaster636
  public static function implement(funk:FunkinLua)
  {
    funk.set("makeVideoSprite", function(tag:String, video:String, ext:String = 'mp4', ?x:Float = 0, ?y:Float = 0, ?loop:Dynamic = false) {
      tag = tag.replace('.', '');
      LuaUtil.findToDestroy(tag);
      final leVideo:VideoSprite = new VideoSprite(Paths.video(video, ext), true, false, loop, false);
      leVideo.setPosition(x, y);
      MusicBeatState.getVariables("Video").set(tag, leVideo);
    });
    funk.set("setVideoSize", function(tag:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
      final video:VideoSprite = LuaUtil.getObjectLoop(tag);
      if (video != null)
      {
        if (!video.isPlaying)
        {
          video.videoSprite.bitmap.onFormatSetup.add(function() {
            video.videoSprite.setGraphicSize(x, y);
            if (updateHitbox) video.videoSprite.updateHitbox();
          });
        }
        video.setGraphicSize(x, y);
        if (updateHitbox) video.updateHitbox();
        return;
      }
      FunkinLua.luaTrace('setVideoSize: Couldnt find video: ' + tag, false, false, FlxColor.RED);
    });
    // TODO: find a way to do this?
    /*funk.set("scaleVideo", function(tag:String, x:Float, y:Float, updateHitbox:Bool = true) {
      final video:VideoSprite = LuaUtil.getObjectLoop(tag);
      if (video != null)
      {
        if (!video.isPlaying)
        {
          video.videoSprite.bitmap.onFormatSetup.add(function() {
            video.videoSprite.scale.set(x, y);
            if (updateHitbox) video.videoSprite.updateHitbox();
          });
        }
        video.scale.set(x, y);
        if (updateHitbox) video.updateHitbox();
        return;
      }
      FunkinLua.luaTrace('scaleVideo: Couldnt find video: ' + obj, false, false, FlxColor.RED);
    });*/

    funk.set("addLuaVideo", function(tag:String, front:Bool = false) {
      var myVideo:VideoSprite = MusicBeatState.variableMap(tag).get(tag);
      if (myVideo == null) return false;

      var instance = LuaUtil.getTargetInstance();
      if (front) instance.add(myVideo);
      else
      {
        if (PlayState.instance == null || !PlayState.instance.isDead) instance.insert(instance.members.indexOf(LuaUtil.getLowestCharacterPlacement()), myVideo);
        else
          GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), myVideo);
      }
      return true;
    });
    funk.set("removeLuaVideo", function(tag:String, destroy:Bool = true, ?group:String = null) {
      var obj:VideoSprite = LuaUtil.getObjectDirectly(tag);
      if (obj == null || obj.destroy == null) return;

      var groupObj:Dynamic = null;
      if (group == null) groupObj = LuaUtil.getTargetInstance();
      else
        groupObj = LuaUtil.getObjectDirectly(group);

      groupObj.remove(obj, true);
      if (destroy)
      {
        var variables = MusicBeatState.variableMap(tag);
        if (variables != null) variables.remove(tag);
        obj.destroy();
      }
    });

    funk.set("playVideo", function(tag:String) {
      final video:VideoSprite = LuaUtil.getObjectLoop(tag);
      if (video != null)
      {
        if (!video.isPlaying) video.play();
        return;
      }
      FunkinLua.luaTrace('playVideo: Couldnt find video: ' + tag, false, false, FlxColor.RED);
    });
    funk.set("resumeVideo", function(tag:String) {
      final video:VideoSprite = LuaUtil.getObjectLoop(tag);
      if (video != null)
      {
        if (!video.isPlaying && video.isPaused) video.resume();
        return;
      }
      FunkinLua.luaTrace('resumeVideo: Couldnt find video: ' + tag, false, false, FlxColor.RED);
    });
    funk.set("pauseVideo", function(tag:String) {
      final video:VideoSprite = LuaUtil.getObjectLoop(tag);
      if (video != null)
      {
        if (video.isPlaying && !video.isPaused) video.pause();
        return;
      }
      FunkinLua.luaTrace('pauseVideo: Couldnt find video: ' + tag, false, false, FlxColor.RED);
    });

    funk.set("luaVideoExists", function(tag:String) {
      final obj:VideoSprite = MusicBeatState.variableMap(tag).get(tag);
      return (obj != null && Std.isOfType(obj, VideoSprite));
    });
  }
}
#end
