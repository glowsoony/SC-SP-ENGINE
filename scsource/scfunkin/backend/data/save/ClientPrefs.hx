package scfunkin.backend.data.save;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import scfunkin.states.TitleState;

class ClientPrefs
{
  public static var data:SaveVariables = {};
  public static var defaultData:SaveVariables = {};

  // Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
  public static var keyBinds:Map<String, Array<FlxKey>> = [
    // Key Bind, Name for ControlsSubState
    'note_up' => [W, UP],
    'note_left' => [A, LEFT],
    'note_down' => [S, DOWN],
    'note_right' => [D, RIGHT],
    'ui_up' => [W, UP],
    'ui_left' => [A, LEFT],
    'ui_down' => [S, DOWN],
    'ui_right' => [D, RIGHT],
    'accept' => [SPACE, ENTER],
    'back' => [BACKSPACE, ESCAPE],
    'pause' => [ENTER, ESCAPE],
    'reset' => [R],
    'volume_mute' => [ZERO],
    'volume_up' => [NUMPADPLUS, PLUS],
    'volume_down' => [NUMPADMINUS, MINUS],
    'debug_1' => [SEVEN],
    'debug_2' => [EIGHT],
    'debug_3' => [SIX],
    'space' => [SPACE]
  ];
  public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
    'note_up' => [DPAD_UP, Y],
    'note_left' => [DPAD_LEFT, X],
    'note_down' => [DPAD_DOWN, A],
    'note_right' => [DPAD_RIGHT, B],
    'ui_up' => [DPAD_UP, LEFT_STICK_DIGITAL_UP],
    'ui_left' => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
    'ui_down' => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
    'ui_right' => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
    'accept' => [A, START],
    'back' => [B],
    'pause' => [START],
    'reset' => [BACK]
  ];
  public static var defaultKeys:Map<String, Array<FlxKey>> = null;
  public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

  public static function resetKeys(controller:Null<Bool> = null) // Null = both, False = Keyboard, True = Controller
  {
    if (controller != true) for (key in keyBinds.keys())
      if (defaultKeys.exists(key)) keyBinds.set(key, defaultKeys.get(key).copy());
    if (controller != false) for (button in gamepadBinds.keys())
      if (defaultButtons.exists(button)) gamepadBinds.set(button, defaultButtons.get(button).copy());
  }

  public static function clearInvalidKeys(key:String)
  {
    var keyBind:Array<FlxKey> = keyBinds.get(key);
    var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
    while (keyBind != null && keyBind.contains(NONE))
      keyBind.remove(NONE);
    while (gamepadBind != null && gamepadBind.contains(NONE))
      gamepadBind.remove(NONE);
  }

  public static function loadDefaultKeys()
  {
    defaultKeys = keyBinds.copy();
    defaultButtons = gamepadBinds.copy();
  }

  public static function saveSettings()
  {
    for (key in Reflect.fields(data))
    {
      Debug.logTrace('saved variable: $key');
      Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
    }
    #if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
    flush();

    // Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
    var save:FlxSave = new FlxSave();
    save.bind('controls_v3', scfunkin.utils.CoolUtil.getSavePath());
    save.data.keyboard = keyBinds;
    save.data.gamepad = gamepadBinds;
    flush(save);
    FlxG.log.add("Settings saved!");
  }

  public static function flush(?save:FlxSave):Void
  {
    if (save != null) save.flush();
    else
      FlxG.save.flush();
  }

  public static function loadPrefs()
  {
    // Prevent crashes if the save data is corrupted.
    scfunkin.utils.SerializerUtil.initSerializer();

    #if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

    for (key in Reflect.fields(data))
      if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key)) Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));

    if (Main.fpsVar != null)
    {
      Main.fpsVar.visible = data.showFPS;
    }

    #if (!html && ! switch)
    if (FlxG.save.data.framerate == null)
    {
      final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
      data.framerate = Std.int(FlxMath.bound(refreshRate, 1, 240));
    }
    #end

    if (data.framerate > FlxG.drawFramerate)
    {
      FlxG.updateFramerate = data.framerate;
      FlxG.drawFramerate = data.framerate;
    }
    else
    {
      FlxG.drawFramerate = data.framerate;
      FlxG.updateFramerate = data.framerate;
    }

    if (FlxG.save.data.gameplaySettings != null)
    {
      var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
      for (name => value in savedMap)
        data.gameplaySettings.set(name, value);
    }

    // flixel automatically saves your volume!
    if (FlxG.save.data.volume != null) FlxG.sound.volume = FlxG.save.data.volume;
    if (FlxG.save.data.mute != null) FlxG.sound.muted = FlxG.save.data.mute;

    #if DISCORD_ALLOWED DiscordClient.check(); #end
  }

  public static function keybindSaveLoad()
  {
    // controls on a separate save file
    var save:FlxSave = new FlxSave();
    save.bind('controls_v3', scfunkin.utils.CoolUtil.getSavePath());
    if (save != null)
    {
      if (save.data.keyboard != null)
      {
        var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;
        for (control => keys in loadedControls)
        {
          if (keyBinds.exists(control)) keyBinds.set(control, keys);
        }
      }
      if (save.data.gamepad != null)
      {
        var loadedControls:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;
        for (control => keys in loadedControls)
        {
          if (gamepadBinds.exists(control)) gamepadBinds.set(control, keys);
        }
      }
      reloadVolumeKeys();
    }
  }

  inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
  {
    if (!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
    return /*PlayState.isStoryMode ? defaultValue : */ (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
  }

  public static function reloadVolumeKeys()
  {
    Main.muteKeys = keyBinds.get('volume_mute').copy();
    Main.volumeDownKeys = keyBinds.get('volume_down').copy();
    Main.volumeUpKeys = keyBinds.get('volume_up').copy();
    toggleVolumeKeys(true);
  }

  public static function toggleVolumeKeys(?turnOn:Bool = true)
  {
    final emptyArray = [];
    FlxG.sound.muteKeys = turnOn ? Main.muteKeys : emptyArray;
    FlxG.sound.volumeDownKeys = turnOn ? Main.volumeDownKeys : emptyArray;
    FlxG.sound.volumeUpKeys = turnOn ? Main.volumeUpKeys : emptyArray;
  }

  public static function getkeys(keyname:String, separator:String = ' | ') // for lazyness
  {
    var keys:Array<String> = [];
    for (i in 0...2)
    {
      var randomKey:String = scfunkin.play.input.InputFormatter.getKeyName(keyBinds.get(keyname)[i]);
      keys[i] = randomKey;
    }
    return keys[0] == '---' ? keys[1] : keys[1] == '---' ? keys[0] : keys[0] + separator + keys[1];
  }

  public static function splashOption(type:String):Bool
  {
    switch (type)
    {
      case 'Player':
        return (data.splashOption == 'Player' || data.splashOption == 'Both') ? true : false;
      default:
        return (data.splashOption == 'Opponent' || data.splashOption == 'Both') ? true : false;
    }
    return false;
  }

  public static function get(key:String, isDefault:Bool = false):Dynamic
    return Reflect.field(isDefault ? defaultData : data, key);

  public static function set(key:String, value:Dynamic, isDefault:Bool = false):Void
    Reflect.setField(isDefault ? defaultData : data, value, key);

  public static function getKey(key:String, isDefault:Bool = false):Array<FlxKey>
    return isDefault ? defaultKeys.get(key) : keyBinds.get(key);

  public static function setKey(key:String, newKeys:Array<FlxKey>, isDefault:Bool = false):Void
    isDefault ? defaultKeys.set(key, newKeys) : keyBinds.set(key, newKeys);

  public static function getGamepadBind(bind:String, isDefault:Bool = false):Array<FlxGamepadInputID>
    return isDefault ? defaultButtons.get(bind) : gamepadBinds.get(bind);

  public static function setGamepadBind(bind:String, newBinds:Array<FlxGamepadInputID>, isDefault:Bool = false):Void
    isDefault ? defaultButtons.set(bind, newBinds) : gamepadBinds.set(bind, newBinds);
}
