package;

import flixel.graphics.FlxGraphic;
import flixel.FlxState;
import openfl.Lib;
import lime.app.Application;
import scfunkin.states.TitleState;
import scfunkin.states.FlashingState;
import scfunkin.play.song.data.Highscore;
import scfunkin.debug.Debug;
import scfunkin.debug.FPSCounter;

class Init extends FlxState
{
  public static var mouseCursor:FlxSprite;

  override function create()
  {
    FlxTransitionableState.skipNextTransOut = true;

    // Run this first so we can see logs.
    scfunkin.debug.Debug.onInitProgram();

    Application.current.window.setIcon(lime.utils.Assets.getImage('assets/art/iconOG.png'));

    #if !mobile
    if (Main.fpsVar == null) Lib.current.stage.addChild(Main.fpsVar = new FPSCounter(10, 3, 0xFFFFFF));
    #end

    #if !MODS_ALLOWED
    if (sys.FileSystem.exists('mods') && sys.FileSystem.isDirectory('mods'))
    {
      var entries = sys.FileSystem.readDirectory('mods');
      for (entry in entries)
        sys.FileSystem.deleteFile('mods' + '/' + entry);
      FileSystem.deleteDirectory('mods');
    }
    #end

    #if linux
    Lib.current.stage.window.setIcon(lime.graphics.Image.fromFile("icon.png"));
    #end

    FlxG.autoPause = false;

    // Setup window events (like callbacks for onWindowClose)
    // and fullscreen keybind setup - Not Used
    scfunkin.utils.WindowUtil.initWindowEvents();
    // Disable the thing on Windows where it tries to send a bug report to Microsoft because why do they care?
    scfunkin.utils.WindowUtil.disableCrashHandler();

    FlxGraphic.defaultPersist = true;

    #if LUA_ALLOWED
    Mods.pushGlobalMods();
    #end
    Mods.loadTopMod();

    FlxG.save.bind('funkin', scfunkin.utils.CoolUtil.getSavePath());

    ClientPrefs.loadPrefs();
    ClientPrefs.keybindSaveLoad();
    Language.reloadPhrases();

    FlxG.fixedTimestep = false;
    FlxG.game.focusLostFramerate = 60;
    FlxG.keys.preventDefaultKeys = [TAB];

    FlxG.updateFramerate = FlxG.drawFramerate = ClientPrefs.data.framerate;
    FlxG.mouse.enabled = FlxG.mouse.visible = true;

    #if !mobile
    if (Main.fpsVar != null) Main.fpsVar.visible = ClientPrefs.data.showFPS;
    #end

    #if LUA_ALLOWED llua.Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(scfunkin.backend.scripting.psych.LuaCallbackHandler.call)); #end
    Controls.instance = new Controls();
    ClientPrefs.loadDefaultKeys();
    #if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
    Highscore.load();

    if (FlxG.save.data.weekCompleted != null) scfunkin.states.menu.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

    #if DISCORD_ALLOWED
    DiscordClient.prepare();
    #end

    #if cpp
    cpp.NativeGc.enable(true);
    cpp.NativeGc.run(true);
    #end

    // Finish up loading debug tools.
    Debug.onGameStart();

    if (Main.checkGJKeysAndId())
    {
      GameJoltAPI.connect();
      GameJoltAPI.authDaUser(ClientPrefs.data.gjUser, ClientPrefs.data.gjToken, true);
    }

    if (ClientPrefs.data.gjUser.toLowerCase() == 'glowsoony') FlxG.scaleMode = new flixel.system.scaleModes.FillScaleMode();

    if (FlxG.save.data != null && FlxG.save.data.fullscreen) FlxG.fullscreen = FlxG.save.data.fullscreen;

    if (FlxG.save.data.flashing == null && !FlashingState.leftState)
    {
      FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
      MusicBeatState.switchState(new FlashingState());
    }
    else
      FlxG.switchState(Type.createInstance(TitleState, []));
  }
}
