package scfunkin.backend.scripting;

class ScriptPreset
{
  public static function scriptPresetVariables():#if haxe3 Map<String, Dynamic> #else Hash<Dynamic> #end
  {
    return [
      // Haxe related stuff
      "Std" => Std,
      "Math" => Math,
      "Reflect" => Reflect,
      "StringTools" => StringTools,
      "Json" => haxe.Json,
      // OpenFL & Lime related stuff
      "Assets" => openfl.utils.Assets,
      "Application" => lime.app.Application,
      "GraphicsShader" => openfl.display.GraphicsShader,
      "Main" => Main,
      "ShaderFilter" => openfl.filters.ShaderFilter,
      "window" => lime.app.Application.current.window,
      // Flixel related stuff
      "FlxG" => flixel.FlxG,
      "FlxSprite" => flixel.FlxSprite,
      "FlxBasic" => flixel.FlxBasic,
      "FlxCamera" => flixel.FlxCamera,
      "state" => flixel.FlxG.state,
      "FlxEase" => flixel.tweens.FlxEase,
      "FlxTween" => flixel.tweens.FlxTween,
      "FlxSound" => flixel.sound.FlxSound,
      "FlxAssets" => flixel.system.FlxAssets,
      "FlxMath" => flixel.math.FlxMath,
      "FlxGroup" => flixel.group.FlxGroup,
      "FlxTypedGroup" => flixel.group.FlxGroup.FlxTypedGroup,
      "FlxSpriteGroup" => flixel.group.FlxSpriteGroup,
      "FlxTypeText" => flixel.addons.text.FlxTypeText,
      "FlxText" => flixel.text.FlxText,
      "FlxTimer" => flixel.util.FlxTimer, // Flixel-addons related stuff
      #if (sys && !flash)
      "FlxRuntimeShader" => flixel.addons.display.FlxRuntimeShader,
      #end
      // Engine related suff + Folder they are located in.
      // Backend
      #if ACHIEVEMENTS_ALLOWED
      "Achievements" => scfunkin.backend.misc.Achievements,
      #end
      "Conductor" => scfunkin.play.Conductor,
      "ClientPrefs" => scfunkin.backend.data.save.ClientPrefs,
      "CoolUtil" => scfunkin.utils.CoolUtil,
      #if DISCORD_ALLOWED
      "Discord" => scfunkin.backend.misc.Discord.DiscordClient,
      #end
      "Language" => scfunkin.backend.misc.Language,
      "Mods" => scfunkin.backend.assets.Mods,
      "Paths" => scfunkin.backend.assets.Paths,
      "PsychCamera" => scfunkin.objects.misc.PsychCamera,
      // CodenameEngine
      // -->Shaders
      "FunkinShader" => scfunkin.shaders.codename.FunkinShader,
      "CustomShader" => scfunkin.shaders.codename.CustomShader,
      // Cutscenes
      "CutsceneHandler" => scfunkin.objects.cutscenes.CutsceneHandler,
      "DialogueBox" => scfunkin.objects.cutscenes.DialogueBox,
      "DialogueBoxPsych" => scfunkin.objects.cutscenes.DialogueBoxPsych,
      // Input
      "Controls" => scfunkin.play.input.Controls,
      // Objects
      "Alphabet" => scfunkin.objects.ui.Alphabet,
      "AttachedSprite" => scfunkin.objects.ui.AttachedSprite,
      "AttachedText" => scfunkin.objects.ui.AttachedText,
      "BGSprite" => scfunkin.objects.ui.BGSprite,
      "Character" => scfunkin.objects.ui.Character,
      #if flxanimate "FlxAnimate" => FlxAnimate, #end
      "FunkinSCSprite" => FunkinSCSprite,
      "HealthIcon" => scfunkin.objects.ui.HealthIcon,
      "Note" => scfunkin.objects.note.Note,
      "StrumArrow" => scfunkin.objects.note.StrumArrow,
      // --> stagecontent
      "Stage" => scfunkin.play.stage.Stage,
      // Options
      "Options" => scfunkin.states.substates.options.OptionsState,
      "ModSettingsSubState" => scfunkin.states.substates.options.ModSettingsSubState,
      // PsychLua
      "CustomFlxColor" => scfunkin.backend.scripting.psych.CustomFlxColor,
      #if LUA_ALLOWED
      "FunkinLua" => scfunkin.backend.scripting.psych.FunkinLua,
      #end
      // Shaders
      "ColorSwap" => scfunkin.shaders.ColorSwap,
      // States
      "FreeplayState" => scfunkin.states.freeplay.FreeplayState,
      "MainMenuState" => scfunkin.states.MainMenuState,
      "PlayState" => scfunkin.states.PlayState,
      "StoryMenuState" => scfunkin.states.menu.StoryMenuState,
      "TitleState" => scfunkin.states.TitleState,
      // SubStates
      "GameOverSubstate" => scfunkin.states.substates.GameOverSubstate,
      "PauseSubState" => scfunkin.states.substates.PauseSubState,
      // External Usages For Engine
      "Countdown" => scfunkin.backend.misc.Countdown,
      "HenchmenKillState" => scfunkin.play.stage.HenchmenKillState
    ];
  }

  public static function codenameAbstracts():#if haxe3 Map<String, Dynamic> #else Hash<Dynamic> #end
  {
    return [
      "FlxPoint" => scfunkin.utils.CoolUtil.getMacroAbstractClass("flixel.math.FlxPoint"),
      "FlxAxes" => scfunkin.utils.CoolUtil.getMacroAbstractClass("flixel.util.FlxAxes"),
      "FlxColor" => scfunkin.utils.CoolUtil.getMacroAbstractClass("flixel.util.FlxColor")
    ];
  }
}
