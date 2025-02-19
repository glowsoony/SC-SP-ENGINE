package scfunkin.states;

// If you want to add your stage to the game, copy states/stages/Template.hx,
// and put your stage code there, then, on PlayState, search for
// "switch (curStage)", and add your stage to that list.
// If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
// "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
// "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
// "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
// "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
import flixel.ui.FlxBar;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.addons.effects.FlxTrail;
import flixel.addons.display.FlxRuntimeShader;
import flixel.addons.display.FlxBackdrop;
import lime.app.Application;
import lime.utils.Assets;
import openfl.events.KeyboardEvent;
import openfl.utils.Assets as OpenFlAssets;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import tjson.TJSON as Json;
import scfunkin.objects.cutscenes.CutsceneHandler;
import scfunkin.objects.cutscenes.DialogueBoxPsych;
import scfunkin.states.menu.StoryMenuState;
import scfunkin.states.MusicBeatState.subStates;
import scfunkin.states.freeplay.FreeplayState;
import scfunkin.states.editors.ChartingState;
import scfunkin.states.editors.CharacterEditorState;
import scfunkin.states.substates.PauseSubState;
import scfunkin.states.substates.GameOverSubstate;
import scfunkin.states.substates.ResultsScreenKadeSubstate;
import scfunkin.objects.ui.*;
import scfunkin.objects.misc.*;
import scfunkin.objects.*;
import scfunkin.objects.note.Note.EventNote;
import scfunkin.utils.SoundUtil;
import scfunkin.utils.TweenUtil;
import scfunkin.utils.TimerUtil;
import scfunkin.backend.data.judgement.*;
import scfunkin.backend.data.files.*;
import scfunkin.backend.misc.Countdown;
import scfunkin.backend.misc.HelperFunctions;
import scfunkin.backend.misc.CustomArrayGroup;
import scfunkin.play.song.data.Highscore;
import scfunkin.play.song.SongEvents;
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
import scfunkin.backend.scripting.*;
import crowplexus.iris.Iris;
#end

class PlayState extends MusicBeatState
{
  public var bfStrumStyle:String = "";
  public var dadStrumStyle:String = "";

  public static var inResults:Bool = false;

  public static var tweenManager:FlxTweenManager = null;
  public static var timerManager:FlxTimerManager = null;

  // event variables
  public var isCameraOnForcedPos:Bool = false;

  public var BF_X:Float = 770;
  public var BF_Y:Float = 450;
  public var DAD_X:Float = 100;
  public var DAD_Y:Float = 100;
  public var GF_X:Float = 400;
  public var GF_Y:Float = 130;
  public var MOM_X:Float = 100;
  public var MOM_Y:Float = 100;

  public var songSpeedTween:FlxTween;
  public var songSpeed(default, set):Float = 1;
  public var songSpeedType:String = "multiplicative";
  public var noteKillOffset:Float = 350;

  public var playbackRate(default, set):Float = 1;

  public static var curStage:String = '';
  public static var stageUI:String = "normal";
  public static var isPixelStage(get, never):Bool;

  @:noCompletion
  static function get_isPixelStage():Bool
    return stageUI == "pixel" || stageUI.endsWith("-pixel");

  public static var SONG:Song = null;
  public static var isStoryMode:Bool = false;
  public static var storyWeek:Int = 0;
  public static var storyPlaylist:Array<String> = [];
  public static var storyDifficulty:Int = 1;

  public var inst:FlxSound;
  public var vocals:FlxSound;
  public var opponentVocals:FlxSound;
  public var splitVocals:Bool = false;

  public var dad:Character = null;
  public var gf:Character = null;
  public var mom:Character = null;
  public var boyfriend:Character = null;

  public var preloadChar:Character = null;

  public var camFollow:FlxObject;
  public var prevCamFollow:FlxObject;

  public var playerStrums:StrumLine = new StrumLine(0, 'BF');
  public var opponentStrums:StrumLine = new StrumLine(1, 'DAD');

  public var continueBeatBop:Bool = true;
  public var camZooming:Bool = false;
  public var camZoomingMult:Int = 4;
  public var camZoomingMultStep:Int = 16;
  public var camZoomingMultSec:Int = 1;
  public var camZoomingBop:Float = 1;
  public var camZoomingBopStep:Float = 1;
  public var camZoomingBopSec:Float = 1;
  public var camZoomingDecay:Float = 1;
  public var maxCamZoom:Float = 1.35;
  public var curSong:String = "";

  public var generatedMusic:Bool = false;
  public var endingSong:Bool = false;
  public var startingSong:Bool = false;

  public static var changedDifficulty:Bool = false;
  public static var chartingMode:Bool = false;
  public static var modchartMode:Bool = false;

  // Gameplay settings
  public var healthGain:Float = 1;
  public var healthLoss:Float = 1;
  public var showCaseMode:Bool = false;
  public var guitarHeroSustains:Bool = false;
  public var instakillOnMiss:Bool = false;
  public var cpuControlled:Bool = false;
  public var practiceMode:Bool = false;
  public var opponentMode(default, set):Bool = false;

  var you:FlxText = new FlxText(0, 0, 200, "YOU", 60);
  var youDuration:Float = 7;

  function showYou(value:Bool)
  {
    FlxTween.cancelTweensOf(you);
    you.alpha = 1;
    you.x = value ? 250 : 890;
    you.y = 180;
    FlxTween.tween(you, {alpha: 0}, youDuration, {ease: FlxEase.quadOut});
  }

  function set_opponentMode(value:Bool):Bool
  {
    if (dad != null) dad.holdTimerType = value ? "Player" : "Opponent";
    if (boyfriend != null) boyfriend.holdTimerType = value ? "Opponent" : "Player";

    playerStrums.characterStrumlineType = value ? 'DAD' : 'BF';
    opponentStrums.characterStrumlineType = value ? 'BF' : 'DAD';

    showYou(value);

    opponentStrums.playKeys = value;
    playerStrums.playKeys = !value;

    playerStrums.calls.onHit = function(daNote:Note) {
      if (daNote.allowNoteToHit)
      {
        if (!value)
        {
          if (playerStrums.cpuControlled
            && !daNote.blockHit
            && daNote.canBeHit
            && ((daNote.isSustainNote && daNote.prevNote.wasGoodHit) || daNote.strumTime <= Conductor.songPosition))
          {
            goodNoteHit(daNote);
            playerStrums.calls.noteHit.dispatch(daNote);
          }
        }
        else
        {
          if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
          {
            goodNoteHit(daNote);
            playerStrums.calls.noteHit.dispatch(daNote);
          }
        }
      }
    }
    opponentStrums.calls.onHit = function(daNote:Note) {
      if (daNote.allowNoteToHit)
      {
        if (!value)
        {
          if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
          {
            opponentNoteHit(daNote);
            opponentStrums.calls.noteHit.dispatch(daNote);
          }
        }
        else
        {
          if (opponentStrums.cpuControlled
            && !daNote.blockHit
            && daNote.canBeHit
            && ((daNote.isSustainNote && daNote.prevNote.wasGoodHit) || daNote.strumTime <= Conductor.songPosition))
          {
            opponentNoteHit(daNote);
            opponentStrums.calls.noteHit.dispatch(daNote);
          }
        }
      }
    }

    return opponentMode = value;
  }

  public var holdsActive:Bool = true;
  public var notITGMod:Bool = true;

  public var pressMissDamage:Float = 0.05;

  public var camGame:FlxCamera;
  public var camVideo:FlxCamera = CameraTools.createCamera();
  public var camUnderUI:FlxCamera = CameraTools.createCamera();
  public var camHUD:FlxCamera = CameraTools.createCamera();
  public var camOther:FlxCamera = CameraTools.createCamera();
  public var camNoteStuff:FlxCamera = CameraTools.createCamera();
  public var camStuff:FlxCamera = CameraTools.createCamera();
  public var mainCam:FlxCamera = CameraTools.createCamera();
  public var camPause:FlxCamera = CameraTools.createCamera();

  public var cameraSpeed:Float = 1;

  public static var seenCutscene:Bool = false;
  public static var deathCounter:Int = 0;

  public var defaultCamZoom:Float = 1.05;

  // how big to stretch the pixel art assets
  public static var daPixelZoom:Float = 6;

  public var inCutscene:Bool = false;
  public var inCinematic:Bool = false;

  public var arrowsGenerated:Bool = false;
  public var arrowsAppeared:Bool = false;

  public var skipCountdown:Bool = false;
  public var songLength:Float = 0;

  #if DISCORD_ALLOWED
  // Discord RPC variables
  public var storyDifficultyText:String = "";
  public var detailsText:String = "";
  public var detailsPausedText:String = "";
  #end

  // From kade but from bolo's kade (thanks!)
  #if (VIDEOS_ALLOWED && hxvlc)
  var reserveVids:Array<VideoSprite> = [];

  public var daVideoGroup:FlxTypedGroup<VideoSprite> = null;
  #end

  // Achievement shit
  var keysPressed:Array<Int> = [];
  var boyfriendIdleTime:Float = 0.0;
  var boyfriendIdled:Bool = false;

  // Lua shit
  public static var instance:PlayState;
  public static var timeToStart:Float = 0;

  // Song
  public var songName:String;

  // Callbacks for stages
  public var startCallback:Void->Void = null;
  public var endCallback:Void->Void = null;

  public var usesHUD:Bool = false;

  public function addObject(object:FlxBasic)
    add(object);

  public function insertObject(pos:Int, object:FlxBasic)
    insert(pos, object);

  public function removeObject(object:FlxBasic)
    remove(object);

  public function destroyObject(object:FlxBasic)
    object.destroy();

  private var triggeredAlready:Bool = false;

  // Edwhak muchas gracias!
  public static var forceMiddleScroll:Bool = false; // yeah
  public static var forceRightScroll:Bool = false; // so modcharts that NEED rightscroll will be forced (mainly for player vs enemy classic stuff like bf vs someone)
  public static var prefixMiddleScroll:Bool = false;
  public static var prefixRightScroll:Bool = false; // so if someone force the scroll in chart and clientPrefs are the other option it will be autoLoaded again
  public static var savePrefixScrollM:Bool = false;
  public static var savePrefixScrollR:Bool = false;

  public var stage:Stage = null;

  // for testing
  #if debug
  public var delayBar:FlxSprite;
  public var delayBarBg:FlxSprite;
  public var delayBarTxt:FlxText;
  #end

  public static var isPixelNotes:Bool = false;
  public static var nextReloadAll:Bool = false;

  public var picoSpeakerAllowed:Bool = false;

  var prevScoreData:HighScoreData = null;

  public var instPrecache:Array<SoundMusicPropsCheck> = [];
  public var vocalPrecache:Array<SoundMusicPropsCheck> = [];
  public var opponentVocalPrecache:Array<SoundMusicPropsCheck> = [];

  public var strumLines:StrumLineGroup = new StrumLineGroup();

  #if FunkinModchart
  public var modManager:Manager;
  #end

  public var hud:Hud;
  public var songEvents:SongEvents = new SongEvents();

  private static var _lastLoadedModDirectory:String = '';

  override public function create()
  {
    _lastLoadedModDirectory = Mods.currentModDirectory;
    Paths.clearStoredMemory();
    if (nextReloadAll)
    {
      Paths.clearUnusedMemory();
      Language.reloadPhrases();
    }
    nextReloadAll = false;

    if (SONG == null)
    {
      Debug.displayAlert("PlayState Was Not Able To Load Any Songs!", "PlayState Error");
      MusicBeatState.switchState(new FreeplayState());
      return;
    }

    you.setFormat(null, 60, FlxColor.TRANSPARENT);
    you.setBorderStyle(OUTLINE, FlxColor.WHITE, 2);
    songEvents.onEventPushed = function(subEvent) {
      var funcArgs:Array<Dynamic> = [subEvent.name];
      for (i in 0...subEvent.params.length - 1)
        funcArgs.push(subEvent.params[i] != null ? subEvent.params[i] : "");
      funcArgs.push(subEvent.time);
      callOnScripts('onEventPushed', [subEvent.name, subEvent.params, subEvent.time]);
      callOnScripts('onEventPushedLegacy', funcArgs);
    }

    gfSpeed = 1;
    songName = Paths.formatToSongPath(SONG.getSongData('songId'));
    if (!SONG.getSongData('options').disableCaching)
    {
      if (Paths.fileExists('data/songs/$songName/precache.json', TEXT))
      {
        final rawFile:String = Paths.getTextFromFile('data/songs/$songName/precache.json');
        if (rawFile != null && rawFile.length > 0)
        {
          try
          {
            final precache = tjson.TJSON.parse(rawFile);
            if (precache != null)
            {
              if (precache.characters != null && precache.characters.length > 0)
              {
                final characters:Array<String> = precache.characters;
                for (character in characters)
                {
                  cacheCharacter(character);
                  Debug.logInfo('character precached, $character');
                }
              }

              if (precache.sounds != null && precache.sounds.length > 0)
              {
                final sounds:Array<String> = precache.sounds;
                for (sound in sounds)
                {
                  Paths.sound(sound);
                  Debug.logInfo('sound precached, $sound');
                }
              }

              if (precache.images != null && precache.images.length > 0)
              {
                final images:Array<String> = precache.images;
                for (image in images)
                {
                  Paths.image(image);
                  Debug.logInfo('image precached, $image');
                }
              }

              if (precache.music != null && precache.music.length > 0)
              {
                final music:Array<String> = precache.music;
                for (snd in music)
                {
                  Paths.music(snd);
                  Debug.logInfo('music precached, $snd');
                }
              }

              if (precache.instrumentals != null && precache.instrumentals.length > 0)
              {
                final instrumentals:Array<SoundMusicPropsCheck> = precache.instrumentals;
                var amount:Int = 0;
                for (instrumental in instrumentals)
                {
                  amount++;
                  instPrecache.push(
                    {
                      song: instrumental.song,
                      prefix: instrumental.prefix,
                      suffix: instrumental.suffix,
                      externVocal: instrumental.externVocal,
                      character: instrumental.character,
                      difficulty: instrumental.difficulty
                    });
                }
                Debug.logInfo('Amount of instrumentals precached $amount');
              }

              if (precache.vocals != null && precache.vocals.length > 0)
              {
                final vocals:Array<SoundMusicPropsCheck> = precache.vocals;
                var amount:Int = 0;
                for (vocal in vocals)
                {
                  amount++;
                  vocalPrecache.push(
                    {
                      song: vocal.song,
                      prefix: vocal.prefix,
                      suffix: vocal.suffix,
                      externVocal: vocal.externVocal,
                      character: vocal.character,
                      difficulty: vocal.difficulty
                    });
                }
                Debug.logInfo('Amount of vocals precached $amount');
              }

              if (precache.opponentVocals != null && precache.opponentVocals.length > 0)
              {
                final vocals:Array<SoundMusicPropsCheck> = precache.opponentVocals;
                var amount:Int = 0;
                for (vocal in vocals)
                {
                  amount++;
                  opponentVocalPrecache.push(
                    {
                      song: vocal.song,
                      prefix: vocal.prefix,
                      suffix: vocal.suffix,
                      externVocal: vocal.externVocal,
                      character: vocal.character,
                      difficulty: vocal.difficulty
                    });
                }

                Debug.logInfo('Amount of opponentVocals precached $amount');
              }

              if (precache.stages != null && precache.stages.length > 0)
              {
                final stages:Array<String> = precache.stages;
                for (stageName in stages)
                {
                  changeStage(stageName);
                  stage.onDestroy();
                  stage = null;
                  Debug.logInfo('stage ($stageName) precached');
                }
              }
            }
          }
          catch (e:haxe.Exception)
            Debug.logInfo([e.message, e.stack]);
        }
      }
    }

    // Set up stage stuff before any scripts, else no functioning playstate.
    if (SONG.getSongData('stage') == null || SONG.getSongData('stage')
      .length < 1) SONG.setSongData('stage', StageData.vanillaSongStage(Paths.formatToSongPath(SongJsonData.loadedSongName)));
    curStage = SONG.getSongData('stage');
    stage = new Stage(curStage);

    tweenManager = new FlxTweenManager();
    timerManager = new FlxTimerManager();

    startCallback = startCountdown;
    endCallback = endSong;

    if (alreadyEndedSong)
    {
      alreadyEndedSong = false;
      endSong();
    }

    alreadyEndedSong = paused = stoppedAllInstAndVocals = finishedSong = false;
    usesHUD = SONG.getSongData('options').usesHUD;

    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (codeNameScripts == null) (codeNameScripts = new scfunkin.backend.scripting.codename.ScriptPack("PlayState")).setParent(this);
    #end

    // Perfect spot to init HUD
    hud = new Hud();

    // for lua
    instance = this;
    PauseSubState.songName = null; // Reset to default
    PauseSubState.pauseCounter = 0;
    playbackRate = ClientPrefs.getGameplaySetting('songspeed');

    playerStrums.actualStrumLineID = 1;
    opponentStrums.actualStrumLineID = 0;

    inResults = false;

    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    // Force A Scroll
    if (SONG.getSongData('options').middleScroll && !ClientPrefs.data.middleScroll)
    {
      forceMiddleScroll = true;
      forceRightScroll = false;
      ClientPrefs.data.middleScroll = true;
    }
    else if (SONG.getSongData('options').rightScroll && ClientPrefs.data.middleScroll)
    {
      forceMiddleScroll = false;
      forceRightScroll = true;
      ClientPrefs.data.middleScroll = false;
    }

    savePrefixScrollR = (forceMiddleScroll && !ClientPrefs.data.middleScroll);
    savePrefixScrollM = (forceRightScroll && ClientPrefs.data.middleScroll);

    prefixRightScroll = !ClientPrefs.data.middleScroll;
    prefixMiddleScroll = ClientPrefs.data.middleScroll;

    // Gameplay settings
    healthGain = ClientPrefs.getGameplaySetting('healthgain');
    healthLoss = ClientPrefs.getGameplaySetting('healthloss');
    instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
    opponentMode = (ClientPrefs.getGameplaySetting('opponent') && !SONG.getSongData('options').blockOpponentMode);
    if (PlayState.isStoryMode && WeekData.getCurrentWeek().blockOpponentMode) opponentMode = false;
    practiceMode = ClientPrefs.getGameplaySetting('practice');
    cpuControlled = ClientPrefs.getGameplaySetting('botplay');
    showCaseMode = ClientPrefs.getGameplaySetting('showcasemode');
    holdsActive = ClientPrefs.getGameplaySetting('sustainnotesactive');
    notITGMod = ClientPrefs.getGameplaySetting('modchart');
    guitarHeroSustains = ClientPrefs.data.newSustainBehavior;

    playerStrums.characterStrumlineType = opponentMode ? 'DAD' : 'BF';
    opponentStrums.characterStrumlineType = opponentMode ? 'BF' : 'DAD';

    // Extra Stuff Needed FOR SCE
    CoolUtil.opponentModeActive = opponentMode;

    prevScoreData = Highscore.getSongScore(songName, storyDifficulty, opponentMode);
    Debug.logInfo([prevScoreData, songName, storyDifficulty]);

    Highscore.songHighScoreData = Highscore.resetScoreData();
    Highscore.songHighScoreData.mainData.name = songName;
    Highscore.songHighScoreData.mainData.difficulty = storyDifficulty;
    Highscore.songHighScoreData.mainData.opponentMode = opponentMode;
    if (isStoryMode)
    {
      Highscore.weekHighScoreData.mainData.name = WeekData.getWeekFileName();
      Highscore.weekHighScoreData.mainData.difficulty = storyDifficulty;
      Highscore.songHighScoreData.mainData.opponentMode = opponentMode;
    }

    // Game Camera (where stage and characters are)
    camGame = initPsychCamera();

    // Video Camera if you put funni videos or smth
    FlxG.cameras.add(camVideo, false);

    // for other stuff then the (Health Bar, scoreTxt, etc)
    FlxG.cameras.add(camUnderUI, false);

    // HUD Camera (Health Bar, scoreTxt, etc)
    FlxG.cameras.add(camHUD, false);

    // for jumescares and shit
    FlxG.cameras.add(camOther, false);

    // All Note Stuff Above HUD
    FlxG.cameras.add(camNoteStuff, false);

    // Stuff camera (stuff that are on top of everything but lower then the main camera)
    FlxG.cameras.add(camStuff, false);

    // Main Camera
    FlxG.cameras.add(mainCam, false);

    // The final one should be more but for this one rn it's the pauseCam
    FlxG.cameras.add(camPause, false);

    camNoteStuff.zoom = !usesHUD ? camHUD.zoom : 1;

    persistentUpdate = persistentDraw = true;

    Conductor.mapBPMChanges(SONG);
    Conductor.bpm = SONG.getSongData('bpm');

    #if DISCORD_ALLOWED
    // String that contains the mode defined here so it isn't necessary to call changePresence for each mode
    storyDifficultyText = Difficulty.getString();

    if (isStoryMode) detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
    else
      detailsText = "Freeplay";

    // String for when the game is paused
    detailsPausedText = "Paused - " + detailsText;
    #end

    GameOverSubstate.resetVariables();

    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    luaDebugGroup = new FlxTypedGroup<scfunkin.objects.ui.scripting.DebugLuaText>();
    luaDebugGroup.cameras = [camOther];
    add(luaDebugGroup);
    #end

    if (SONG.getSongData('characters').girlfriend == null
      || SONG.getSongData('characters').girlfriend.length < 1) SONG.getSongData('characters').girlfriend = 'gf'; // Fix for the Chart Editor

    gf = new Character(GF_X, GF_Y, SONG.getSongData('characters').girlfriend, 'GF');
    var gfOffset = new scfunkin.backend.misc.CharacterOffsets(SONG.getSongData('characters').girlfriend, false, true);
    var daGFX:Float = gfOffset.daOffsetArray[0];
    var daGFY:Float = gfOffset.daOffsetArray[1];
    startCharacterPos(gf);
    gf.x += daGFX;
    gf.y += daGFY;
    gf.scrollFactor.set(0.95, 0.95);
    gf.useGFSpeed = true;

    dad = new Character(DAD_X, DAD_Y, SONG.getSongData('characters').opponent, 'DAD');
    startCharacterPos(dad, true);
    dad.noteSkinStyleOfCharacter = SONG.getSongData('options').opponentNoteStyle;
    dad.strumSkinStyleOfCharacter = SONG.getSongData('options').opponentStrumStyle;
    if (dad.curCharacter.startsWith('gf')) dad.useGFSpeed = true;

    mom = new Character(MOM_X, MOM_X, SONG.getSongData('characters').secondOpponent, 'DAD');
    startCharacterPos(mom, true);

    if (SONG.getSongData('characters').secondOpponent == null || SONG.getSongData('characters').secondOpponent.length < 1)
    {
      mom.alpha = 0.0001;
      mom.missingCharacter = false;
      mom.visible = false;
    }

    boyfriend = new Character(BF_X, BF_Y, SONG.getSongData('characters').player, true, 'BF');
    startCharacterPos(boyfriend, false, true);
    boyfriend.noteSkinStyleOfCharacter = SONG.getSongData('options').playerNoteStyle;
    boyfriend.strumSkinStyleOfCharacter = SONG.getSongData('options').playerStrumStyle;

    hud.createHUD();

    stage.setupStageProperties(SONG.getSongData('songId'), true);
    curStage = stage.curStage;
    defaultCamZoom = stage.camZoom;
    cameraSpeed = stage.stageCameraSpeed;
    hud.cache();

    boyfriend.x += stage.bfXOffset;
    boyfriend.y += stage.bfYOffset;
    mom.x += stage.momXOffset;
    mom.y += stage.momYOffset;
    dad.x += stage.dadXOffset;
    dad.y += stage.dadYOffset;
    gf.x += stage.gfXOffset;
    gf.y += stage.gfYOffset;

    picoSpeakerAllowed = ((SONG.getSongData('characters').girlfriend == 'pico-speaker' || gf.curCharacter == 'pico-speaker')
      && !stage.hideGirlfriend);
    if (stage.hideGirlfriend) gf.alpha = 0.0001;
    if (picoSpeakerAllowed)
    {
      gf.useGFSpeed = null;
      gf.idleToTime = gf.isDancing = false;
    }

    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    // "GLOBAL" SCRIPTS
    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/global/'))
      for (file in FileSystem.readDirectory(folder))
      {
        #if LUA_ALLOWED
        if (file.toLowerCase().endsWith('.lua')) new FunkinLua(folder + file, 'PLAYSTATE');
        #end

        #if HSCRIPT_ALLOWED
        for (extn in CoolUtil.haxeExtensions)
          if (file.toLowerCase().endsWith('.$extn')) addScript(folder + file, scfunkin.backend.scripting.ScriptType.IRIS);
        #end
      }

    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/global/sc/'))
      for (file in FileSystem.readDirectory(folder))
        #if HSCRIPT_ALLOWED
        for (extn in CoolUtil.haxeExtensions)
          if (file.toLowerCase().endsWith('.$extn')) addScript(folder + file, scfunkin.backend.scripting.ScriptType.SC);
        #end

    #if (HSCRIPT_ALLOWED && HScriptImproved)
    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/global/advanced/'))
      for (file in FileSystem.readDirectory(folder))
        for (extn in CoolUtil.haxeExtensions)
          if (file.toLowerCase().endsWith('.$extn')) addScript(folder + file, scfunkin.backend.scripting.ScriptType.CODENAME);
    #end

    for (character in [gf, mom, dad, boyfriend])
      if (character != null) character.loadCharacterScript(character.curCharacter);
    #end

    dad.holdTimerType = opponentMode ? "Player" : "Opponent";
    boyfriend.holdTimerType = opponentMode ? "Opponent" : "Player";

    if (ClientPrefs.data.characters)
    {
      boyfriend.scrollFactor.set(stage.bfScrollFactor[0], stage.bfScrollFactor[1]);
      dad.scrollFactor.set(stage.dadScrollFactor[0], stage.dadScrollFactor[1]);
      gf.scrollFactor.set(stage.gfScrollFactor[0], stage.gfScrollFactor[1]);
    }

    if (boyfriend.deadChar != null) GameOverSubstate.characterName = boyfriend.deadChar;

    var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
    if (gf != null)
    {
      camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
      camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
    }

    if (dad.curCharacter.startsWith('gf') || dad.replacesGF)
    {
      dad.setPosition(GF_X, GF_Y);
      if (gf != null) gf.visible = false;
    }

    setCameraOffsets();

    if (ClientPrefs.data.background)
    {
      for (i in stage.toAdd)
        add(i);

      for (index => array in stage.layInFront)
      {
        switch (index)
        {
          case 0:
            if (ClientPrefs.data.characters) if (gf != null) add(gf);
            for (bg in array)
              add(bg);
          case 1:
            if (ClientPrefs.data.characters) add(dad);
            for (bg in array)
              add(bg);
          case 2:
            if (ClientPrefs.data.characters) if (mom != null) add(mom);
            for (bg in array)
              add(bg);
          case 3:
            if (ClientPrefs.data.characters) add(boyfriend);
            for (bg in array)
              add(bg);
          case 4:
            if (ClientPrefs.data.characters)
            {
              if (gf != null) add(gf);
              add(dad);
              if (mom != null) add(mom);
              add(boyfriend);
            }
            for (bg in array)
              add(bg);
        }
      }
    }
    else
    {
      if (ClientPrefs.data.characters)
      {
        if (gf != null)
        {
          gf.scrollFactor.set(0.95, 0.95);
          add(gf);
        }
        add(dad);
        if (mom != null) add(mom);
        add(boyfriend);
      }
    }

    if (stage.curStage == 'schoolEvil')
    {
      if (!ClientPrefs.data.lowQuality && ClientPrefs.data.characters)
      {
        final trail:FlxTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
        addBehindDad(trail);
      }
    }

    songEvents.onEventPushedUnique = function(event) {
      switch (event.name)
      {
        case "Change Character":
          cacheCharacter(event.params[1]);
        case 'Play Sound':
          Paths.sound(event.params[0]);
      }
      if (stage != null && !finishedSong) stage.eventPushedUniqueStage(event);
      for (call in ['onEventPushedUnique', 'eventPushedUnique'])
        callOnScripts(call, [event.name, event.params, event.time]);
    }
    songEvents.onEventPushedUniquePost = function(event) {
      if (stage != null && !finishedSong) stage.eventPushedStage(event);
    }
    songEvents.onEventEarlyTrigger = function(event):Float {
      var returnedValue:Null<Float> = callOnScripts('onEventEarlyTrigger', [event.name, event.params, event.time], true);
      if (returnedValue == null)
      {
        var funcArgs:Array<Dynamic> = [event.name];
        for (i in 0...event.params.length - 1)
          funcArgs.push(event.params[i] != null ? event.params[i] : "");
        funcArgs.push(event.time);
        returnedValue = callOnScripts('onEventEarlyTriggerLegacy', funcArgs, true);
        if (returnedValue == null)
        {
          returnedValue = callOnScripts('eventEarlyTrigger', [event.name, event.params, event.time], true);
          if (returnedValue == null) callOnScripts('eventEarlyTriggerLegacy', funcArgs, true);
        }
        return returnedValue;
      }
      return returnedValue;
    }

    final enabledHolds:Bool = ((!SONG.getSongData('options').disableHoldCovers && !SONG.getSongData('options').notITG)
      && ClientPrefs.data.holdCoverPlay);
    playerStrums.holdCovers.enabled = opponentStrums.holdCovers.enabled = enabledHolds;

    inCinematic = (isStoryMode && ((storyWeek == 5 && songName == 'winter-horrorland') || storyWeek == 7));

    Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;

    #if debug
    delayBarBg = new FlxSprite().makeGraphic(300, 30, FlxColor.BLACK);
    delayBarBg.screenCenter();
    delayBarBg.camera = game.mainCam;

    delayBar = new FlxSprite(640).makeGraphic(1, 22, FlxColor.WHITE);
    delayBar.scale.x = 0;
    delayBar.updateHitbox();
    delayBar.screenCenter(Y);
    delayBar.camera = game.mainCam;

    delayBarTxt = new FlxText(0, 312, 100, '0 ms', 32);
    delayBarTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    delayBarTxt.scrollFactor.set();
    delayBarTxt.borderSize = 2;
    delayBarTxt.screenCenter(X);
    delayBarTxt.camera = game.mainCam;

    add(delayBarBg);
    add(delayBar);
    add(delayBarTxt);
    #end

    strumLines.add(opponentStrums);
    strumLines.add(playerStrums);
    add(strumLines);

    for (strumLine in strumLines)
      strumLine.cpuControlled = cpuControlled;

    // like old psych stuff
    if (SONG.getSongData('notes')[0] != null) cameraTargeted = SONG.getSongData('notes')[0].mustHitSection != true ? 'dad' : 'bf';
    camZooming = true;

    add(hud);
    updateScore(false);

    generateSong();

    var arrowSetupStuffDAD:String = dad.strumSkin;
    var arrowSetupStuffBF:String = boyfriend.strumSkin;
    var songArrowSkins:Bool = (SONG.getSongData('options').strumSkin != null && SONG.getSongData('options').strumSkin.length > 0);

    if (arrowSetupStuffBF == null || arrowSetupStuffBF.length < 1)
      arrowSetupStuffBF = (!songArrowSkins ? (isPixelStage ? 'pixel' : 'normal') : SONG.getSongData('options')
      .strumSkin);
    else
      arrowSetupStuffBF = boyfriend.strumSkin;
    if (arrowSetupStuffDAD == null || arrowSetupStuffDAD.length < 1)
      arrowSetupStuffDAD = (!songArrowSkins ? (isPixelStage ? 'pixel' : 'normal') : SONG.getSongData('options')
      .strumSkin);
    else
      arrowSetupStuffDAD = dad.strumSkin;

    final skippedAhead:Bool = (skipCountdown || startOnTime > 0);
    if (!skipStrumSpawn)
    {
      setupArrowStuff(0, arrowSetupStuffDAD); // opponent
      setupArrowStuff(1, arrowSetupStuffBF); // player
      updateDefaultPos();
      if (!arrowsAppeared)
      {
        appearStrumArrows(skippedAhead ? false : ((!isStoryMode || storyPlaylist.length >= 3 || songName == 'tutorial')
          && !skipArrowStartTween
          && !disabledIntro));
      }
      playerStrums.setHoldCoverParents(playerStrums.length);
      opponentStrums.setHoldCoverParents(opponentStrums.length);
    }
    #if FunkinModchart
    if (notITGMod && SONG.getSongData('options').notITG)
    {
      modManager = new Manager();
      add(modManager);
    }
    #end

    #if (VIDEOS_ALLOWED && hxvlc)
    daVideoGroup = new FlxTypedGroup<VideoSprite>();
    add(daVideoGroup);
    #end

    camFollow = new FlxObject();
    camFollow.setPosition(camPos.x, camPos.y);
    camPos.put();

    if (prevCamFollow != null)
    {
      camFollow = prevCamFollow;
      prevCamFollow = null;
    }
    add(camFollow);

    FlxG.camera.follow(camFollow, LOCKON, 0);
    FlxG.camera.zoom = defaultCamZoom;
    FlxG.camera.snapToTarget();

    FlxG.fixedTimestep = false;

    if (ClientPrefs.data.breakTimer)
    {
      final noteTimer:scfunkin.objects.ui.NoteTimer = new scfunkin.objects.ui.NoteTimer(this);
      noteTimer.cameras = [camStuff];
      add(noteTimer);
    }

    you.cameras = [camHUD];
    add(you);

    for (strumLine in strumLines)
    {
      strumLine.cameras = [usesHUD ? camHUD : camNoteStuff];
      strumLine.calls.onSpawnNoteLua = function(notes:FlxTypedGroup<Note>, dunceNote:Note) {
        callOnLuas('onSpawnNote', [
          notes.members.indexOf(dunceNote),
          dunceNote.noteData,
          dunceNote.noteType,
          dunceNote.isSustainNote,
          dunceNote.strumTime
        ]);
        strumLine.calls.spawnNoteLua.dispatch(notes, dunceNote);
      }

      strumLine.calls.onSpawnNoteHx = function(dunceNote:Note) {
        callOnAllHS('onSpawnNote', [dunceNote]);
        strumLine.calls.spawnNoteHx.dispatch(dunceNote);
      }

      strumLine.calls.onSpawnNoteLuaPost = function(notes:FlxTypedGroup<Note>, dunceNote:Note) {
        callOnLuas('onSpawnNotePost', [
          notes.members.indexOf(dunceNote),
          dunceNote.noteData,
          dunceNote.noteType,
          dunceNote.isSustainNote,
          dunceNote.strumTime
        ]);
        strumLine.calls.spawnNoteLuaPost.dispatch(notes, dunceNote);
      }

      strumLine.calls.onSpawnNoteHxPost = function(dunceNote:Note) {
        callOnAllHS('onSpawnNote', [dunceNote]);
        strumLine.calls.spawnNoteHx.dispatch(dunceNote);
      }
      strumLine.calls.onKeyPressedPre = function(key):Dynamic {
        // had to name it like this else it'd break older scripts lol
        return callOnScripts('onKeyPressPre', [key]);
      }
      strumLine.calls.onKeyPressed = function(key) {
        callOnScripts('onKeyPress', [key]);
      }
      strumLine.calls.onKeyReleasedPre = function(key):Dynamic {
        return callOnScripts('onKeyReleasedPre', [key]);
      }
      strumLine.calls.onKeyReleased = function(key) {
        callOnScripts('onKeyRelease', [key]);
      }
    }
    playerStrums.calls.onNoteKeyHit = function(note) {
      goodNoteHit(note);
    }
    playerStrums.calls.onGhostTap = function(key) {
      callOnScripts('onGhostTap', [key]);
    }
    playerStrums.calls.onMissPress = function(key) {
      if (!playerStrums.ghostTapping) noteMissPress(key, playerStrums);
    }
    playerStrums.calls.onHit = function(daNote:Note) {
      if (daNote.allowNoteToHit)
      {
        if (!opponentMode)
        {
          if (playerStrums.cpuControlled
            && !daNote.blockHit
            && daNote.canBeHit
            && ((daNote.isSustainNote && daNote.prevNote.wasGoodHit) || daNote.strumTime <= Conductor.songPosition))
          {
            goodNoteHit(daNote);
            playerStrums.calls.noteHit.dispatch(daNote);
          }
        }
        else
        {
          if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
          {
            goodNoteHit(daNote);
            playerStrums.calls.noteHit.dispatch(daNote);
          }
        }
      }
    }
    opponentStrums.calls.onNoteKeyHit = function(daNote:Note) {
      opponentNoteHit(daNote);
    }
    opponentStrums.calls.onHit = function(daNote:Note) {
      if (daNote.allowNoteToHit)
      {
        if (!opponentMode)
        {
          if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
          {
            opponentNoteHit(daNote);
            opponentStrums.calls.noteHit.dispatch(daNote);
          }
        }
        else
        {
          if (opponentStrums.cpuControlled
            && !daNote.blockHit
            && daNote.canBeHit
            && ((daNote.isSustainNote && daNote.prevNote.wasGoodHit) || daNote.strumTime <= Conductor.songPosition))
          {
            opponentNoteHit(daNote);
            opponentStrums.calls.noteHit.dispatch(daNote);
          }
        }
      }
    }
    playerStrums.calls.onMissed = function(daNote:Note) {
      if (daNote.allowDeleteAndMiss && !playerStrums.cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
      {
        noteMiss(daNote, playerStrums);
        playerStrums.calls.noteMissed.dispatch(daNote);
      }
    }
    playerStrums.characters.push(boyfriend);
    playerStrums.calls.onHoldingKey = function() {
      #if ACHIEVEMENTS_ALLOWED
      checkForAchievement(['oversinging']);
      #end
    }
    opponentStrums.characters.push(dad);

    startingSong = true;
    songInfo = Main.appName + ' - Song Playing: ${songName.toUpperCase()} - ${Difficulty.getString()}';

    if (ClientPrefs.data.characters)
    {
      for (character in [dad, boyfriend, gf, mom])
        if (character != null) character.dance();
    }

    if (inCutscene) cancelAppearArrows();

    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    for (notetype in noteTypes)
      startNoteTypesNamed(notetype);
    songEvents.forEachEventPushed(function(event) {
      startEventsNamed(event);
    });
    #end
    noteTypes = null;
    songEvents.tempEventsPushed = null;
    songEvents.onTriggerEvent = triggerPlayStateEvent;

    // SONG SPECIFIC SCRIPTS
    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/songs/$songName/'))
      for (file in FileSystem.readDirectory(folder))
      {
        #if LUA_ALLOWED
        if (file.toLowerCase().endsWith('.lua')) new FunkinLua(folder + file, 'PLAYSTATE');
        #end

        #if HSCRIPT_ALLOWED
        for (extn in CoolUtil.haxeExtensions)
          if (file.toLowerCase().endsWith('.$extn')) addScript(folder + file, scfunkin.backend.scripting.ScriptType.IRIS);
        #end
      }

    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/songs/$songName/sc/'))
      for (file in FileSystem.readDirectory(folder))
        #if HSCRIPT_ALLOWED
        for (extn in CoolUtil.haxeExtensions)
          if (file.toLowerCase().endsWith('.$extn')) addScript(folder + file, scfunkin.backend.scripting.ScriptType.SC);
        #end

    #if (HSCRIPT_ALLOWED && HScriptImproved)
    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/songs/$songName/advanced/'))
      for (file in FileSystem.readDirectory(folder))
        for (extn in CoolUtil.haxeExtensions)
          if (file.toLowerCase().endsWith('.$extn')) addScript(folder + file, scfunkin.backend.scripting.ScriptType.CODENAME);
    #end
    #end

    callOnScripts('start', []);

    if (isStoryMode)
    {
      switch (songName)
      {
        case 'winter-horrorland':
          cancelAppearArrows();

        case 'roses':
          appearStrumArrows(false);

        case 'ugh', 'guns', 'stress':
          cancelAppearArrows();
      }
    }

    songEvents.applyEarlyTimeTrigger();
    if (startCallback != null) startCallback();
    hud.comboStats.onRecalculateRating = function(badHit:Bool = false) {
      setOnScripts('score', hud.comboStats.songScore);
      setOnScripts('misses', hud.comboStats.songMisses);
      setOnScripts('hits', hud.comboStats.songHits);
      setOnScripts('combo', hud.comboStats.combo);

      final ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
      if (ret != LuaUtil.Function_Stop)
      {
        // This ones up here for reasons!
        hud.comboStats.ratingFC = Rating.generateComboRank(hud.comboStats.songMisses);

        hud.comboStats.ratingName = '?';
        if (hud.comboStats.totalPlayed != 0) // Prevent divide by 0
        {
          // Rating Percent
          hud.comboStats.ratingPercent = Math.min(1, Math.max(0, hud.comboStats.totalNotesHit / hud.comboStats.totalPlayed));

          // Rating Name
          hud.comboStats.ratingName = ComboStats.ratingStuff[ComboStats.ratingStuff.length - 1][0]; // Uses last string
          if (hud.comboStats.ratingPercent < 1)
          {
            for (i in 0...ComboStats.ratingStuff.length - 1)
            {
              if (hud.comboStats.ratingPercent < ComboStats.ratingStuff[i][1])
              {
                hud.comboStats.ratingName = ComboStats.ratingStuff[i][0];
                break;
              }
            }
          }
        }
      }
      setOnScripts('rating', hud.comboStats.ratingPercent);
      setOnScripts('ratingName', hud.comboStats.ratingName);
      setOnScripts('ratingFC', hud.comboStats.ratingFC);
      setOnScripts('totalPlayed', hud.comboStats.totalPlayed);
      setOnScripts('totalNotesHit', hud.comboStats.totalNotesHit);
      updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
    }
    hud.comboStats.onRecalculateRating(false);
    hud.comboStats.onLastCombo = function(lastCombo:Int) {
      if (lastCombo > 5 && gf != null && gf.hasOffsetAnimation('sad'))
      {
        gf.playAnim('sad');
        gf.specialAnim = true;
      }
    }
    opponentStrums.playKeys = opponentMode;
    playerStrums.playKeys = !opponentMode;

    for (strumLine in strumLines)
    {
      if (strumLine == null) continue;
      strumLine.canHoldKey = function():Bool return startedCountdown && !inCutscene && generatedMusic;
      strumLine.canKeyActionUpdate = function():Bool return startedCountdown && !paused;
    }

    // PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
    if (ClientPrefs.data.hitsoundVolume > 0) if (ClientPrefs.data.hitSounds != "None") Paths.sound('hitsounds/${ClientPrefs.data.hitSounds}');
    if (!ClientPrefs.data.ghostTapping)
    {
      for (i in 1...4)
        Paths.sound('missnote$i');
    }
    Paths.image('alphabet');

    if (PauseSubState.songName != null) Paths.music(PauseSubState.songName);
    else if (Paths.formatToSongPath(ClientPrefs.data.pauseMusic) != 'none') Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));

    resetRPC();

    if (stage != null) stage.onCreatePost();
    callOnScripts('onCreatePost');

    if (!SONG.getSongData('options').disableNoteRGB
      && !SONG.getSongData('options').disableStrumRGB
      && !SONG.getSongData('options').disableNoteCustomRGB) setUpColoredNotes();

    super.create();

    #if desktop
    Application.current.window.title = songInfo;
    #end

    Paths.clearUnusedMemory();

    songEvents.lessThanCheck();

    if (timeToStart > 0)
    {
      clearNotesBefore(false, timeToStart);
    }

    if (ClientPrefs.data.behaviourType == 'KADE') subStates.push(new ResultsScreenKadeSubstate(camFollow));

    opponentStrums.calls.onSpawnNoteLua = function(notes:FlxTypedGroup<Note>, dunceNote:Note) {
      callOnLuas('onSpawnNote', [
        notes.members.indexOf(dunceNote),
        dunceNote.noteData,
        dunceNote.noteType,
        dunceNote.isSustainNote,
        dunceNote.strumTime
      ]);
      opponentStrums.calls.spawnNoteLua.dispatch(notes, dunceNote);
    }

    opponentStrums.calls.onSpawnNoteHx = function(dunceNote:Note) {
      callOnAllHS('onSpawnNote', [dunceNote]);
      opponentStrums.calls.spawnNoteHx.dispatch(dunceNote);
    }

    opponentStrums.calls.onSpawnNoteLuaPost = function(notes:FlxTypedGroup<Note>, dunceNote:Note) {
      callOnLuas('onSpawnNotePost', [
        notes.members.indexOf(dunceNote),
        dunceNote.noteData,
        dunceNote.noteType,
        dunceNote.isSustainNote,
        dunceNote.strumTime
      ]);
      opponentStrums.calls.spawnNoteLuaPost.dispatch(notes, dunceNote);
    }

    opponentStrums.calls.onSpawnNoteHxPost = function(dunceNote:Note) {
      callOnAllHS('onSpawnNote', [dunceNote]);
      opponentStrums.calls.spawnNoteHx.dispatch(dunceNote);
    }

    hud.countdownTick = function(tick:Countdown, swagC:Int) {
      if (ClientPrefs.data.characters) characterBopper(swagC);

      if (tick == GO)
      {
        if (ClientPrefs.data.heyIntro)
        {
          for (char in [dad, boyfriend, gf, mom])
          {
            if (char != null && (char.hasOffsetAnimation('hey') || char.hasOffsetAnimation('cheer')))
            {
              char.playAnim(char.hasOffsetAnimation('cheer') ? 'cheer' : 'hey', true);
              if (!char.skipHeyTimer)
              {
                char.specialAnim = true;
                char.heyTimer = 0.6;
              }
            }
          }
        }
      }

      if (generatedMusic)
      {
        playerStrums.notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
        opponentStrums.notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
      }

      if (!skipStrumSpawn && arrowsAppeared)
      {
        opponentStrums.notes.forEachAlive(function(note:Note) {
          note.copyAlpha = false;
          note.alpha = note.multAlpha;
          if (ClientPrefs.data.middleScroll)
          {
            note.alpha *= 0.35;
          }
        });
      }

      if (stage != null) stage.countdownTickStage(tick, swagC);
      callOnLuas('onCountdownTick', [swagC]);
      callOnAllHS('onCountdownTick', [tick, swagC]);
    }

    // This step ensures z-indexes are applied properly,
    // and it's important to call it last so all elements get affected.
    refresh();
  }

  public var stopCountDown:Bool = false;

  public dynamic function setUpColoredNotes()
  {
    for (strumLine in strumLines)
    {
      strumLine.staticColorStrums = true;
      for (note in strumLine.unspawnNotes.members)
        note.setCustomColors(ClientPrefs.data.colorNoteType);
      for (strum in strumLine)
      {
        strum.rgbShader.r = 0xFF808080;
        strum.rgbShader.b = 0xFF474747;
        strum.rgbShader.g = 0xFFFFFFFF;
        strum.rgbShader.enabled = false;
      }
    }
  }

  public var songInfo:String = '';

  function set_songSpeed(value:Float):Float
  {
    if (generatedMusic) for (strumLine in strumLines)
      strumLine.scrollSpeed = value;

    songSpeed = value;
    noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
    return value;
  }

  function set_playbackRate(value:Float):Float
  {
    #if FLX_PITCH
    if (generatedMusic)
    {
      vocals.pitch = value;
      opponentVocals.pitch = value;
      FlxG.sound.music.pitch = value;
    }
    for (strumLine in strumLines)
      strumLine.playbackSpeed = value;
    FlxG.timeScale = playbackRate = value;
    Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
    Conductor.offset = (PlayState.SONG.getSongData('offset') / value);
    setOnScripts('playbackRate', playbackRate);
    #if VIDEOS_ALLOWED
    if (videoCutscene != null) videoCutscene.videoSprite.bitmap.rate = value;
    #end
    #else
    playbackRate = 1.0;
    #end
    return playbackRate;
  }

  function cancelAppearArrows()
  {
    for (strumLine in strumLines)
    {
      strumLine.forEach(function(babyArrow:StrumArrow) {
        tweenManager.cancelTweensOf(babyArrow);
        babyArrow.alpha = 0;
        babyArrow.y = strumLine.initialStrumLinePos.y;
      });
    }
    arrowsAppeared = false;
  }

  function removeStaticArrows(?destroy:Bool = false)
  {
    if (arrowsGenerated)
    {
      for (strumLine in strumLines)
      {
        strumLine.forEach(function(babyArrow:StrumArrow) {
          strumLine.remove(babyArrow);
          if (destroy) babyArrow.destroy();
        });
      }
      arrowsGenerated = false;
    }
  }

  public function startCharacterPos(char:Character, ?gfCheck:Bool = false, ?isBf:Bool = false)
  {
    if (gfCheck && char.curCharacter.startsWith('gf'))
    { // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
      char.setPosition(GF_X, GF_Y);
      char.scrollFactor.set(0.95, 0.95);
      char.idleTime = 2;
    }
    char.x += char.positionArray[0];
    char.y += char.positionArray[1] - (isBf ? 350 : 0);
  }

  public var videoCutscene:VideoSprite = null;

  public function startVideo(name:String, type:String = 'mp4', forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true,
      adjustSize:Bool = true)
  {
    #if (VIDEOS_ALLOWED && hxvlc)
    try
    {
      inCinematic = !forMidSong;
      canPause = forMidSong;

      var foundFile:Bool = false;
      var fileName:String = Paths.video(name, type);
      #if sys
      if (FileSystem.exists(fileName))
      #else
      if (OpenFlAssets.exists(fileName))
      #end
      foundFile = true;

      if (foundFile)
      {
        videoCutscene = new VideoSprite(fileName, forMidSong, canSkip, loop, false, adjustSize);
        videoCutscene.videoSprite.bitmap.rate = playbackRate;

        // Finish callback
        if (!forMidSong)
        {
          function onVideo(skip:Bool = false)
          {
            callOnScripts(skip ? 'onVideoSkipped' : 'onVideoCompleted', [name]);
            if (!isDead
              && generatedMusic
              && SONG.getSongData('notes')[Std.int(curStep / 16)] != null
              && !endingSong
              && !isCameraOnForcedPos)
            {
              cameraTargeted = SONG.getSongData('notes')[Std.int(curStep / 16)].mustHitSection ? 'bf' : 'dad';
              FlxG.camera.snapToTarget();
            }
            videoCutscene = null;
            canPause = true;
            inCutscene = false;
            startAndEnd();
          }
          // End callback
          videoCutscene.finishCallback = () -> {
            onVideo(false);
          }
          // Skip callbac
          videoCutscene.onSkip = () -> {
            onVideo(true);
          }
        }
        if (GameOverSubstate.instance != null && isDead) GameOverSubstate.instance.add(videoCutscene);
        else
          add(videoCutscene);

        if (playOnLoad) videoCutscene.play();
        return videoCutscene;
      }
      #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
      else
        addTextToDebug("Video not found: " + fileName, FlxColor.RED);
      #else
      else
        FlxG.log.error("Video not found: " + fileName);
      #end
    }
    catch (e:Dynamic) {}
    #else
    FlxG.log.warn('Platform not supported!');
    startAndEnd();
    #end
    return null;
  }

  function startAndEnd()
  {
    if (endingSong) endSong();
    else
      startCountdown();
  }

  var dialogueCount:Int = 0;

  public var psychDialogue:DialogueBoxPsych;

  // You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
  public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
  {
    // TO DO: Make this more flexible, maybe?
    if (psychDialogue != null) return;

    if (dialogueFile.dialogue.length > 0)
    {
      inCutscene = true;
      psychDialogue = new DialogueBoxPsych(dialogueFile, song);
      psychDialogue.scrollFactor.set();
      if (endingSong)
      {
        psychDialogue.finishThing = function() {
          psychDialogue = null;
          endSong();
        }
      }
      else
      {
        psychDialogue.finishThing = function() {
          psychDialogue = null;
          startCountdown();
        }
      }
      psychDialogue.nextDialogueThing = startNextDialogue;
      psychDialogue.skipDialogueThing = skipDialogue;
      psychDialogue.cameras = [camHUD];
      add(psychDialogue);
    }
    else
    {
      FlxG.log.warn('Your dialogue file is badly formatted!');
      startAndEnd();
    }
  }

  // Can't make it a instance because of how it functions!
  public static var startOnTime:Float = 0;

  public function updateDefaultPos()
  {
    for (i in 0...playerStrums.length)
    {
      setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
      setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
    }
    for (i in 0...opponentStrums.length)
    {
      setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
      setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
    }
  }

  public var skipStrumSpawn:Bool = false;

  public dynamic function startCountdown()
  {
    if (!stopCountDown)
    {
      if (startedCountdown)
      {
        callOnScripts('onStartCountdown');
        return false;
      }

      if (!arrowsAppeared && (inCinematic || inCutscene)) appearStrumArrows(true);

      seenCutscene = true;
      inCutscene = inCinematic = false;
      if (SONG.getSongData('notes')[curSection] != null) cameraTargeted = SONG.getSongData('notes')[curSection].mustHitSection != true ? 'dad' : 'bf';
      isCameraFocusedOnCharacters = true;

      final ret:Dynamic = callOnScripts('onStartCountdown', null, true);
      if (ret != LuaUtil.Function_Stop)
      {
        startedCountdown = true;
        updateDefaultPos();
        Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
        setOnScripts('startedCountdown', true);
        callOnScripts('onCountdownStarted');

        if (startOnTime > 0)
        {
          clearNotesBefore(false, startOnTime);
          setSongTime(startOnTime - 350);
          return true;
        }
        else if (skipCountdown)
        {
          setSongTime(0);
          return true;
        }

        hud.startCountdownTimer();
        showYou(opponentMode);
      }
      return true;
    }
    return false;
  }

  public function insertIndexOf(obj:FlxBasic, obj2:FlxBasic, ?pos:Int = 0)
    insert(members.indexOf(obj) + pos, obj2);

  public function addBehindGF(obj:FlxBasic)
    insertIndexOf(gf, obj);

  public function addBehindBF(obj:FlxBasic)
    insertIndexOf(boyfriend, obj);

  public function addBehindMom(obj:FlxBasic)
    insertIndexOf(mom, obj);

  public function addBehindDad(obj:FlxBasic)
    insertIndexOf(dad, obj);

  public function clearNotesBefore(?completelyClear:Bool = false, ?time:Float = 0)
  {
    for (strumLine in strumLines)
      strumLine.calls.onClearNotesBefore(time, completelyClear);
    callOnScripts('onClearNotesBefore', [completelyClear, time]);
  }

  // fun fact: Dynamic Functions can be overriden by just doing this
  // `updateScore = function(miss:Bool = false) { ... }
  // its like if it was a variable but its just a function!
  // cool right? -Crow
  public dynamic function updateScore(miss:Bool = false)
  {
    var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
    if (ret == LuaUtil.Function_Stop) return;
    hud.updateScoreText();
    if (!miss && !cpuControlled) hud.doScoreBop();
    callOnScripts('onUpdateScore', [miss]);
  }

  public function setSongTime(time:Float)
  {
    for (sound in [FlxG.sound.music, vocals, opponentVocals])
    {
      if (sound == null) continue;
      sound.pause();
    }
    FlxG.sound.music.time = time - Conductor.offset;
    #if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
    FlxG.sound.music.play();

    for (vocal in [vocals, opponentVocals])
    {
      if (vocal == null) continue;
      if (Conductor.songPosition < vocal.length)
      {
        vocal.time = time - Conductor.offset;
        #if FLX_PITCH vocal.pitch = playbackRate; #end
        vocal.play();
      }
      else
        vocal.pause();
    }

    Conductor.songPosition = time;
  }

  public function startNextDialogue()
  {
    dialogueCount++;
    callOnScripts('onNextDialogue', [dialogueCount]);
  }

  public function skipDialogue()
    callOnScripts('onSkipDialogue', [dialogueCount]);

  public var songStarted:Bool = false;
  public var acceptFinishedSongBind:Bool = true;

  public dynamic function startSong():Void
  {
    canPause = songStarted = true;
    startingSong = false;

    #if (VIDEOS_ALLOWED && hxvlc)
    if (daVideoGroup != null)
    {
      for (vid in daVideoGroup)
      {
        vid.videoSprite.bitmap.resume();
      }
    }
    #end

    @:privateAccess
    FlxG.sound.playMusic(inst._sound, 1, false);
    #if FLX_PITCH
    FlxG.sound.music.pitch = playbackRate;
    #end
    if (acceptFinishedSongBind) FlxG.sound.music.onComplete = finishSong.bind();
    // Prevent the volume from being wrong.
    FlxG.sound.music.volume = 1.0;
    vocals.play();
    opponentVocals.play();

    setSongTime(Math.max(0, timeToStart) + Conductor.offset);
    timeToStart = 0;

    setSongTime(Math.max(0, startOnTime - 500) + Conductor.offset);
    startOnTime = 0;

    Debug.logInfo('started loading!');

    if (paused)
    {
      FlxG.sound.music.pause();
      vocals.pause();
      opponentVocals.pause();
    }

    if (stage != null) stage.startSongStage();

    // Song duration in a float, useful for the time left feature
    songLength = FlxG.sound.music.length;
    hud.tweenInTimeBar();

    #if DISCORD_ALLOWED
    // Updating Discord Rich Presence (with Time Left)
    if (autoUpdateRPC) DiscordClient.changePresence(detailsText, SONG.getSongData('songId') + " (" + storyDifficultyText + ")", hud.iconP2.getCharacter(),
      true, songLength);
    #end

    setOnScripts('songLength', songLength);
    callOnScripts('onSongStart');
  }

  public var noteTypes:Array<String> = [];

  public var opponentSectionNoteStyle:String = "";
  public var playerSectionNoteStyle:String = "";

  public var opponentSectionStrumStyle:String = "";
  public var playerSectionStrumStyle:String = "";

  // note shit
  public var noteSkinDad:String;
  public var noteSkinBF:String;

  public var strumSkinDad:String;
  public var strumSkinBF:String;

  public dynamic function generateSong():Void
  {
    opponentSectionNoteStyle = playerSectionNoteStyle = opponentSectionStrumStyle = playerSectionStrumStyle = "";
    final songData:Song = SONG;
    final extraSongData:Dynamic = songData.getSongData('_extraData');

    songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
    songSpeed = songSpeedType == 'multiplicative' ? songData.getSongData('speed') * ClientPrefs.getGameplaySetting('scrollspeed') : ClientPrefs.getGameplaySetting('scrollspeed');
    Conductor.bpm = songData.getSongData('bpm');

    curSong = songData.getSongData('songId');

    if (instakillOnMiss)
    {
      final redVignette:FlxSprite = new FlxSprite().loadGraphic(Paths.image('nomisses_vignette', 'shared'));
      redVignette.screenCenter();
      redVignette.cameras = [mainCam];
      redVignette.setGraphicSize(FlxG.width, FlxG.height);
      add(redVignette);
    }

    vocals = new FlxSound();
    opponentVocals = new FlxSound();

    if (songData.getSongData('needsVoices'))
    {
      if (vocalPrecache.length > 0)
      {
        for (vocal in vocalPrecache)
        {
          vocals.loadEmbedded(SoundUtil.findVocalOrInst(vocal));
          vocals.volume = 0;
          vocals.play();
          vocals.stop();
        }
      }

      if (opponentVocalPrecache.length > 0)
      {
        for (vocal in opponentVocalPrecache)
        {
          opponentVocals.loadEmbedded(SoundUtil.findVocalOrInst(vocal));
          opponentVocals.volume = 0;
          opponentVocals.play();
          opponentVocals.stop();
        }
      }

      @:privateAccess
      {
        if (vocals._sound != null)
        {
          vocals.destroy();
          vocals = new FlxSound();
        }

        if (opponentVocals._sound != null)
        {
          opponentVocals.destroy();
          opponentVocals = new FlxSound();
        }
      }

      try
      {
        final currentPrefix:String = (songData.getSongData('options').vocalsPrefix != null ? songData.getSongData('options').vocalsPrefix : '');
        final currentSuffix:String = (songData.getSongData('options').vocalsSuffix != null ? songData.getSongData('options').vocalsSuffix : '');
        final vocalPl:String = (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile;
        final vocalOp:String = (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile;
        final normalVocals = Paths.voices(currentPrefix, songData.getSongData('songId'), currentSuffix);
        var playerVocals = SoundUtil.findVocalOrInst((extraSongData != null && extraSongData._vocalSettings != null) ? extraSongData._vocalSettings :
          {
            song: songData.getSongData('songId'),
            prefix: currentPrefix,
            suffix: currentSuffix,
            externVocal: vocalPl,
            character: boyfriend.curCharacter,
            difficulty: Difficulty.getString()
          });
        vocals.loadEmbedded(playerVocals != null ? playerVocals : normalVocals);

        var oppVocals = SoundUtil.findVocalOrInst((extraSongData != null && extraSongData._vocalOppSettings != null) ? extraSongData._vocalOppSettings :
          {
            song: songData.getSongData('songId'),
            prefix: currentPrefix,
            suffix: currentSuffix,
            externVocal: vocalOp,
            character: dad.curCharacter,
            difficulty: Difficulty.getString()
          });
        if (oppVocals != null)
        {
          opponentVocals.loadEmbedded(oppVocals);
          splitVocals = true;
        }
      }
      catch (e:Dynamic) {}
    }

    #if FLX_PITCH
    vocals.pitch = playbackRate;
    opponentVocals.pitch = playbackRate;
    #end

    FlxG.sound.list.add(vocals);
    FlxG.sound.list.add(opponentVocals);

    inst = new FlxSound();

    if (instPrecache.length > 0)
    {
      for (instrumental in instPrecache)
      {
        inst.loadEmbedded(SoundUtil.findVocalOrInst(instrumental, 'INST'));
        inst.volume = 0;
        inst.play();
        inst.stop();
      }
    }

    @:privateAccess
    {
      if (inst._sound != null)
      {
        inst.destroy();
        inst = new FlxSound();
      }
    }

    try
    {
      final currentPrefix:String = (songData.getSongData('options').instrumentalPrefix != null ? songData.getSongData('options').instrumentalPrefix : '');
      final currentSuffix:String = (songData.getSongData('options').instrumentalSuffix != null ? songData.getSongData('options').instrumentalSuffix : '');
      inst.loadEmbedded(SoundUtil.findVocalOrInst((extraSongData != null && extraSongData._instSettings != null) ? extraSongData._instSettings :
        {
          song: songData.getSongData('songId'),
          prefix: currentPrefix,
          suffix: currentSuffix,
          externVocal: "",
          character: "",
          difficulty: Difficulty.getString()
        }, 'INST'));
    }
    catch (e:Dynamic) {}
    #if FLX_PITCH inst.pitch = playbackRate; #end
    FlxG.sound.list.add(inst);

    // Extra eventJsons
    var pushedEventJsons:Array<String> = [];
    if (extraSongData != null && extraSongData._eventJsons != null)
    {
      final extraSongJsons:Array<Dynamic> = extraSongData._eventJsons;
      if (extraSongJsons.length > 0)
      {
        for (eventJson in extraSongJsons)
        {
          if (eventJson == null) continue;

          final eventFile:ExternalFile =
            {
              name: eventJson.name != null ? eventJson.name : eventJson,
              folder: eventJson.folder != null ? eventJson.folder : songName
            };
          final eventFileName:String = eventFile.name;
          final eventFolder:String = eventFile.folder;
          final custom:Bool = eventJson.folder != songName;
          final file:String = Paths.getPath('$eventFolder$eventFileName.json', TEXT);
          if (#if MODS_ALLOWED FileSystem.exists(file) || #end OpenFlAssets.exists(file))
          {
            var eventsData:Array<Dynamic> = SongJsonData.getChart(
              {
                jsonInput: eventFileName,
                folder: eventFolder
              }, custom).events;
            if (eventsData != null)
            {
              for (event in eventsData) // Event Notes
                for (i in 0...event[1].length)
                  songEvents.makeEvent(event, i);
            }
          }
          pushedEventJsons.push(eventFileName);
        }
      }
    }

    if (pushedEventJsons.length < 1)
    {
      var difficultyEventsFound:Bool = false;
      var file:String = Paths.getPath('data/songs/$songName/events-${Difficulty.getString().toLowerCase()}.json', TEXT);
      if (#if MODS_ALLOWED FileSystem.exists(file) || #end OpenFlAssets.exists(file))
      {
        final eventsData:Array<Dynamic> = SongJsonData.getChart(
          {
            jsonInput: 'events-' + Difficulty.getString().toLowerCase(),
            folder: songName,
            difficulty: Difficulty.getString().toLowerCase()
          }).events;
        if (eventsData != null)
        {
          for (event in eventsData) // Event Notes
            for (i in 0...event[1].length)
              songEvents.makeEvent(event, i);
          difficultyEventsFound = true;
        }
      }

      file = Paths.getPath('data/songs/$songName/events.json', TEXT);
      if (#if MODS_ALLOWED FileSystem.exists(file) || #end OpenFlAssets.exists(file))
      {
        final eventsData:Array<Dynamic> = SongJsonData.getChart(
          {
            jsonInput: 'events',
            folder: songName
          }).events;
        if (eventsData != null && !difficultyEventsFound)
        {
          for (event in eventsData) // Event Notes
            for (i in 0...event[1].length)
              songEvents.makeEvent(event, i);
        }
      }
    }

    // Extra Song Scripts
    if (extraSongData != null && extraSongData._scriptFiles != null)
    {
      final extraScriptsData:Array<ExternalFile> = extraSongData._scriptFiles;
      if (extraScriptsData.length > 0)
      {
        for (script in extraScriptsData)
        {
          switch (script.type.toLowerCase())
          {
            #if LUA_ALLOWED
            case 'lua':
              addScript(Paths.getPath(script.folder + script.name), LUA);
            #end
            #if HSCRIPT_ALLOWED
            case 'psych-hscript', 'iris':
              addScript(Paths.getPath(script.folder + script.name), IRIS);
            #if HscriptImproved
            case 'codename-hscript':
              addScript(Paths.getPath(script.folder + script.name), CODENAME);
            #end
            case 'sc-hscript':
              addScript(Paths.getPath(script.folder + script.name), SC);
            #end
          }
        }
      }
    }

    for (strumLine in strumLines)
      strumLine.scrollSpeed = songSpeed;

    // Event Notes
    final events:Array<Dynamic> = songData.getSongData('events');
    for (event in events)
      for (i in 0...event[1].length)
        songEvents.makeEvent(event, i);

    final notes:Array<SwagSection> = songData.getSongData('notes');
    if (notes != null && notes.length > 0)
    {
      var prePlayerNotes:Array<Note> = playerStrums.createNotes(notes);
      var preOpponentNotes:Array<Note> = opponentStrums.createNotes(notes);

      for (note in prePlayerNotes)
      {
        try
        {
          if (Paths.fileExists('data/songs/$songName/precache.json', TEXT))
          {
            final rawFile:String = Paths.getTextFromFile('data/songs/$songName/precache.json');
            if (rawFile != null && rawFile.length > 0)
            {
              final precache = tjson.TJSON.parse(rawFile);
              if (precache != null)
              {
                if (precache.arrowSwitches != null && precache.arrowSwitches.length > 0)
                {
                  final arrowSwitches:Array<Dynamic> = precache.arrowSwitches;
                  for (arrowSkin in arrowSwitches)
                  {
                    final skinSection:Int = arrowSkin.section;
                    if (note.noteSection == skinSection)
                    {
                      final skin:String = arrowSkin.skin;
                      final type:String = (arrowSkin.type != null && arrowSkin.type.length > 0) ? arrowSkin.type : 'note';
                      final isPlayer:Bool = ((arrowSkin.player != null && arrowSkin.player.length > 0) ? arrowSkin.player != 'dad' : false);
                      if (isPlayer)
                      {
                        if (type != 'note') playerSectionStrumStyle = skin;
                        else
                          playerSectionNoteStyle = skin;
                      }
                    }
                  }
                }
              }
            }
          }
        }
        catch (e:haxe.Exception) {}

        noteSkinBF = boyfriend.noteSkin;

        var noteSkinUsed:String = playerSectionNoteStyle != "" ? playerSectionNoteStyle : noteSkinBF;
        var songArrowSkins:Bool = true;

        if (SONG.getSongData('options').arrowSkin == null || SONG.getSongData('options').arrowSkin.length < 1) songArrowSkins = false;
        if (noteSkinUsed == null || noteSkinUsed.length < 1) noteSkinUsed = (!songArrowSkins ? (isPixelStage ? 'pixel' : 'normal') : SONG.getSongData('options')
          .arrowSkin);
        else
          noteSkinUsed = playerSectionNoteStyle != "" ? playerSectionNoteStyle : noteSkinBF;

        note.texture = note.noteSkin = noteSkinUsed;
      }

      for (note in preOpponentNotes)
      {
        try
        {
          if (Paths.fileExists('data/songs/$songName/precache.json', TEXT))
          {
            final rawFile:String = Paths.getTextFromFile('data/songs/$songName/precache.json');
            if (rawFile != null && rawFile.length > 0)
            {
              final precache = tjson.TJSON.parse(rawFile);
              if (precache != null)
              {
                if (precache.arrowSwitches != null && precache.arrowSwitches.length > 0)
                {
                  final arrowSwitches:Array<Dynamic> = precache.arrowSwitches;
                  for (arrowSkin in arrowSwitches)
                  {
                    final skinSection:Int = arrowSkin.section;
                    if (note.noteSection == skinSection)
                    {
                      final skin:String = arrowSkin.skin;
                      final type:String = (arrowSkin.type != null && arrowSkin.type.length > 0) ? arrowSkin.type : 'note';
                      final isPlayer:Bool = ((arrowSkin.player != null && arrowSkin.player.length > 0) ? arrowSkin.player != 'dad' : false);
                      if (!isPlayer)
                      {
                        if (type != 'note') opponentSectionStrumStyle = skin;
                        else
                          opponentSectionNoteStyle = skin;
                      }
                    }
                  }
                }
              }
            }
          }
        }
        catch (e:haxe.Exception) {}

        noteSkinDad = dad.noteSkin;

        var noteSkinUsed:String = opponentSectionNoteStyle != "" ? opponentSectionNoteStyle : noteSkinDad;
        var songArrowSkins:Bool = true;

        if (SONG.getSongData('options').arrowSkin == null || SONG.getSongData('options').arrowSkin.length < 1) songArrowSkins = false;
        if (noteSkinUsed == null || noteSkinUsed.length < 1) noteSkinUsed = (!songArrowSkins ? (isPixelStage ? 'pixel' : 'normal') : SONG.getSongData('options')
          .arrowSkin);
        else
          noteSkinUsed = opponentSectionNoteStyle != "" ? opponentSectionNoteStyle : noteSkinDad;

        note.texture = note.noteSkin = noteSkinUsed;
      }

      playerStrums.unspawnNotes.setMembers(prePlayerNotes);
      opponentStrums.unspawnNotes.setMembers(preOpponentNotes);
      playerStrums.unspawnNotes.resort('strumTime');
      opponentStrums.unspawnNotes.resort('strumTime');
    }

    var allNotes:Array<Note> = [];
    for (noteMembers in [
      opponentStrums.unspawnNotes.members.copy(),
      playerStrums.unspawnNotes.members.copy()
    ])
      for (note in noteMembers)
        allNotes.push(note);
    allNotes.sort(function(a:Note, b:Note) return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime));
    for (note in allNotes)
    {
      if (note.strumLineID == 0 && !note.isSustainNote)
      {
        hud.comboStats.playerNotesCount++;
        Highscore.songHighScoreData.comboData.totalNoteCount++;
      }
      else if (note.strumLineID == 1) hud.comboStats.opponentNotesCount++;
      hud.comboStats.songNotesCount++;

      if (!noteTypes.contains(note.noteType)) noteTypes.push(note.noteType);
    }
    generatedMusic = true;
    opponentSectionNoteStyle = playerSectionNoteStyle = opponentSectionStrumStyle = playerSectionStrumStyle = "";
    callOnScripts('onSongGenerated', []);
  }

  public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
    return sortNotes(FlxSort.ASCENDING, Obj1, Obj2);

  public static function sortNotes(order:Int = FlxSort.ASCENDING, Obj1:Dynamic, Obj2:Dynamic):Int
    return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

  public var boyfriendCameraOffset:Array<Float> = [0, 0];
  public var opponentCameraOffset:Array<Float> = [0, 0];
  public var opponent2CameraOffset:Array<Float> = [0, 0];
  public var girlfriendCameraOffset:Array<Float> = [0, 0];

  public function setCameraOffsets()
  {
    opponentCameraOffset = [stage?.opponentCameraOffset[0] ?? 0, stage?.opponentCameraOffset[1] ?? 0];
    girlfriendCameraOffset = [stage?.girlfriendCameraOffset[0] ?? 0, stage?.girlfriendCameraOffset[1] ?? 0];
    boyfriendCameraOffset = [stage?.boyfriendCameraOffset[0] ?? 0, stage?.boyfriendCameraOffset[1] ?? 0];
    opponent2CameraOffset = [stage?.opponent2CameraOffset[0] ?? 0, stage?.opponent2CameraOffset[1] ?? 0];
  }

  public var skipArrowStartTween:Bool = false; // for lua and hx
  public var disabledIntro:Bool = false; // for lua and hx

  public dynamic function setupArrowStuff(player:Int, style:String, amount:Int = 4):Void
  {
    switch (player)
    {
      case 0:
        if (opponentMode) bfStrumStyle = style;
        else
          dadStrumStyle = style;
      case 1:
        if (opponentMode) dadStrumStyle = style;
        else
          bfStrumStyle = style;
    }

    if (player > 0) playerStrums.generateStrums(player, style, amount);
    else
      opponentStrums.generateStrums(player, style, amount);
  }

  public function appearStrumArrows(?tween:Bool = true):Void
  {
    for (strumLines in [playerStrums, opponentStrums])
    {
      strumLines.forEach(function(babyArrow:StrumArrow) {
        babyArrow.reloadNote(babyArrow.player == 1 ? bfStrumStyle : dadStrumStyle);
        var targetAlpha:Float = 1;

        if (babyArrow.player < 1 && ClientPrefs.data.middleScroll)
        {
          targetAlpha = 0.35;
        }

        if (tween)
        {
          babyArrow.alpha = 0;
          TweenUtil.createTween(tweenManager, babyArrow, {alpha: targetAlpha}, 0.85, {ease: FlxEase.circOut, startDelay: 0.02 + (0.2 * babyArrow.ID)});
        }
        else
          babyArrow.alpha = disabledIntro ? 0 : targetAlpha;
      });
    }
    arrowsAppeared = true;
  }

  public var pauseTimer:FlxTimer;

  override function openSubState(SubState:FlxSubState)
  {
    if (stage != null) stage.onOpenSubState(SubState);
    if (paused)
    {
      PauseSubState.pauseCounter += 1;
      if (pauseTimer != null) pauseTimer.cancel();
      #if (VIDEOS_ALLOWED && hxvlc)
      for (vid in VideoSprite._videos)
      {
        if (vid.isPlaying) vid.pause();
      }
      if (daVideoGroup != null)
      {
        for (vid in daVideoGroup.members)
        {
          if (vid.videoSprite.alive) vid.videoSprite.bitmap.pause();
        }
      }
      if (videoCutscene != null) videoCutscene.videoSprite.pause();
      #end

      for (sound in [FlxG.sound.music, vocals, opponentVocals])
      {
        if (sound == null || alreadyEndedSong) continue;
        if (sound == opponentVocals && splitVocals) sound.pause();
        else
          sound.pause();
      }

      FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = false);
      FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = false);
    }

    super.openSubState(SubState);
  }

  public var canResync:Bool = true;

  override function closeSubState()
  {
    super.closeSubState();

    if (stage != null) stage.onCloseSubState();

    if (paused)
    {
      if (PauseSubState.pauseCounter > 1)
      {
        pauseTimer = new FlxTimer().start(3, function(tmr) {
          PauseSubState.pauseCounter = 0;
        });
      }
      canResync = true;
      FlxG.timeScale = playbackRate;
      #if (VIDEOS_ALLOWED && hxvlc)
      if (videoCutscene != null) videoCutscene.videoSprite.resume();
      if (daVideoGroup != null)
      {
        for (vid in daVideoGroup)
        {
          if (vid.videoSprite.alive) vid.videoSprite.bitmap.resume();
        }
      }
      for (vid in VideoSprite._videos)
      {
        if (vid.isPlaying) vid.resume();
      }
      #end

      if (FlxG.sound.music != null && !startingSong && canResync) resyncVocals(splitVocals);

      FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = true);
      FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = true);

      paused = false;
      callOnScripts('onResume');
      resetRPC(hud.startTimer != null && hud.startTimer.finished);
    }
  }

  override public function onFocus():Void
  {
    callOnScripts('onFocus');
    if (!paused)
    {
      if (hud.health > 0) resetRPC(Conductor.songPosition > 0.0);
      #if VIDEOS_ALLOWED
      if (videoCutscene != null) videoCutscene.resume();
      #end
    }
    super.onFocus();
    callOnScripts('onFocusPost');
  }

  override public function onFocusLost():Void
  {
    callOnScripts('onFocusLost');
    if (!paused)
    {
      #if DISCORD_ALLOWED
      if (hud.health > 0 && autoUpdateRPC)
      {
        DiscordClient.changePresence(detailsPausedText, SONG.getSongData('songId') + " (" + storyDifficultyText + ")", hud.iconP2.getCharacter());
      }
      #end
      #if VIDEOS_ALLOWED
      if (videoCutscene != null) videoCutscene.resume();
      #end
    }
    super.onFocusLost();
    callOnScripts('onFocusLostPost');
  }

  // Updating Discord Rich Presence.
  public var autoUpdateRPC:Bool = true; // performance setting for custom RPC things

  function resetRPC(?showTime:Bool = false)
  {
    #if DISCORD_ALLOWED
    if (!autoUpdateRPC) return;

    if (showTime) DiscordClient.changePresence(detailsText, SONG.getSongData('songId')
      + " ("
      + storyDifficultyText
      + ")", hud.iconP2.getCharacter(), true,
      songLength
      - Conductor.songPosition
      - ClientPrefs.data.noteOffset);
    else
      DiscordClient.changePresence(detailsText, SONG.getSongData('songId') + " (" + storyDifficultyText + ")", hud.iconP2.getCharacter());
    #end
  }

  public var finishTimer:FlxTimer = null;

  public function resyncVocals(split:Bool = false):Void
  {
    if (finishTimer != null || alreadyEndedSong) return;

    FlxG.sound.music.play();
    #if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
    Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

    var checkVocals = split ? [vocals, opponentVocals] : [vocals];
    for (voc in checkVocals)
    {
      if (voc != null)
      {
        if (FlxG.sound.music.time < voc.length)
        {
          voc.time = FlxG.sound.music.time;
          #if FLX_PITCH voc.pitch = playbackRate; #end
          voc.play();
        }
        else
          voc.pause();
      }
    }
  }

  var vidIndex:Int = 0;

  public function backgroundOverlayVideo(vidSource:String, type:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false,
      playOnLoad:Bool = true, layInFront:Bool = false)
  {
    #if (VIDEOS_ALLOWED && hxvlc)
    switch (type)
    {
      default:
        var foundFile:Bool = false;
        var fileName:String = Paths.video(vidSource, type);
        #if sys
        if (FileSystem.exists(fileName))
        #else
        if (OpenFlAssets.exists(fileName))
        #end
        foundFile = true;

        if (foundFile)
        {
          var cutscene:VideoSprite = new VideoSprite(fileName, forMidSong, canSkip, loop);

          if (!layInFront)
          {
            cutscene.videoSprite.scrollFactor.set(0, 0);
            cutscene.videoSprite.camera = camGame;
            cutscene.videoSprite.scale.set((6 / 5) + (defaultCamZoom / 8), (6 / 5) + (defaultCamZoom / 8));
          }
          else
          {
            cutscene.videoSprite.camera = camVideo;
            cutscene.videoSprite.scrollFactor.set();
            cutscene.videoSprite.scale.set((6 / 5), (6 / 5));
          }

          cutscene.videoSprite.updateHitbox();
          cutscene.videoSprite.visible = false;

          reserveVids.push(cutscene);
          if (!layInFront)
          {
            remove(daVideoGroup);
            if (ClientPrefs.data.characters)
            {
              if (gf != null) remove(gf);
              remove(dad);
              if (mom != null) remove(mom);
              remove(boyfriend);
            }
            for (cutscene in reserveVids)
              daVideoGroup.add(cutscene);
            add(daVideoGroup);
            if (ClientPrefs.data.characters)
            {
              if (gf != null) add(gf);
              add(boyfriend);
              add(dad);
              if (mom != null) add(mom);
            }
          }
          else
          {
            for (cutscene in reserveVids)
            {
              cutscene.videoSprite.camera = camVideo;
              daVideoGroup.add(cutscene);
            }
          }

          reserveVids = [];

          cutscene.videoSprite.bitmap.rate = playbackRate;
          daVideoGroup.members[vidIndex].videoSprite.visible = true;
          vidIndex++;
        }
    }
    #end
  }

  public var paused:Bool = false;
  public var canReset:Bool = true;
  public var startedCountdown:Bool = false;
  public var canPause:Bool = false;
  public var freezeCamera:Bool = false;
  public var allowDebugKeys:Bool = true;

  public var cameraTargeted:String;
  public var camMustHit:Bool;

  public var charCam:Character = null;
  public var isDadCam:Bool = false;
  public var isGFCam:Bool = false;
  public var isMomCam:Bool = false;
  public var isBFCam:Bool = false;
  public var isCameraFocusedOnCharacters:Bool = false;
  public var forceChangeOnTarget:Bool = false;

  public var totalElapsed:Float = 0;

  override public function update(elapsed:Float)
  {
    if (alreadyEndedSong)
    {
      if (endCallback != null) endCallback();
      else
        MusicBeatState.switchState(new FreeplayState());
      super.update(elapsed);
      return;
    }

    if (paused && !isDead) // Updates on game over state, causes variables to be unknown is taken && !isDead
    {
      callOnScripts('onUpdate', [elapsed]);
      callOnScripts('update', [elapsed]);

      super.update(elapsed);

      callOnScripts('onUpdatePost', [elapsed]);
      callOnScripts('updatePost', [elapsed]);
      return;
    }

    totalElapsed += elapsed;

    for (value in MusicBeatState.getVariables("Character").keys())
    {
      if (MusicBeatState.getVariables("Character").get(value) != null && MusicBeatState.getVariables("Character").exists(value))
      {
        final daChar:Character = MusicBeatState.getVariables("Character").get(value);
        if (daChar != null)
        {
          if ((daChar.isPlayer && !daChar.flipMode || !daChar.isPlayer && daChar.flipMode))
          {
            if (daChar.getLastAnimationPlayed().startsWith('sing')) daChar.holdTimer += elapsed;
            else
              daChar.holdTimer = 0;
          }
        }
      }
    }

    // Some Extra VERS to help
    setOnScripts('songPos', Conductor.songPosition);
    setOnScripts('hudZoom', camHUD.zoom);
    setOnScripts('cameraZoom', FlxG.camera.zoom);

    setOnScripts('curDecStep', curDecStep);
    setOnScripts('curDecBeat', curDecBeat);

    callOnScripts('onUpdate', [elapsed]);
    callOnScripts('update', [elapsed]);

    if (stage != null) stage.onUpdate(elapsed);

    if (FunkinLua.lua_Shaders != null)
    {
      for (shaderKeys in FunkinLua.lua_Shaders.keys())
        if (FunkinLua.lua_Shaders.exists(shaderKeys)) if (FunkinLua.lua_Shaders.get(shaderKeys)
          .canUpdate()) FunkinLua.lua_Shaders.get(shaderKeys).update(elapsed);
    }

    if (showCaseMode)
    {
      for (value in MusicBeatState.getVariables("Icon").keys())
      {
        if (MusicBeatState.getVariables("Icon").get(value) != null && MusicBeatState.getVariables("Icon").exists(value))
        {
          cast(MusicBeatState.getVariables("Icon").get(value), HealthIcon).visible = false;
          cast(MusicBeatState.getVariables("Icon").get(value), HealthIcon).alpha = 0;
        }
      }
    }

    if (!inCutscene && !paused && !freezeCamera)
    {
      FlxG.camera.followLerp = 0.04 * cameraSpeed * playbackRate;
      final idleDance:Bool = (boyfriend.getLastAnimationPlayed().startsWith('idle')
        || boyfriend.getLastAnimationPlayed().endsWith('right')
        || boyfriend.getLastAnimationPlayed().endsWith('left'));
      if (!startingSong && !endingSong && !boyfriend.isAnimationNull() && idleDance)
      {
        boyfriendIdleTime += elapsed;
        if (boyfriendIdleTime >= 0.15)
        { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
          boyfriendIdled = true;
        }
      }
      else
        boyfriendIdleTime = 0;
    }
    else
      FlxG.camera.followLerp = 0;

    if (!paused)
    {
      tweenManager.update(elapsed);
      timerManager.update(elapsed);
    }

    if ((controls.PAUSE || ClientPrefs.data.autoPause && !Main.focused) && startedCountdown && canPause)
    {
      var ret:Dynamic = callOnScripts('onPause', null, true);
      if (ret != LuaUtil.Function_Stop) openPauseMenu();
    }

    updateIcons();

    if (!endingSong && !inCutscene && allowDebugKeys && songStarted)
    {
      if (controls.justPressed('debug_1')) openChartEditor(true);
      if (controls.justPressed('debug_2')) openCharacterEditor(true);
    }

    // Update the conductor.
    if (startedCountdown && !paused)
    {
      Conductor.songPosition += elapsed * 1000;
      if (Conductor.songPosition >= Conductor.offset)
      {
        Conductor.songPosition = FlxMath.lerp(FlxG.sound.music.time + Conductor.offset, Conductor.songPosition, Math.exp(-elapsed * 5));
        var timeDiff:Float = Math.abs((FlxG.sound.music.time + Conductor.offset) - Conductor.songPosition);
        if (timeDiff > 1000 * playbackRate) Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
        // if (timeDiff > 25 * playbackRate) Debug.logWarn('Warning! Delay is too fucking high!!');
        #if debug
        if (FlxG.keys.justPressed.K)
        {
          Debug.logInfo('Times: ' + FlxG.sound.music.time + '' + vocals.time + '' + opponentVocals.time);
          Debug.logInfo('Difference: ' + (FlxG.sound.music.time - Conductor.songPosition));
        }

        var daScale = Math.max(-144, Math.min(144, FlxG.sound.music.time - Conductor.songPosition) * (144 / 25));
        delayBar.scale.x = Math.abs(daScale);
        delayBar.updateHitbox();
        if (daScale < 0) delayBar.x = 640 - delayBar.scale.x;
        else
          delayBar.x = 640;

        var timeDiff:Int = Math.round(FlxG.sound.music.time - Conductor.songPosition);
        delayBarTxt.text = '$timeDiff ms';
        if (Math.abs(timeDiff) > 15) delayBar.color = FlxColor.RED;
        else
          delayBar.color = FlxColor.WHITE;
        #end
      }
    }

    if (startingSong)
    {
      if (startedCountdown && Conductor.songPosition >= Conductor.offset) startSong();
      else if (!startedCountdown) Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
    }

    try
    {
      if (generatedMusic && !endingSong && !isCameraOnForcedPos && isCameraFocusedOnCharacters)
      {
        if (!forceChangeOnTarget)
        {
          if (SONG.getSongData('notes')[curSection] != null)
          {
            if (!SONG.getSongData('notes')[curSection].mustHitSection) moveCameraToTarget('dad');
            if (SONG.getSongData('notes')[curSection].mustHitSection) moveCameraToTarget('bf');
            if (SONG.getSongData('notes')[curSection].gfSection) moveCameraToTarget('gf');
            if (SONG.getSongData('notes')[curSection].player4Section) moveCameraToTarget('mom');
          }
        }
        moveCameraToTarget(cameraTargeted);
      }
    }
    catch (e)
    {
      moveCameraToTarget(null);
      cameraTargeted = null;
    }

    if (camZooming && songStarted)
    {
      FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * 1));
      camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * 1));
      camNoteStuff.zoom = !usesHUD ? camHUD.zoom : 1;
    }

    for (index => quick in ["secShit", "beatShit", "stepShit"])
    {
      final objects:Array<Dynamic> = [curSection, curBeat, curStep];
      FlxG.watch.addQuick(quick, objects[index]);
    }

    // RESET = Quick Game Over Screen
    if (!ClientPrefs.data.noReset
      && controls.RESET
      && canReset
      && !inCutscene
      && !inCinematic
      && startedCountdown
      && !endingSong)
    {
      hud.health = 0;
      Debug.logTrace("RESET = True");
    }
    doDeathCheck();

    for (strumLine in strumLines)
    {
      strumLine.registerUnspawnedNotes();
      if (!inCutscene && !inCinematic && generatedMusic)
      {
        if (!strumLine.cpuControlled)
        {
          strumLine.updateKeys();
          callOnScripts('onKeysChecked');
          callOnScripts('keysChecked');
        }
        else
          strumLine.calls.onNotHoldingKey();

        strumLine.charactersDance();
        strumLine.updateNotes(startedCountdown);
      }
    }

    if (generatedMusic)
    {
      if (!inCutscene && !inCinematic) charactersDance();
      songEvents.checkTempEvents();
    }

    #if debug
    if (!endingSong && !startingSong)
    {
      if (FlxG.keys.justPressed.ONE)
      {
        KillNotes();
        FlxG.sound.music.onComplete();
      }
      if (FlxG.keys.justPressed.TWO)
      { // Go 10 seconds into the future :O
        setSongTime(Conductor.songPosition + 10000);
        clearNotesBefore(false, Conductor.songPosition);
      }
    }
    #end

    setOnScripts('botPlay', cpuControlled);

    if (playerStrums.staticColorStrums && !SONG.getSongData('options').disableStrumRGB)
    {
      for (strum in playerStrums)
      {
        if (strum.animation.curAnim.name == 'static')
        {
          strum.rgbShader.r = 0xFFFFFFFF;
          strum.rgbShader.b = 0xFF808080;
        }
      }
    }

    super.update(elapsed);

    callOnScripts('onUpdatePost', [elapsed]);
    callOnScripts('updatePost', [elapsed]);
  }

  public dynamic function moveCameraToTarget(setTarget:String)
  {
    cameraTargeted = setTarget;
    camMustHit = isBFCam = (cameraTargeted == 'bf' || cameraTargeted == 'boyfriend');
    isMomCam = cameraTargeted == 'mom';
    isDadCam = cameraTargeted == 'dad';
    isGFCam = cameraTargeted == 'gf';

    final focusedPlayer:String = 'onFocus${cameraTargeted.toUpperCase()}';

    callOnScripts(focusedPlayer);

    var offsetX = 0;
    var offsetY = 0;

    switch (cameraTargeted)
    {
      case 'dad':
        if (dad != null)
        {
          camFollow.setPosition(dad.getMidpoint().x + 150 + offsetX, dad.getMidpoint().y - 100 + offsetY);

          camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
          camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];

          camFollow.x += dadcamX;
          camFollow.y += dadcamY;

          if (dad.getLastAnimationPlayed().toLowerCase().startsWith('idle')
            || dad.getLastAnimationPlayed().toLowerCase().endsWith('right')
            || dad.getLastAnimationPlayed().toLowerCase().endsWith('left'))
          {
            dadcamY = 0;
            dadcamX = 0;
          }
        }
      case 'gf' | 'girlfriend':
        if (gf != null)
        {
          camFollow.setPosition(gf.getMidpoint().x + offsetX, gf.getMidpoint().y + offsetY);

          camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
          camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];

          camFollow.x += gfcamX;
          camFollow.y += gfcamY;

          if (gf.getLastAnimationPlayed().toLowerCase().startsWith('idle')
            || gf.getLastAnimationPlayed().toLowerCase().endsWith('right')
            || gf.getLastAnimationPlayed().toLowerCase().endsWith('left'))
          {
            gfcamY = 0;
            gfcamX = 0;
          }
        }
      case 'boyfriend' | 'bf':
        if (boyfriend != null)
        {
          camFollow.setPosition(boyfriend.getMidpoint().x - 100 + offsetX, boyfriend.getMidpoint().y - 100 + offsetY);

          camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
          camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

          camFollow.x += bfcamX;
          camFollow.y += bfcamY;

          if (boyfriend.getLastAnimationPlayed().toLowerCase().startsWith('idle')
            || boyfriend.getLastAnimationPlayed().toLowerCase().endsWith('right')
            || boyfriend.getLastAnimationPlayed().toLowerCase().endsWith('left'))
          {
            bfcamY = 0;
            bfcamX = 0;
          }
        }
      case 'mom':
        if (mom != null)
        {
          camFollow.setPosition(mom.getMidpoint().x + 150 + offsetX, mom.getMidpoint().y - 100 + offsetY);

          camFollow.x += mom.cameraPosition[0] + opponent2CameraOffset[0];
          camFollow.y += mom.cameraPosition[1] + opponent2CameraOffset[1];

          camFollow.x += momcamX;
          camFollow.y += momcamY;

          if (mom.getLastAnimationPlayed().toLowerCase().startsWith('idle')
            || mom.getLastAnimationPlayed().toLowerCase().endsWith('right')
            || mom.getLastAnimationPlayed().toLowerCase().endsWith('left'))
          {
            momcamY = 0;
            momcamX = 0;
          }
        }
    }

    callOnScripts('onMoveCamera', [cameraTargeted]);

    if (charCam != null)
    {
      var characterCam:String = '';
      if (charCam == boyfriend) characterCam = 'player';
      else if (charCam == dad) characterCam = 'opponent';
      else if (charCam == gf) characterCam = 'girlfriend';
      var camArray:Array<Float> = stage.cameraCharacters.get(characterCam);

      if (ClientPrefs.data.cameraMovement && !charCam.charNotPlaying && ClientPrefs.data.characters) moveCameraXY(charCam, -1, camArray[0], camArray[1]);
    }
  }

  public dynamic function updateIcons()
  {
    var icons:Array<HealthIcon> = [hud.iconP1, hud.iconP2];

    var percent20or80:Bool = false;
    var percent80or20:Bool = false;

    if (SONG.getSongData('options').oldBarSystem)
    {
      percent20or80 = (hud.whichHud == "HITMANS" ? hud.healthBarHit.percent < 20 : hud.healthBar.percent < 20);
      percent80or20 = (hud.whichHud == "HITMANS" ? hud.healthBarHit.percent > 80 : hud.healthBar.percent > 80);
    }
    else
    {
      percent20or80 = (hud.whichHud == "HITMANS" ? hud.healthBarHitNew.percent < 20 : hud.healthBarNew.percent < 20);
      percent80or20 = (hud.whichHud == "HITMANS" ? hud.healthBarHitNew.percent > 80 : hud.healthBarNew.percent > 80);
    }

    for (i in 0...icons.length)
    {
      icons[i].percent20or80 = percent20or80;
      icons[i].percent80or20 = percent80or20;
      icons[i].healthIndication = hud.health;
      icons[i].speedBopLerp = playbackRate;
    }

    icons[0].setIconScale = hud.playerIconScale;
    icons[1].setIconScale = hud.opponentIconScale;

    for (value in MusicBeatState.getVariables("Icon").keys())
    {
      if (MusicBeatState.getVariables("Icon").get(value) != null && MusicBeatState.getVariables("Icon").exists(value))
      {
        cast(MusicBeatState.getVariables("Icon").get(value), HealthIcon).percent20or80 = percent20or80;
        cast(MusicBeatState.getVariables("Icon").get(value), HealthIcon).percent80or20 = percent80or20;

        cast(MusicBeatState.getVariables("Icon").get(value), HealthIcon).healthIndication = hud.health;
        cast(MusicBeatState.getVariables("Icon").get(value), HealthIcon).speedBopLerp = playbackRate;
      }
    }
  }

  public dynamic function changeOpponentVocalTrack(?prefix:String = null, ?suffix:String = null, ?song:String = null, ?extra:Array<String> = null)
  {
    if (extra == null) extra = [];

    final songData:Song = SONG;
    final newSong:String = song;

    // Extra
    final extraExternVocal:String = extra[0] != null ? extra[0] : null;
    final extraCharacter:String = extra[1] != null ? extra[1] : null;
    final extraDifficulty:String = extra[2] != null ? extra[2] : null;

    // Final
    final vocalOpp:String = (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile;
    final externVocal:String = extraExternVocal != null ? extraExternVocal : vocalOpp;
    final character:String = extraCharacter != null ? extraCharacter : boyfriend.curCharacter;
    final difficulty:String = extraDifficulty != null ? extraDifficulty : Difficulty.getString();

    try
    {
      if (songData.getSongData('needsVoices'))
      {
        if (newSong != null)
        {
          final currentPrefix:String = prefix != null ? prefix : '';
          final currentSuffix:String = suffix != null ? suffix : '';
          final oppVocals = SoundUtil.findVocalOrInst(
            {
              song: newSong,
              prefix: currentPrefix,
              suffix: currentSuffix,
              externVocal: externVocal,
              character: character,
              difficulty: difficulty
            });
          if (oppVocals != null)
          {
            opponentVocals.loadEmbedded(oppVocals);
            splitVocals = true;
            opponentVocals.play();
            opponentVocals.time = Conductor.songPosition;
            #if FLX_PITCH
            opponentVocals.pitch = playbackRate;
            #end
          }
          else
          {
            opponentVocals.exists = false;
            opponentVocals.destroy();
            opponentVocals = new FlxSound();
          }
        }
        else
        {
          final currentPrefix:String = songData.getSongData('options').vocalsPrefix != null ? songData.getSongData('options').vocalsPrefix : '';
          final currentSuffix:String = songData.getSongData('options').vocalsSuffix != null ? songData.getSongData('options').vocalsSuffix : '';
          final oppVocals = SoundUtil.findVocalOrInst(
            {
              song: songData.getSongData('songId'),
              prefix: currentPrefix,
              suffix: currentSuffix,
              externVocal: externVocal,
              character: character,
              difficulty: difficulty
            });

          if (oppVocals != null)
          {
            opponentVocals.loadEmbedded(oppVocals);
            splitVocals = true;
            opponentVocals.play();
            opponentVocals.time = Conductor.songPosition;
            #if FLX_PITCH
            opponentVocals.pitch = playbackRate;
            #end
          }
          else
          {
            opponentVocals.exists = false;
            opponentVocals.destroy();
            opponentVocals = new FlxSound();
          }
        }
      }
    }
    catch (e:Dynamic)
    {
      opponentVocals.exists = false;
      opponentVocals.destroy();
      opponentVocals = new FlxSound();
    }
  }

  public dynamic function changeVocalTrack(?prefix:String = null, ?suffix:String = null, ?song:String = null, ?extra:Array<String> = null)
  {
    if (extra == null) extra = [];

    final songData:Song = SONG;
    final newSong:String = song;

    // Extra
    final extraExternVocal:String = extra[0] != null ? extra[0] : null;
    final extraCharacter:String = extra[1] != null ? extra[1] : null;
    final extraDifficulty:String = extra[2] != null ? extra[2] : null;

    // Final
    final vocalPl:String = (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile;
    final externVocal:String = extraExternVocal != null ? extraExternVocal : vocalPl;
    final character:String = extraCharacter != null ? extraCharacter : boyfriend.curCharacter;
    final difficulty:String = extraDifficulty != null ? extraDifficulty : Difficulty.getString();

    try
    {
      if (songData.getSongData('needsVoices'))
      {
        if (newSong != null)
        {
          final currentPrefix:String = prefix != null ? prefix : '';
          final currentSuffix:String = suffix != null ? suffix : '';
          final normalVocals = Paths.voices(currentPrefix, newSong, currentSuffix);
          final playerVocals = SoundUtil.findVocalOrInst(
            {
              song: newSong,
              prefix: currentPrefix,
              suffix: currentSuffix,
              externVocal: externVocal,
              character: character,
              difficulty: difficulty
            });
          final sound = playerVocals != null ? playerVocals : normalVocals;
          if (sound != null)
          {
            vocals.loadEmbedded(sound);
            vocals.play();
            vocals.time = Conductor.songPosition;
            #if FLX_PITCH
            vocals.pitch = playbackRate;
            #end
          }
          else
          {
            vocals.exists = false;
            vocals.destroy();
            vocals = new FlxSound();
          }
        }
        else
        {
          final currentPrefix:String = songData.getSongData('options').vocalsPrefix != null ? songData.getSongData('options').vocalsPrefix : '';
          final currentSuffix:String = songData.getSongData('options').vocalsSuffix != null ? songData.getSongData('options').vocalsSuffix : '';
          final normalVocals = Paths.voices(currentPrefix, songData.getSongData('song'), currentSuffix);
          final playerVocals = SoundUtil.findVocalOrInst(
            {
              song: songData.getSongData('songId'),
              prefix: currentPrefix,
              suffix: currentSuffix,
              externVocal: externVocal,
              character: character,
              difficulty: difficulty
            });
          final sound = playerVocals != null ? playerVocals : normalVocals;
          if (sound != null)
          {
            vocals.loadEmbedded(sound);
            vocals.play();
            vocals.time = Conductor.songPosition;
            #if FLX_PITCH
            vocals.pitch = playbackRate;
            #end
          }
          else
          {
            vocals.exists = false;
            vocals.destroy();
            vocals = new FlxSound();
          }
        }
      }
    }
    catch (e:Dynamic)
    {
      vocals.exists = false;
      vocals.destroy();
      vocals = new FlxSound();
    }
  }

  public dynamic function changeMusicTrack(?prefix:String = null, ?suffix:String = null, ?song:String = null, ?extra:Array<String> = null)
  {
    if (extra == null) extra = [];

    final songData:Song = SONG;
    final newSong:String = song;

    // Final=Extra
    final externVocal:String = extra[0] != null ? extra[0] : "";
    final character:String = extra[1] != null ? extra[1] : "";
    final difficulty:String = extra[2] != null ? extra[2] : Difficulty.getString();

    try
    {
      if (newSong != null)
      {
        final addedOnPrefix:String = (prefix != null ? prefix : "");
        final addedOnSuffix:String = (suffix != null ? suffix : "");
        inst.loadEmbedded(SoundUtil.findVocalOrInst(
          {
            song: newSong,
            prefix: addedOnPrefix,
            suffix: addedOnSuffix,
            externVocal: externVocal,
            character: character,
            difficulty: difficulty
          }, 'INST'), false);
      }
      else
      {
        final currentPrefix = (songData.getSongData('options').instrumentalPrefix != null ? songData.getSongData('options').instrumentalPrefix : "");
        final currentSuffix = (songData.getSongData('options').instrumentalSuffix != null ? songData.getSongData('options').instrumentalSuffix : "");
        inst.loadEmbedded(SoundUtil.findVocalOrInst(
          {
            song: songData.getSongData('songId'),
            prefix: currentPrefix,
            suffix: currentSuffix,
            externVocal: externVocal,
            character: character,
            difficulty: difficulty
          }, 'INST'), false);
      }

      @:privateAccess
      FlxG.sound.music.loadEmbedded(inst._sound, false);
      FlxG.sound.music.persist = true;
      FlxG.sound.music.play();
      FlxG.sound.music.time = Conductor.songPosition;
      #if FLX_PITCH
      FlxG.sound.music.pitch = playbackRate;
      #end
      if (acceptFinishedSongBind) FlxG.sound.music.onComplete = finishSong.bind();
    }
    catch (e:Dynamic) {}
  }

  function stopSound()
  {
    for (sound in [FlxG.sound.music, vocals, opponentVocals])
    {
      if (sound == null) continue;
      sound.volume = 0;
      sound.stop();
    }
  }

  function openPauseMenu()
  {
    FlxG.camera.followLerp = 0;
    persistentUpdate = false;
    persistentDraw = true;
    paused = true;

    for (sound in [FlxG.sound.music, vocals, opponentVocals])
    {
      if (sound == null) continue;
      sound.pause();
    }

    if (!cpuControlled)
    {
      final group:StrumLine = playerStrums;
      for (note in group)
        if (note.animation.curAnim != null && note.animation.curAnim.name != 'static')
        {
          note.playAnim('static');
          note.resetAnim = 0;
        }
    }

    var pauseSubState = new PauseSubState();
    openSubState(pauseSubState);
    pauseSubState.camera = camPause;

    #if DISCORD_ALLOWED
    if (autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.getSongData('songId') + " (" + storyDifficultyText + ")",
      hud.iconP2.getCharacter());
    #end
  }

  public function openChartEditor(openedOnce:Bool = false)
  {
    if (modchartMode) return false;
    else
    {
      canResync = false;
      FlxG.timeScale = 1;
      FlxG.camera.followLerp = 0;
      chartingMode = true;
      modchartMode = false;
      if (persistentUpdate != false) persistentUpdate = false;
      stopSound();
      #if DISCORD_ALLOWED
      DiscordClient.changePresence("Chart Editor", null, null, true);
      DiscordClient.resetClientID();
      #end

      MusicBeatState.switchState(new ChartingState());
      return true;
    }
  }

  public function openCharacterEditor(openedOnce:Bool = false)
  {
    canResync = false;
    FlxG.timeScale = 1;
    FlxG.camera.followLerp = 0;
    stopSound();
    #if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
    MusicBeatState.switchState(new CharacterEditorState(SONG.getSongData('characters').opponent));
    return true;
  }

  function doDeathCheck(?skipHealthCheck:Bool = false)
  {
    if (((skipHealthCheck && instakillOnMiss) || hud.health <= 0) && !practiceMode && !isDead && gameOverTimer == null)
    {
      var ret:Dynamic = callOnScripts('onGameOver', null, true);
      if (ret != LuaUtil.Function_Stop)
      {
        death();
        return true;
      }
    }
    return false;
  }

  public var isDead:Bool = false; // Don't mess with this on Lua!!!
  public var gameOverTimer:FlxTimer;

  public dynamic function death()
  {
    boyfriend.stunned = paused = true;
    deathCounter++;

    canResync = canPause = false;
    persistentUpdate = persistentDraw = false;
    FlxTimer.globalManager.clear();
    FlxTween.globalManager.clear();
    FlxG.camera.setFilters([]);

    #if VIDEOS_ALLOWED
    if (videoCutscene != null)
    {
      videoCutscene.destroy();
      videoCutscene = null;
    }
    for (vid in VideoSprite._videos)
      vid.destroy();
    VideoSprite._videos = [];
    #end
    if (ClientPrefs.data.instantRespawn && !ClientPrefs.data.characters || boyfriend.deadChar == "" && GameOverSubstate.characterName == "")
    {
      stopSound();
      LoadingState.loadAndSwitchState(new PlayState());
    }
    else
    {
      if (GameOverSubstate.deathDelay > 0)
      {
        gameOverTimer = new FlxTimer().start(GameOverSubstate.deathDelay, function(_) {
          stopSound();
          openSubState(new GameOverSubstate(boyfriend));
          gameOverTimer = null;
        });
      }
      else
      {
        stopSound();
        openSubState(new GameOverSubstate(boyfriend));
      }
    }

    #if DISCORD_ALLOWED
    // Game Over doesn't get his own variable because it's only used here
    if (autoUpdateRPC) DiscordClient.changePresence("Game Over - " + detailsText, SONG.getSongData('songId') + " (" + storyDifficultyText + ")",
      hud.iconP2.getCharacter());
    #end
    isDead = true;
  }

  public var letCharactersSwapNoteSkin:Bool = false; // False because of the stupid work around's with this.
  public var zoomLimitForAdding:Float = 1.35;

  function triggerPlayStateEvent(eventName:String, eventParams:Array<String>, ?eventTime:Float)
  {
    var flValues:Array<Null<Float>> = [];
    for (i in 0...eventParams.length - 1)
    {
      flValues.push(Std.parseFloat(eventParams[i]));
      if (Math.isNaN(flValues[i])) flValues[i] = null;
    }

    function checkString(e:String):Bool
      return e != null && e.length > 0;

    switch (eventName)
    {
      case 'Hey!':
        var value:Int = 2;
        switch (eventParams[0].toLowerCase().trim())
        {
          case 'bf' | 'boyfriend' | '0':
            value = 0;
          case 'gf' | 'girlfriend' | '1':
            value = 1;
          case 'dad' | '2':
            value = 2;
          case 'mom' | '3':
            value = 3;
          default:
            value = 4;
        }

        if (flValues[1] == null || flValues[1] <= 0) flValues[1] = 0.6;

        var checkAnim:String = checkString(eventParams[2]) ? eventParams[2] : 'hey';
        if (checkAnim == '') checkAnim = 'hey';

        if ((value == 3 || value == 4) && mom != null && mom.hasOffsetAnimation(checkAnim))
        {
          mom.playAnim(checkAnim, true);
          if (!mom.skipHeyTimer)
          {
            mom.specialAnim = true;
            mom.heyTimer = flValues[1];
          }
        }
        if ((value == 2 || value == 4) && dad != null && dad.hasOffsetAnimation(checkAnim))
        {
          dad.playAnim(checkAnim, true);
          if (!dad.skipHeyTimer)
          {
            dad.specialAnim = true;
            dad.heyTimer = flValues[1];
          }
        }
        if ((value == 1 || value == 4))
        {
          if (dad.curCharacter.startsWith('gf'))
          {
            // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
            dad.playAnim(dad.hasOffsetAnimation(checkAnim) ? checkAnim : 'cheer', true);
            if (!dad.skipHeyTimer)
            {
              dad.specialAnim = true;
              dad.heyTimer = flValues[1];
            }
          }
          else if (gf != null)
          {
            gf.playAnim(gf.hasOffsetAnimation(checkAnim) ? checkAnim : 'cheer', true);
            if (!gf.skipHeyTimer)
            {
              gf.specialAnim = true;
              gf.heyTimer = flValues[1];
            }
          }
        }
        if ((value == 0 || value == 4))
        {
          boyfriend.playAnim(boyfriend.hasOffsetAnimation(checkAnim) ? checkAnim : 'hey', true);
          if (!boyfriend.skipHeyTimer)
          {
            boyfriend.specialAnim = true;
            boyfriend.heyTimer = flValues[1];
          }
        }

      case 'Set GF Speed':
        if (flValues[0] == null || flValues[0] < 1) flValues[0] = 1;
        if (gf != null) gfSpeed = Math.round(flValues[0]);

      case 'Add Camera Zoom':
        if (ClientPrefs.data.camZooms && FlxG.camera.zoom < zoomLimitForAdding)
        {
          if (flValues[0] == null) flValues[0] = 0.015;
          if (flValues[1] == null) flValues[1] = 0.03;

          FlxG.camera.zoom += flValues[0];
          camHUD.zoom += flValues[1];
        }

      case 'Default Set Camera Zoom': // Add setCamZom as default Event
        var val1:Float = flValues[0];
        var val2:Float = flValues[1];

        if (eventParams[1] == '') defaultCamZoom = val1;
        else
        {
          defaultCamZoom = val1;
          FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, val2, {ease: FlxEase.sineInOut});
        }

      case 'Default Camera Flash': // Add flash as default Event
        var val:String = "0xFF" + eventParams[0];
        var color:FlxColor = Std.parseInt(val);
        var time:Float = Std.parseFloat(eventParams[1]);
        var alpha:Float = checkString(eventParams[3]) ? Std.parseFloat(eventParams[3]) : 0.5;
        if (!ClientPrefs.data.flashing) color.alphaFloat = alpha;

        LuaUtil.cameraFromString(eventParams[2].toLowerCase()).flash(color, time, null, true);

      case 'Play Animation':
        var char:Character = dad;
        switch (eventParams[1].toLowerCase().trim())
        {
          case 'dad' | '0':
            char = dad;
          case 'bf' | 'boyfriend' | '1':
            char = boyfriend;
          case 'gf' | 'girlfriend' | '2':
            char = gf;
          case 'mom' | '3':
            char = mom;
          default:
            char = MusicBeatState.getVariables("Character").get(eventParams[1]);
        }

        characterAnimToPlay(eventParams[0], char);

      case 'Camera Follow Pos':
        if (camFollow != null)
        {
          isCameraOnForcedPos = false;
          if (flValues[0] != null || flValues[1] != null)
          {
            isCameraOnForcedPos = true;
            if (flValues[0] == null) flValues[0] = 0;
            if (flValues[1] == null) flValues[1] = 0;
            camFollow.x = flValues[0];
            camFollow.y = flValues[1];
            if (flValues[2] != null) defaultCamZoom = flValues[2];
          }
        }

      case 'Alt Idle Animation':
        var char:Character = dad;
        switch (eventParams[0].toLowerCase().trim())
        {
          case 'dad':
            char = dad;
          case 'gf' | 'girlfriend':
            char = gf;
          case 'boyfriend' | 'bf':
            char = boyfriend;
          case 'mom':
            char = mom;
          default:
            char = MusicBeatState.getVariables("Character").get(eventParams[0]);
        }

        if (char != null) char.idleSuffix = eventParams[1];

      case 'Screen Shake':
        var valuesArray:Array<String> = [eventParams[0], eventParams[1]];
        var targetsArray:Array<FlxCamera> = [camGame, camHUD];
        for (i in 0...targetsArray.length)
        {
          var split:Array<String> = valuesArray[i].split(',');
          var duration:Float = 0;
          var intensity:Float = 0;
          if (split[0] != null) duration = Std.parseFloat(split[0].trim());
          if (split[1] != null) intensity = Std.parseFloat(split[1].trim());
          if (Math.isNaN(duration)) duration = 0;
          if (Math.isNaN(intensity)) intensity = 0;

          if (duration > 0 && intensity != 0)
          {
            targetsArray[i].shake(intensity, duration);
          }
        }

      case 'Change Character':
        var charType:Int = 0;
        switch (eventParams[0].toLowerCase().trim())
        {
          case 'bf' | 'boyfriend' | '0':
            charType = 0;
            LuaUtil.changeBFAuto(eventParams[1]);

          case 'dad' | '1':
            charType = 1;
            LuaUtil.changeDadAuto(eventParams[1]);

          case 'gf' | 'girlfriend' | '2':
            charType = 2;
            if (gf != null) LuaUtil.changeGFAuto(eventParams[1]);

          case 'mom' | '3':
            charType = 3;
            if (mom != null) LuaUtil.changeMomAuto(eventParams[1]);

          default:
            var char:Character = MusicBeatState.getVariables("Character").get(eventParams[0]);
            if (char != null) LuaUtil.makeLuaCharacter(eventParams[0], eventParams[1], char.isPlayer, char.flipMode);
        }

        if (!SONG.getSongData('options').notITG && !notITGMod && letCharactersSwapNoteSkin)
        {
          if (boyfriend.noteSkin != null && dad.noteSkin != null)
          {
            for (strumLine in [playerStrums, opponentStrums])
            {
              for (n in strumLine.notes.members)
              {
                n.texture = (n.strumLineID == 0 ? boyfriend.noteSkin : dad.noteSkin);
                n.noteSkin = (n.strumLineID == 0 ? boyfriend.noteSkin : dad.noteSkin);
                n.reloadNote(n.noteSkin);
              }
              for (i in strumLine.members)
              {
                i.texture = (i.player == 1 ? boyfriend.noteSkin : dad.noteSkin);
                i.daStyle = (i.player == 1 ? boyfriend.noteSkin : dad.noteSkin);
                i.reloadNote(i.daStyle);
              }
            }
          }
        }

      case 'Change Scroll Speed':
        if (songSpeedType != "constant")
        {
          var speedEase = GenericUtil.getTweenEaseByString(checkString(eventParams[2]) ? eventParams[2] : 'linear');
          if (flValues[0] == null) flValues[0] = 1;
          if (flValues[1] == null) flValues[1] = 0;

          var newValue:Float = SONG.getSongData('speed') * ClientPrefs.getGameplaySetting('scrollspeed') * flValues[0];
          if (flValues[1] <= 0) songSpeed = newValue;
          else
          {
            songSpeedTween = TweenUtil.createTween(tweenManager, this, {songSpeed: newValue}, flValues[1],
              {
                ease: speedEase,
                onComplete: function(twn:FlxTween) {
                  songSpeedTween = null;
                }
              });
          }
        }

      case 'Set Property':
        try
        {
          var trueValue:Dynamic = eventParams[1].trim();
          if (trueValue == 'true' || trueValue == 'false') trueValue = trueValue == 'true';
          else if (flValues[1] != null) trueValue = flValues[1];
          else
            trueValue = eventParams[1];

          final split:Array<String> = eventParams[0].split('.');
          if (split.length > 1) LuaUtil.setVarInArray(LuaUtil.getPropertyLoop(split), split[split.length - 1], trueValue);
          else
            LuaUtil.setVarInArray(this, eventParams[0], trueValue);
        }
        catch (e:Dynamic)
        {
          var len:Int = e.message.indexOf('\n') + 1;
          if (len <= 0) len = e.message.length;
          #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
          addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
          #else
          Debug.logError('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
          #end
        }

      case 'Play Sound':
        if (flValues[1] == null) flValues[1] = 1;
        FlxG.sound.play(Paths.sound(eventParams[0]), flValues[1]);

      case 'Reset Extra Arguments':
        var char:Character = dad;
        switch (eventParams[0].toLowerCase().trim())
        {
          case 'dad' | '0':
            char = dad;
          case 'bf' | 'boyfriend' | '1':
            char = boyfriend;
          case 'gf' | 'girlfriend' | '2':
            char = gf;
          case 'mom' | '3':
            char = mom;
          default:
            char = MusicBeatState.getVariables("Character").get(eventParams[0]);
        }

        if (char != null) char.resetAnimationVars();

      case 'Change Stage':
        changeStage(eventParams[0]);

      case 'Add Cinematic Bars':
        var valueForFloat1:Float = flValues[0];
        if (Math.isNaN(valueForFloat1)) valueForFloat1 = 0;

        var valueForFloat2:Float = flValues[1];
        if (Math.isNaN(valueForFloat2)) valueForFloat2 = 0;

        addCinematicBars(false, valueForFloat1, valueForFloat2);
      case 'Remove Cinematic Bars':
        var valueForFloat1:Float = flValues[0];
        if (Math.isNaN(valueForFloat1)) valueForFloat1 = 0;

        addCinematicBars(true, valueForFloat1);

      case 'Default Set Camera Bop':
        var type:String = 'BEAT';
        if (checkString(eventParams[2])) type = eventParams[2];
        switch (type.toLowerCase())
        {
          case 'beat':
            if (flValues[0] != null) camZoomingBop = flValues[0];
            if (flValues[1] != null) camZoomingMult = Math.round(flValues[1]);
          case 'step':
            if (flValues[0] != null) camZoomingBopStep = flValues[0];
            if (flValues[1] != null) camZoomingMultStep = Math.round(flValues[1]);
          case 'sec', 'section':
            if (flValues[0] != null) camZoomingBopSec = flValues[0];
            if (flValues[1] != null) camZoomingMultSec = Math.round(flValues[1]);
        }

      case 'Set Camera Bop Type':
        if (checkString(eventParams[0])) bopOnBeat = (eventParams[0] == 'true') ? true : false;
        if (checkString(eventParams[1])) bopOnStep = (eventParams[1] == 'true') ? true : false;
        if (checkString(eventParams[2])) bopOnSection = (eventParams[2] == 'true') ? true : false;
      case 'Set Camera Target':
        if (checkString(eventParams[1])) forceChangeOnTarget = (eventParams[1] == 'false') ? false : true;
        if (checkString(eventParams[0])) cameraTargeted = eventParams[0];

      case 'Change Camera Props':
        FlxTween.cancelTweensOf(camFollow);
        FlxTween.cancelTweensOf(defaultCamZoom);
        isCameraFocusedOnCharacters = (eventParams[4] == 'disable' || eventParams[4] == '');
        if (!isCameraFocusedOnCharacters)
        {
          // Props split up from one value.
          final camProps:Array<String> = eventParams[0].split(',');
          final followX:Float = (checkString(camProps[0]) ? Std.parseFloat(camProps[0]) : 0);
          final followY:Float = (checkString(camProps[1]) ? Std.parseFloat(camProps[1]) : 0);
          final zoomForCam:Float = (checkString(camProps[2]) ? Std.parseFloat(camProps[2]) : 0);

          // If camera uses Tweens to make values exact.
          final tweenCamera:Bool = (checkString(eventParams[1]) ? (eventParams[1] == "false" ? false : true) : false);

          // Eases
          final easesPoses:Array<String> = eventParams[2].split(',');
          final easeForX:String = (checkString(easesPoses[0]) ? easesPoses[0] : 'linear');
          final easeForY:String = (checkString(easesPoses[1]) ? easesPoses[1] : 'linear');
          final easeForZoom:String = (checkString(easesPoses[2]) ? easesPoses[2] : 'linear');

          // Time
          final timeForTweens:Array<String> = eventParams[3].split(',');
          final xTime:Float = (checkString(timeForTweens[0]) ? Std.parseFloat(timeForTweens[0]) : 0);
          final yTime:Float = (checkString(timeForTweens[1]) ? Std.parseFloat(timeForTweens[1]) : 0);
          final zoomTime:Float = (checkString(timeForTweens[2]) ? Std.parseFloat(timeForTweens[2]) : 0);

          if (tweenCamera)
          {
            if (checkString(camProps[0])) FlxTween.tween(camFollow, {x: followX}, xTime, {ease: GenericUtil.getTweenEaseByString(easeForX)});
            if (checkString(camProps[1])) FlxTween.tween(camFollow, {y: followY}, yTime, {ease: GenericUtil.getTweenEaseByString(easeForY)});
            if (checkString(camProps[2])) FlxTween.tween(this, {defaultCamZoom: zoomForCam}, zoomTime, {ease: GenericUtil.getTweenEaseByString(easeForZoom)});
          }
          else
          {
            if (checkString(camProps[0])) camFollow.x = followX;
            if (checkString(camProps[1])) camFollow.y = followY;
            if (checkString(camProps[2])) defaultCamZoom = zoomForCam;
          }
        }
    }

    if (stage != null && !finishedSong) stage.eventCalledStage(eventName, eventParams, eventTime);
    callOnScripts('onEvent', [eventName, eventParams, eventTime]);
    callOnScripts('onEventLegacy', [
      eventName,
      eventParams[0],
      eventParams[1],
      eventTime,
      eventParams[2],
      eventParams[3],
      eventParams[4],
      eventParams[5]
    ]);
  }

  public dynamic function characterAnimToPlay(animation:String, char:Character)
  {
    if (!ClientPrefs.data.characters) return;
    if (char != null)
    {
      char.playAnim(animation, true);
      char.specialAnim = true;
    }
  }

  public var cinematicBars:Map<String, FlxSprite> = ["top" => null, "bottom" => null];

  public dynamic function addCinematicBars(remove:Bool = false, speed:Float, ?thickness:Float = 7)
  {
    for (bar in ["top", "bottom"])
    {
      if (cinematicBars[bar] == null)
      {
        cinematicBars[bar] = new FlxSprite(0, 0).makeGraphic(FlxG.width, Std.int(FlxG.height / thickness), FlxColor.BLACK);
        cinematicBars[bar].screenCenter(X);
        cinematicBars[bar].cameras = [camUnderUI];
        cinematicBars[bar].y = bar == "top" ? 0 - cinematicBars["top"].height : FlxG.height; // offscreen
        add(cinematicBars[bar]);
      }
      TweenUtil.createTween(tweenManager, cinematicBars[bar],
        {y: bar == "top" ? (!remove ? 0 : 0 - cinematicBars[bar].height) : (!remove ? FlxG.height - cinematicBars[bar].height : FlxG.height)}, speed,
        {ease: FlxEase.circInOut});
    }
  }

  public var dadcamX:Float = 0;
  public var dadcamY:Float = 0;
  public var gfcamX:Float = 0;
  public var gfcamY:Float = 0;
  public var bfcamX:Float = 0;
  public var bfcamY:Float = 0;
  public var momcamX:Float = 0;
  public var momcamY:Float = 0;

  /**
   * The function is used to move the camera using either the animations of the characters or notehit.
   * @param char The character used to identify the camera Character.
   * @param note If this data is not -1 it will follow the numbers 0-3 for each direction.
   * @param intensity1 The first intensity.
   * @param intensity2 The second intensity.
   */
  public dynamic function moveCameraXY(char:Character = null, note:Int = -1, intensity1:Float = 0, intensity2:Float = 0):Void
  {
    final isDad:Bool = char == dad;
    final isGf:Bool = char == gf;
    final isMom:Bool = char == mom;
    final stringChosen:String = (note > -1 ? Std.string(Std.int(Math.abs(note))) : (!char.isAnimationNull() ? char.getLastAnimationPlayed() : Std.string(Std.int(Math.abs(note)))));
    var camName:String = "";
    var camValueY:Float = 0;
    var camValueX:Float = 0;

    switch (stringChosen)
    {
      case 'singLEFT' | 'singLEFT-alt' | '0':
        camValueY = 0;
        camValueX = -intensity1;
      case 'singDOWN' | 'singDOWN-alt' | '1':
        camValueY = intensity2;
        camValueX = 0;
      case 'singUP' | 'singUP-alt' | '2':
        camValueY = -intensity2;
        camValueX = 0;
      case 'singRIGHT' | 'singRIGHT-alt' | '3':
        camValueY = 0;
        camValueX = intensity1;
    }

    if (isDad) camName = "dad";
    else if (isGf) camName = "gf";
    else if (isMom) camName = "mom";
    else
      camName = "bf";

    Reflect.setProperty(PlayState.instance, camName + 'camX', camValueX);
    Reflect.setProperty(PlayState.instance, camName + 'camY', camValueY);
  }

  public dynamic function finishSong(?ignoreNoteOffset:Bool = false):Void
  {
    finishedSong = true;
    for (sound in [vocals, opponentVocals])
    {
      if (sound == null) continue;
      sound.volume = 0;
      sound.pause();
    }
    if (endCallback == null) return;
    if ((ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset)) endCallback();
    else
    {
      finishTimer = TimerUtil.createTimer(timerManager, ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
        endCallback();
      });
    }
  }

  public var transitioning = false;
  public var alreadyEndedSong:Bool = false;
  public var stoppedAllInstAndVocals:Bool = false;

  public static var finishedSong:Bool = false;
  public static var endSongFast:Bool = false;

  public dynamic function endSong()
  {
    // Should kill you if you tried to cheat
    if (!startingSong)
    {
      playerStrums.notes.forEach(function(daNote:Note) {
        if (daNote != null && daNote.strumTime < songLength - Conductor.safeZoneOffset) hud.health -= 0.05 * healthLoss;
      });
      for (daNote in playerStrums.unspawnNotes.members)
      {
        if (daNote != null && daNote.strumTime < songLength - Conductor.safeZoneOffset)
        {
          hud.health -= 0.05 * healthLoss;
        }
      }

      if (doDeathCheck())
      {
        return false;
      }
    }

    var isNewHighscore:Bool = false;

    endingSong = true;

    for (variable in ['canPause', 'camZooming', 'inCinematic', 'inCutscene'])
      Reflect.setProperty(PlayState.instance, variable, false);

    seenCutscene = chartingMode = modchartMode = false;
    deathCounter = 0;

    hud.endSong();

    function deactivateSound()
    {
      for (sound in [FlxG.sound.music, vocals, opponentVocals])
      {
        if (sound == null) continue;
        sound.active = false;
        sound.volume = 0;
        sound.stop();
      }
    }
    deactivateSound();

    stoppedAllInstAndVocals = !FlxG.sound.music.active;
    alreadyEndedSong = true;

    #if ACHIEVEMENTS_ALLOWED
    var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
    checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
    #end

    var legitTimings:Bool = true;
    for (rating in Rating.timingWindows)
    {
      if (rating.timingWindow != rating.defaultTimingWindow)
      {
        legitTimings = false;
        break;
      }
    }

    var superMegaConditionShit:Bool = legitTimings
      && notITGMod
      && holdsActive
      && !cpuControlled
      && !practiceMode
      && !chartingMode
      && !modchartMode
      && HelperFunctions.truncateFloat(healthGain, 2) <= 1
      && HelperFunctions.truncateFloat(healthLoss, 2) >= 1;
    var ret:Dynamic = callOnScripts('onEndSong', null, true);
    if (ret != LuaUtil.Function_Stop && !transitioning)
    {
      Highscore.songHighScoreData.rankData =
        {
          rating: hud.comboStats.ratingFC,
          comboRank: hud.comboStats.comboLetterRank,
          accuracy: hud.comboStats.ratingPercent
        };
      Highscore.songHighScoreData.mainData.score = hud.comboStats.songScore;
      #if ! switch
      if (superMegaConditionShit)
      {
        if (ClientPrefs.data.behaviourType != 'KADE')
        {
          isNewHighscore = Highscore.isSongHighScore(Highscore.songHighScoreData);

          // If no high score is present, save both score and rank.
          // If score or rank are better, save the highest one.
          // If neither are higher, nothing will change.
          Highscore.applySongRank(Highscore.songHighScoreData);
        }
      }
      #end
      playbackRate = 1;

      if (isStoryMode)
      {
        isNewHighscore = false;
        var percent:Float = hud.comboStats.updateAcc;
        if (Math.isNaN(percent)) percent = 0;
        hud.comboStats.addWeekAverage(HelperFunctions.truncateFloat(percent / storyPlaylist.length, 2));

        hud.comboStats.setWeekAverages();
        hud.comboStats.setRatingAverages();

        Highscore.weekHighScoreData = Highscore.combineScoreData(Highscore.songHighScoreData, Highscore.weekHighScoreData);

        storyPlaylist.shift();

        if (storyPlaylist.length <= 0)
        {
          if (!stoppedAllInstAndVocals) deactivateSound();
          if (superMegaConditionShit)
          {
            StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
            if (Highscore.isWeekHighScore(Highscore.weekHighScoreData))
            {
              isNewHighscore = true;
              Highscore.saveWeekScore(Highscore.weekHighScoreData);
            }
            FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
            FlxG.save.flush();
          }
          changedDifficulty = false;

          if (ClientPrefs.data.behaviourType == 'KADE')
          {
            if (persistentUpdate != false) persistentUpdate = false;
            openSubState(subStates[0]);
            inResults = true;
          }
          #if BASE_GAME_FILES
          else if (ClientPrefs.data.behaviourType == 'VSLICE')
          {
            if (endSongFast) moveToResultsScreen(isNewHighscore, prevScoreData);
            else
              zoomIntoResultsScreen(isNewHighscore, prevScoreData);
          }
          #end
        else
        {
          Mods.loadTopMod();
          FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
          #if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
          MusicBeatState.switchState(new StoryMenuState());
        }
        }
        else
        {
          var difficulty:String = Difficulty.getFilePath();

          Debug.logTrace('LOADING NEXT SONG');
          Debug.logTrace(Paths.formatToSongPath(storyPlaylist[0]) + difficulty);

          FlxTransitionableState.skipNextTransIn = true;
          FlxTransitionableState.skipNextTransOut = true;
          prevCamFollow = camFollow;

          SongJsonData.loadFromJson(
            {
              jsonInput: storyPlaylist[0] + difficulty,
              folder: storyPlaylist[0],
              difficulty: difficulty,
              inputNoDiff: storyPlaylist[0]
            });

          if (!stoppedAllInstAndVocals) deactivateSound();
          LoadingState.prepareToSong();
          LoadingState.loadAndSwitchState(new PlayState(), false, false);
        }
      }
      else
      {
        hud.comboStats.setRatingAverages();

        if (!stoppedAllInstAndVocals) deactivateSound();
        if (ClientPrefs.data.behaviourType == 'KADE')
        {
          if (persistentUpdate != false) persistentUpdate = false;
          openSubState(subStates[0]);
          inResults = true;
        }
        #if BASE_GAME_FILES
        else if (ClientPrefs.data.behaviourType == 'VSLICE')
        {
          if (endSongFast) moveToResultsScreen(isNewHighscore);
          else
            zoomIntoResultsScreen(isNewHighscore);
        }
        #end
      else
      {
        Debug.logTrace('WENT BACK TO FREEPLAY??');
        Mods.loadTopMod();
        #if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
        MusicBeatState.switchState(new FreeplayState());
        FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
        changedDifficulty = false;
      }
      }
      transitioning = true;

      if (forceMiddleScroll)
      {
        if (savePrefixScrollR && prefixRightScroll)
        {
          ClientPrefs.data.middleScroll = false;
        }
      }
      else if (forceRightScroll)
      {
        if (savePrefixScrollM && prefixMiddleScroll)
        {
          ClientPrefs.data.middleScroll = true;
        }
      }
    }
    return true;
  }

  /**
   * Play the camera zoom animation and then move to the results screen once it's done.
   */
  function zoomIntoResultsScreen(isNewHighscore:Bool, ?prevScoreData:HighScoreData):Void
  {
    Debug.logInfo('WENT TO RESULTS SCREEN!');

    // Stop camera zooming.
    camZooming = false;

    // If the opponent is GF, zoom in on the opponent.
    // Else, if there is no GF, zoom in on BF.
    // Else, zoom in on GF.
    var targetDad:Bool = dad != null && dad.characterId == 'gf';
    var targetBF:Bool = gf == null && !targetDad;

    if (targetBF) FlxG.camera.follow(boyfriend, null, 0.05);
    else if (targetDad) FlxG.camera.follow(dad, null, 0.05);
    else
      FlxG.camera.follow(gf, null, 0.05);

    // TODO: Make target offset configurable.
    // In the meantime, we have to replace the zoom animation with a fade out.
    FlxG.camera.targetOffset.y -= 350;
    FlxG.camera.targetOffset.x += 20;

    // Replace zoom animation with a fade out for now.
    FlxG.camera.fade(FlxColor.BLACK, 0.6);

    for (camera in [camVideo, camUnderUI, camOther, camNoteStuff, camStuff, mainCam])
      FlxTween.tween(camera, {alpha: 0}, 0.6);
    FlxTween.tween(camHUD, {alpha: 0}, 0.6, {onComplete: function(_) moveToResultsScreen(isNewHighscore, prevScoreData)});

    // Zoom in on Girlfriend (or BF if no GF)
    new FlxTimer().start(0.8, function(_) {
      if (targetBF) boyfriend.playAnim('hey');
      else if (targetDad) dad.playAnim('cheer');
      else
        gf.playAnim('cheer');
    });
  }

  /**
   * Move to the results screen right goddamn now.
   */
  function moveToResultsScreen(isNewHighscore:Bool, ?prevScoreData:HighScoreData):Void
  {
    persistentUpdate = false;
    camHUD.alpha = 1;

    var dataToUse:HighScoreData = isStoryMode ? Highscore.weekHighScoreData : Highscore.songHighScoreData;
    dataToUse.mainData.score = isStoryMode ? ComboStats.averageWeekScore : hud.comboStats.songScore;

    var resS:scfunkin.states.substates.vslice.ResultState = new scfunkin.states.substates.vslice.ResultState(
      {
        storyMode: isStoryMode,
        songId: songName,
        difficultyId: Difficulty.getString(storyDifficulty),
        title: isStoryMode ? WeekData.getWeekFileName() : songName,
        prevScoreData: prevScoreData,
        scoreData: dataToUse,
        isNewHighscore: isNewHighscore
      });
    persistentDraw = false;
    openSubState(resS);
  }

  public function KillNotes()
  {
    for (strumLine in strumLines)
    {
      while (strumLine.notes.length > 0)
      {
        final daNote:Note = strumLine.notes.members[0];
        strumLine.invalidateNote(daNote, false);
      }
      strumLine.unspawnNotes.clear();
    }
    songEvents.tempEvents = [];
  }

  public static function sortHitNotes(a:Note, b:Note):Int
  {
    if (a.lowPriority && !b.lowPriority) return 1;
    else if (!a.lowPriority && b.lowPriority) return -1;
    return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
  }

  public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
  {
    if (key != NONE)
    {
      for (i in 0...arr.length)
      {
        var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
        for (noteKey in note)
          if (key == noteKey) return i;
      }
    }
    return -1;
  }

  public dynamic function charactersDance()
  {
    if (!ClientPrefs.data.characters) return;

    // The game now thinks it's needed completely!
    for (value in MusicBeatState.getVariables("Character").keys())
    {
      if (MusicBeatState.getVariables("Character").get(value) != null && MusicBeatState.getVariables("Character").exists(value))
      {
        var daChar:Character = MusicBeatState.getVariables("Character").get(value);
        if (daChar != null)
        {
          if ((daChar.isPlayer && !daChar.flipMode || !daChar.isPlayer && daChar.flipMode)) daChar.danceConditions(daChar.allowHoldTimer());
        }
      }
    }
  }

  public var playDad:Bool = true;
  public var playBF:Bool = true;

  public dynamic function noteMiss(daNote:Note, strumLine:StrumLine):Void
  {
    strumLine.notes.forEachAlive(function(note:Note) {
      if (daNote != note
        && daNote.noteData == note.noteData
        && daNote.isSustainNote == note.isSustainNote
        && Math.abs(daNote.strumTime - note.strumTime) < 1) strumLine.invalidateNote(note, false);
    });
    var dType:Int = 0;

    if (daNote != null)
    {
      dType = daNote.dType;
      if (ClientPrefs.data.behaviourType == 'KADE')
      {
        daNote.rating = Rating.timingWindows[0];
        ResultsScreenKadeSubstate.instance.registerHit(daNote, true, cpuControlled, Rating.timingWindows[0].timingWindow);
      }
    }
    else if (songStarted && SONG.getSongData('notes')[curSection] != null) dType = SONG.getSongData('notes')[curSection].dType;

    var result:Dynamic = callOnLuas('noteMissPre', [
      playerStrums.notes.members.indexOf(daNote),
      daNote.noteData,
      daNote.noteType,
      daNote.isSustainNote
    ]);
    var result2:Dynamic = callOnAllHS('noteMissPre', [daNote]);
    if (result == LuaUtil.Function_Stop || result2 == LuaUtil.Function_Stop) return;
    if (stage != null) stage.noteMissStage(daNote);
    noteMissCommon(daNote.noteData, daNote, strumLine);
    FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.5, 0.6));
    callOnLuas('noteMiss', [
      playerStrums.notes.members.indexOf(daNote),
      daNote.noteData,
      daNote.noteType,
      daNote.isSustainNote,
      dType
    ]);
    callOnAllHS('noteMiss', [daNote]);
  }

  public dynamic function noteMissPress(direction:Int = 1, strumLine:StrumLine):Void // You pressed a key when there was no notes to press for this key
  {
    if (ClientPrefs.data.ghostTapping) return; // fuck it

    noteMissCommon(direction, strumLine);
    if (ClientPrefs.data.missSounds && !finishedSong) FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.5, 0.6));
    if (stage != null) stage.noteMissPressStage(direction);
    callOnScripts('playerOneMissPress', [direction, Conductor.songPosition]);
    callOnScripts('noteMissPress', [direction]);
  }

  public dynamic function noteMissCommon(direction:Int, note:Note = null, strumLine:StrumLine)
  {
    strumLine.missHoldCover(direction, note);

    // score and data
    var char:Character = strumLine == playerStrums ? boyfriend : dad;
    var dType:Int = 0;
    var subtract:Float = pressMissDamage;
    if (note != null) subtract = note.missHealth;

    // GUITAR HERO SUSTAIN CHECK LOL!!!!
    if (note != null && guitarHeroSustains && note.parent == null)
    {
      if (note.parent == null)
      {
        if (note.tail.length != 0)
        {
          note.alpha = 0.3;
          for (childNote in note.tail)
          {
            childNote.alpha = 0.3;
            childNote.missed = true;
            childNote.canBeHit = false;
            childNote.ignoreNote = true;
            childNote.tooLate = true;
          }
          note.missed = true;
          note.canBeHit = false;

          // subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
          // i mean its fair :p -crow
          subtract *= note.tail.length + 1;
          // i think it would be fair if damage multiplied based on how long the sustain is -Tahir
        }

        if (note.missed) return;
      }
      else if (note.parent != null && note.isSustainNote)
      {
        if (note.missed) return;

        var parentNote:Note = note.parent;
        if (parentNote.wasGoodHit && parentNote.tail.length != 0)
        {
          for (child in parentNote.tail)
            if (child != note)
            {
              child.missed = true;
              child.canBeHit = false;
              child.ignoreNote = true;
              child.tooLate = true;
            }
        }
      }
    }

    hud.comboStats.miss();
    hud.health -= subtract * healthLoss;

    vocals.volume = 0;
    if (instakillOnMiss) doDeathCheck(true);

    if (((note != null && note.gfNote)
      || (SONG.getSongData('notes')[curSection] != null && SONG.getSongData('notes')[curSection].gfSection))
      && gf != null) char = gf;
    if (((note != null && note.momNote)
      || (SONG.getSongData('notes')[curSection] != null && SONG.getSongData('notes')[curSection].player4Section))
      && mom != null) char = mom;

    if (note != null) dType = note.dType;
    else if (songStarted && SONG.getSongData('notes')[curSection] != null) dType = SONG.getSongData('notes')[curSection].dType;

    if (strumLine == playerStrums)
    {
      playBF = searchLuaVar('playBFSing', 'bool', false);

      if (playBF) char.onNoteEffect(direction, note, true);
    }
    else if (strumLine == opponentStrums)
    {
      playDad = searchLuaVar('playDadSing', 'bool', false);

      if (playDad) char.onNoteEffect(direction, note, true);
    }
  }

  public dynamic function opponentNoteHit(note:Note):Void
  {
    if (note.wasGoodHit && opponentMode) return;
    final singData:Int = Std.int(Math.abs(note.noteData));
    var char:Character = dad;

    final result:Dynamic = callOnLuas('dadPreNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
    final result2:Dynamic = callOnAllHS('dadPreNoteHit', [note]);
    final result3:Dynamic = callOnLuas('playerTwoPreSing', [note.noteData, Conductor.songPosition]);
    final result4:Dynamic = callOnAllHS('playerTwoPreSing', [note]);
    final result5:Dynamic = callOnLuas('opponentNoteHitPre', [
      playerStrums.notes.members.indexOf(note),
      Math.abs(note.noteData),
      note.noteType,
      note.isSustainNote,
      note.dType
    ]);
    final result6:Dynamic = callOnAllHS('opponentNoteHitPre', [note]);
    if (result == LuaUtil.Function_Stop || result2 == LuaUtil.Function_Stop || result3 == LuaUtil.Function_Stop || result4 == LuaUtil.Function_Stop
      || result5 == LuaUtil.Function_Stop || result6 == LuaUtil.Function_Stop) return;

    if (note.gfNote && gf != null) char = gf;
    else if ((SONG.getSongData('notes')[curSection] != null && SONG.getSongData('notes')[curSection].player4Section || note.momNote)
      && mom != null) char = mom;

    note.canSplash = ((!note.noteSplashData.disabled
      && !note.isSustainNote
      && ClientPrefs.splashOption('Opponent')
      && !hud.popupScoreForOp)
      && !SONG.getSongData('options').notITG);
    if (note.canSplash)
    {
      opponentStrums.spawnSplash(
        {
          currentDataIndex: note.noteData,
          targetNote: note,
          isPlayer: opponentStrums.characterStrumlineType == 'DAD'
        });
    }

    playDad = searchLuaVar('playDadSing', 'bool', false);

    var characterCam:String = '';
    switch (char.characterType)
    {
      case 'BF':
        characterCam = 'player';
      case 'DAD':
        characterCam = 'opponent';
      case 'GF':
        characterCam = 'girlfriend';
      default:
        characterCam = '';
    }
    final camArray:Array<Float> = stage.cameraCharacters.get(characterCam);

    if (ClientPrefs.data.cameraMovement
      && (char.charNotPlaying || !ClientPrefs.data.characters)) moveCameraXY(char, note.noteData, camArray[0], camArray[1]);

    if (playDad) char.onNoteEffect(note.noteData, note, false);
    if (splitVocals) opponentVocals.volume = 1;
    else
      vocals.volume = 1;

    if (opponentMode) note.wasGoodHit = true;
    else
      note.hitByOpponent = true;
    if (ClientPrefs.data.LightUpStrumsOP) opponentStrums.playConfirm(note.noteData, Conductor.stepCrochet * 1.25 / 1000 / playbackRate, note.isSustainNote);
    if (opponentStrums.staticColorStrums && !SONG.getSongData('options').disableStrumRGB)
    {
      opponentStrums.members[note.noteData].rgbShader.r = note.rgbShader.r;
      opponentStrums.members[note.noteData].rgbShader.g = note.rgbShader.g;
      opponentStrums.members[note.noteData].rgbShader.b = note.rgbShader.b;
    }

    if (!note.isSustainNote && hud.popupScoreForOp) hud.displayPopedCombo(opponentStrums, note, true);

    opponentStrums.spawnHoldCover(note);

    if (stage != null) stage.opponentNoteHitStage(note);

    callOnLuas('playerTwoSing', [note.noteData, Conductor.songPosition]);
    callOnAllHS('playerTwoSing', [note]);
    callOnLuas('dadNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
    callOnAllHS('dadNoteHit', [note]);
    callOnLuas('opponentNoteHit', [
      opponentStrums.notes.members.indexOf(note),
      Math.abs(note.noteData),
      note.noteType,
      note.isSustainNote,
      note.dType
    ]);
    callOnAllHS('opponentNoteHit', [note]);

    if (!note.isSustainNote) opponentStrums.invalidateNote(note, false);
  }

  public dynamic function goodNoteHit(note:Note):Void
  {
    if (note.wasGoodHit && !opponentMode) return;
    if (cpuControlled && note.ignoreNote) return;
    final songLightUp:Bool = (cpuControlled || chartingMode || modchartMode || showCaseMode);

    final isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
    final leData:Int = Math.round(Math.abs(note.noteData));
    final leType:String = note.noteType;
    final leDType:Int = note.dType;
    final singData:Int = Std.int(Math.abs(note.noteData));
    var char:Character = boyfriend;

    final result:Dynamic = callOnLuas('bfPreNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
    final result2:Dynamic = callOnAllHS('bfPreNoteHit', [note]);
    final result3:Dynamic = callOnLuas('playerOnePreSing', [note.noteData, Conductor.songPosition]);
    final result4:Dynamic = callOnAllHS('playerOnePreSing', [note]);
    final result5:Dynamic = callOnLuas('goodNoteHitPre', [
      playerStrums.notes.members.indexOf(note),
      Math.abs(note.noteData),
      note.noteType,
      note.isSustainNote,
      note.dType
    ]);
    final result6:Dynamic = callOnAllHS('goodNoteHitPre', [note]);
    if (result == LuaUtil.Function_Stop || result2 == LuaUtil.Function_Stop || result3 == LuaUtil.Function_Stop || result4 == LuaUtil.Function_Stop
      || result5 == LuaUtil.Function_Stop || result6 == LuaUtil.Function_Stop) return;

    if (note.gfNote && gf != null) char = gf;
    else if ((SONG.getSongData('notes')[curSection] != null && SONG.getSongData('notes')[curSection].player4Section || note.momNote)
      && mom != null) char = mom;

    if (!opponentMode) note.wasGoodHit = true;
    else
      note.hitByOpponent = true;

    if (note.hitsound != null && note.hitsoundVolume > 0 && !note.hitsoundDisabled) FlxG.sound.play(Paths.sound(note.hitsound), note.hitsoundVolume);

    if (!note.hitCausesMiss) // Common notes
    {
      playBF = searchLuaVar('playBFSing', 'bool', false);

      var characterCam:String = '';
      switch (char.characterType)
      {
        case 'BF':
          characterCam = 'player';
        case 'DAD':
          characterCam = 'opponent';
        case 'GF':
          characterCam = 'girlfriend';
        default:
          characterCam = '';
      }

      final camArray:Array<Float> = stage.cameraCharacters.get(characterCam);

      if (ClientPrefs.data.cameraMovement
        && (char.charNotPlaying || !ClientPrefs.data.characters)) moveCameraXY(char, note.noteData, camArray[0], camArray[1]);
      if (playBF) char.onNoteEffect(note.noteData, note, false);
      playerStrums.playConfirm(note.noteData, !songLightUp ? -1 : (Conductor.stepCrochet * 1.25 / 1000 / playbackRate), isSus);

      vocals.volume = 1;
      if (playerStrums.staticColorStrums && !SONG.getSongData('options').disableStrumRGB)
      {
        playerStrums.members[note.noteData].rgbShader.r = note.rgbShader.r;
        playerStrums.members[note.noteData].rgbShader.g = note.rgbShader.g;
        playerStrums.members[note.noteData].rgbShader.b = note.rgbShader.b;
      }

      if (!note.isSustainNote) hud.displayPopedCombo(playerStrums, note, false);
      var gainHealth:Bool = true; // prevent health gain, as sustains are threated as a singular note
      if (guitarHeroSustains && note.isSustainNote) gainHealth = false;
      if (gainHealth) hud.health += note.hitHealth * healthGain;

      playerStrums.spawnHoldCover(note);

      if (stage != null) stage.goodNoteHitStage(note);
    }
    else // Notes that count as a miss if you hit them (Hurt notes for example)
    {
      if (!note.noMissAnimation)
      {
        switch (note.noteType)
        {
          case 'Hurt Note':
            if (char.hasOffsetAnimation('hurt'))
            {
              char.playAnim('hurt', true);
              char.specialAnim = true;
            }
        }
      }
      noteMiss(note, playerStrums);
      note.canSplash = ((!note.noteSplashData.disabled && !note.isSustainNote && ClientPrefs.splashOption('Player'))
        && !SONG.getSongData('options').notITG);
      if (note.canSplash)
      {
        playerStrums.spawnSplash(
          {
            currentDataIndex: note.noteData,
            targetNote: note,
            isPlayer: playerStrums.characterStrumlineType == 'BF'
          });
      }
    }

    vocals.volume = 1;

    callOnLuas('playerOneSing', [note.noteData, Conductor.songPosition]);
    callOnAllHS('playerOneSing', [note]);
    callOnLuas('bfNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
    callOnAllHS('bfNoteHit', [note]);
    callOnLuas('goodNoteHit', [
      playerStrums.notes.members.indexOf(note),
      Math.abs(note.noteData),
      note.noteType,
      note.isSustainNote,
      note.dType
    ]);
    callOnAllHS('goodNoteHit', [note]);

    if (!note.isSustainNote) playerStrums.invalidateNote(note, false);
  }

  public override function destroy()
  {
    #if desktop
    Application.current.window.title = Main.appName;
    #end

    FlxG.camera.setFilters([]);

    FlxG.timeScale = 1;
    #if FLX_PITCH FlxG.sound.music.pitch = 1; #end
    Note.globalRgbShaders = [];
    Note.globalQuantRgbShaders = [];
    scfunkin.backend.data.note.NoteTypesConfig.clearNoteTypesData();
    scfunkin.backend.data.note.NoteTypeConfigJson.clearNoteTypeData();

    tweenManager.clear();
    timerManager.clear();

    #if VIDEOS_ALLOWED
    if (videoCutscene != null)
    {
      videoCutscene.destroy();
      videoCutscene = null;
    }
    #end

    stage.onDestroy();

    instance = null;

    if (FlxG.sound.music != null) FlxG.sound.music.pause();
    super.destroy();
  }

  var lastStepHit:Int = -1;

  public var bopOnStep:Bool = false;
  public var bopOnBeat:Bool = true;
  public var bopOnSection:Bool = false;

  override function stepHit()
  {
    if (bopOnStep)
    {
      if (camZooming && camZoomingBopStep > 0 && camZoomingMultStep > 0 && FlxG.camera.zoom < maxCamZoom && ClientPrefs.data.camZooms
        && curStep % camZoomingMultStep == 0 && continueBeatBop)
      {
        FlxG.camera.zoom += defaultCamBopZoom * camZoomingBopStep;
        camHUD.zoom += defaultHUDBopZoom * camZoomingBopStep;
      }
    }

    if (stage != null) stage.onStepHit(curStep);

    super.stepHit();

    if (curStep == lastStepHit) return;

    lastStepHit = curStep;

    setOnScripts('curStep', curStep);
    callOnScripts('stepHit');
    callOnScripts('onStepHit');
  }

  var lastBeatHit:Int = -1;

  public var defaultCamBopZoom:Float = 0.015;
  public var defaultHUDBopZoom:Float = 0.03;

  override function beatHit()
  {
    if (lastBeatHit >= curBeat) return;

    // move it here, uh, much more useful then just each section
    if (bopOnBeat)
    {
      if (camZooming && camZoomingBop > 0 && camZoomingMult > 0 && FlxG.camera.zoom < maxCamZoom && ClientPrefs.data.camZooms
        && curBeat % camZoomingMult == 0 && continueBeatBop)
      {
        FlxG.camera.zoom += defaultCamBopZoom * camZoomingBop;
        camHUD.zoom += defaultHUDBopZoom * camZoomingBop;
      }
    }

    hud.beatHit(curBeat);

    characterBopper(curBeat);

    if (stage != null) stage.onBeatHit(curBeat);

    super.beatHit();
    lastBeatHit = curBeat;

    setOnScripts('curBeat', curBeat);
    callOnScripts('beatHit');
    callOnScripts('onBeatHit');
  }

  public var gfSpeed(default, set):Int = 1; // how frequently gf would play their beat animation

  public function set_gfSpeed(value:Int):Int
  {
    if (Math.isNaN(value)) value = 1;
    gfSpeed = value;
    for (char in [boyfriend, dad, mom, gf])
      if (char != null) char.gfSpeed = value;
    for (characterValue in MusicBeatState.getVariables("Character").keys())
    {
      if (MusicBeatState.getVariables("Character").get(characterValue) != null
        && MusicBeatState.getVariables("Character").exists(characterValue))
      {
        var daChar:Character = MusicBeatState.getVariables("Character").get(characterValue);
        if (daChar != null) daChar.gfSpeed = value;
      }
    }
    return value;
  }

  public var forcedToIdle:Bool = false;

  public function characterBopper(beat:Int):Void
  {
    if (!ClientPrefs.data.characters) return;
    final cpuAlt:Bool = SONG.getSongData('notes')[curSection] != null ? SONG.getSongData('notes')[curSection].CPUAltAnim : false;
    final playerAlt:Bool = SONG.getSongData('notes')[curSection] != null ? SONG.getSongData('notes')[curSection].playerAltAnim : false;
    if (boyfriend != null) boyfriend.isAltSection = playerAlt;
    if (dad != null) dad.isAltSection = cpuAlt;
    if (boyfriend != null && boyfriend.danceTime(beat)) boyfriend.danceChar('player', playerAlt, forcedToIdle);
    if (dad != null && dad.danceTime(beat)) dad.danceChar('opponent', cpuAlt, forcedToIdle);
    if (mom != null && mom.danceTime(beat)) mom.danceChar('opponent', cpuAlt, forcedToIdle);
    if (gf != null && gf.danceTime(beat)) gf.danceChar('girlfriend');
    for (value in MusicBeatState.getVariables("Character").keys())
    {
      if (MusicBeatState.getVariables("Character").get(value) != null && MusicBeatState.getVariables("Character").exists(value))
      {
        var daChar:Character = MusicBeatState.getVariables("Character").get(value);
        if (daChar != null && daChar.danceTime(beat)) daChar.danceChar('custom_char');
      }
    }
  }

  override function sectionHit()
  {
    if (bopOnSection)
    {
      if (camZooming && camZoomingBopSec > 0 && camZoomingMultSec > 0 && FlxG.camera.zoom < maxCamZoom && ClientPrefs.data.camZooms
        && curSection % camZoomingMultSec == 0 && continueBeatBop)
      {
        FlxG.camera.zoom += defaultCamBopZoom * camZoomingBopSec;
        camHUD.zoom += defaultHUDBopZoom * camZoomingBopSec;
      }
    }
    if (SONG.getSongData('notes')[curSection] != null)
    {
      if (SONG.getSongData('notes')[curSection].changeBPM)
      {
        if (Conductor.bpm != SONG.getSongData('notes')[curSection].bpm) Conductor.bpm = SONG.getSongData('notes')[curSection].bpm;

        setOnScripts('curBpm', Conductor.bpm);
        setOnScripts('crochet', Conductor.crochet);
        setOnScripts('stepCrochet', Conductor.stepCrochet);
      }
      for (sectionVariable in [
        'mustHitSection',
        'altAnim',
        'gfSection',
        'playerAltAnim',
        'CPUAltAnim',
        'player4Section'
      ])
        setOnScripts(sectionVariable, Reflect.getProperty(SONG.getSongData('notes')[curSection], sectionVariable));

      if (!SONG.getSongData('options').oldBarSystem)
      {
        changeObjectToTweeningColor(hud.timeBarNew.leftBar, SONG.getSongData('notes')[curSection].gfSection,
          SONG.getSongData('notes')[curSection].mustHitSection, (Conductor.stepCrochet * 4) / 1000, 'sineInOut');
      }
    }

    if (stage != null) stage.onSectionHit(curSection);

    super.sectionHit();

    setOnScripts('curSection', curSection);
    callOnScripts('sectionHit');
    callOnScripts('onSectionHit');
  }

  public function changeObjectToTweeningColor(sprite:FlxSprite, isGF:Bool, isMustHit:Bool, ?time:Float = 1, ?easeStr:String = 'linear')
  {
    var curColor:FlxColor = sprite.color;
    curColor.alphaFloat = sprite.alpha;
    if (isGF) FlxTween.color(sprite, time, curColor, CoolUtil.colorFromString(gf.iconColorFormatted), {ease: GenericUtil.getTweenEaseByString(easeStr)});
    else
    {
      if (isMustHit) FlxTween.color(sprite, time, curColor, CoolUtil.colorFromString(boyfriend.iconColorFormatted),
        {ease: GenericUtil.getTweenEaseByString(easeStr)});
      else
        FlxTween.color(sprite, time, curColor, CoolUtil.colorFromString(dad.iconColorFormatted), {ease: GenericUtil.getTweenEaseByString(easeStr)});
    }
  }

  #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
  public function startNoteTypesNamed(type:String)
  {
    #if LUA_ALLOWED
    startLuasNamed('custom_notetypes/scripts/' + type);
    #end
    #if HSCRIPT_ALLOWED
    startHScriptsNamed('custom_notetypes/scripts/' + type);
    startSCHSNamed('custom_notetypes/scripts/sc/' + type);
    #if HScriptImproved startHSIScriptsNamed('custom_notetypes/scripts/advanced/' + type); #end
    #end
  }

  public function startEventsNamed(event:String)
  {
    #if LUA_ALLOWED
    startLuasNamed('custom_events/scripts/' + event);
    #end
    #if HSCRIPT_ALLOWED
    startHScriptsNamed('custom_events/scripts/' + event);
    startSCHSNamed('custom_events/scripts/sc/' + event);
    #if HScriptImproved startHSIScriptsNamed('custom_events/scripts/advanced/' + event); #end
    #end
  }
  #end

  override public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    if (stage != null && stage.isCustomStage) stage.callOnScripts(funcToCall, args, ignoreStops, exclusions, excludeValues);
    return super.callOnScripts(funcToCall, args, ignoreStops, exclusions, excludeValues);
  }

  override public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    if (stage != null && stage.isCustomStage && stage.isLuaStage) stage.callOnLuas(funcToCall, args);
    return super.callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
  }

  override public function callOnHScript(funcToCall:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    if (stage != null && stage.isCustomStage && stage.isHxStage) stage.callOnHScript(funcToCall, args);
    return super.callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
  }

  override public function callOnHSI(funcToCall:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    if (stage != null && stage.isCustomStage && stage.isHxStage) stage.callOnHSI(funcToCall, args);
    return super.callOnHSI(funcToCall, args, ignoreStops, exclusions, excludeValues);
  }

  override public function callOnSCHS(funcToCall:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    if (stage != null && stage.isCustomStage && stage.isHxStage) stage.callOnSCHS(funcToCall, args);
    return super.callOnSCHS(funcToCall, args, ignoreStops, exclusions, excludeValues);
  }

  override public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    if (stage != null && stage.isCustomStage) stage.setOnScripts(variable, arg, exclusions);
    return super.setOnScripts(variable, arg, exclusions);
  }

  override public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if LUA_ALLOWED
    if (stage != null && stage.isCustomStage && stage.isLuaStage) stage.setOnLuas(variable, arg);
    #end
    return super.setOnLuas(variable, arg, exclusions);
  }

  override public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if LUA_ALLOWED
    if (stage != null && stage.isCustomStage && stage.isHxStage) stage.setOnHScript(variable, arg);
    #end
    return super.setOnHScript(variable, arg, exclusions);
  }

  override public function setOnHSI(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    if (stage != null && stage.isCustomStage && stage.isHxStage) stage.setOnHSI(variable, arg);
    return super.setOnHSI(variable, arg, exclusions);
  }

  override public function setOnSCHS(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    if (stage != null && stage.isCustomStage && stage.isHxStage) stage.setOnSCHS(variable, arg);
    return super.setOnSCHS(variable, arg, exclusions);
  }

  override public function getOnScripts(variable:String, arg:String, exclusions:Array<String> = null)
  {
    if (stage != null && stage.isCustomStage) stage.getOnScripts(variable, arg, exclusions);
    return super.getOnScripts(variable, arg, exclusions);
  }

  override public function getOnLuas(variable:String, arg:String, exclusions:Array<String> = null)
  {
    if (stage != null && stage.isCustomStage && stage.isLuaStage) stage.getOnLuas(variable, arg, exclusions);
    return super.getOnLuas(variable, arg, exclusions);
  }

  override public function getOnHScript(variable:String, exclusions:Array<String> = null)
  {
    if (stage != null && stage.isCustomStage && stage.isHxStage) stage.getOnHScript(variable, exclusions);
    return super.getOnHScript(variable, exclusions);
  }

  override public function getOnHSI(variable:String, exclusions:Array<String> = null)
  {
    if (stage != null && stage.isCustomStage && stage.isHxStage) stage.getOnHSI(variable, exclusions);
    return super.getOnHSI(variable, exclusions);
  }

  override public function getOnSCHS(variable:String, exclusions:Array<String> = null)
  {
    if (stage != null && stage.isCustomStage && stage.isHxStage) stage.getOnSCHS(variable, exclusions);
    return super.getOnSCHS(variable, exclusions);
  }

  override public function searchLuaVar(variable:String, arg:String, result:Bool)
  {
    if (stage != null && stage.isCustomStage && stage.isLuaStage) stage.searchLuaVar(variable, arg, result);
    return super.searchLuaVar(variable, arg, result);
  }

  #if ACHIEVEMENTS_ALLOWED
  private function checkForAchievement(achievesToCheck:Array<String> = null)
  {
    if (chartingMode || modchartMode || cpuControlled) return;

    final usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));

    for (name in achievesToCheck)
    {
      if (!Achievements.exists(name)) continue;

      var unlock:Bool = false;
      if (name != WeekData.getWeekFileName() + '_nomiss') // common achievements
      {
        switch (name)
        {
          case 'ur_bad':
            unlock = (hud.comboStats.ratingPercent < 0.2 && !practiceMode);

          case 'ur_good':
            unlock = (hud.comboStats.ratingPercent >= 1 && !usedPractice);

          case 'oversinging':
            unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

          case 'hype':
            unlock = (!boyfriendIdled && !usedPractice);

          case 'two_keys':
            unlock = (!usedPractice && keysPressed.length <= 2);

          case 'toastie':
            unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);

          case 'debugger':
            unlock = (songName == 'test' && !usedPractice);
        }
      }
      else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
      {
        if (isStoryMode
          && ComboStats.averageWeekMisses + hud.comboStats.songMisses < 1
          && (Difficulty.getString().toUpperCase() == 'HARD' || Difficulty.getString().toUpperCase() == 'NIGHTMARE')
          && storyPlaylist.length <= 1
          && !changedDifficulty
          && !usedPractice) unlock = true;
      }

      if (unlock) Achievements.unlock(name);
    }
  }
  #end

  public function cacheCharacter(character:String,
      ?superCache:Bool = false) // Make cacheCharacter function not repeat already preloaded characters! ///NEEDS CONSTANT PRELOADING LOL
  {
    try
    {
      final cacheChar:Character = new Character(0, 0, character);
      Debug.logInfo('found ' + character);
      cacheChar.alpha = 0.00001;
      cacheChar.loadCharacterScript(cacheChar.curCharacter);
      cacheChar.destroy();
      if (superCache)
      {
        add(cacheChar);
        remove(cacheChar);
      }
    }
    catch (e:Dynamic)
      Debug.logError('Error on $e');
  }

  #if (!flash && sys)
  public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();

  public function createRuntimeShader(name:String):FlxRuntimeShader
  {
    if (!ClientPrefs.data.shaders) return new FlxRuntimeShader();

    #if (!flash && MODS_ALLOWED && sys)
    if (!runtimeShaders.exists(name) && !initLuaShader(name))
    {
      FlxG.log.warn('Shader $name is missing!');
      return new FlxRuntimeShader();
    }

    final arr:Array<String> = runtimeShaders.get(name);
    return new FlxRuntimeShader(arr[0], arr[1]);
    #else
    FlxG.log.warn("Platform unsupported for Runtime Shaders!");
    return null;
    #end
  }

  public function initLuaShader(name:String)
  {
    if (!ClientPrefs.data.shaders) return false;

    #if (MODS_ALLOWED && !flash && sys)
    if (runtimeShaders.exists(name))
    {
      FlxG.log.warn('Shader $name was already initialized!');
      return true;
    }

    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/shaders/'))
    {
      var frag:String = folder + name + '.frag';
      var vert:String = folder + name + '.vert';
      var found:Bool = false;

      frag = FileSystem.exists(frag) ? File.getContent(frag) : null;
      vert = FileSystem.exists(vert) ? File.getContent(vert) : null;
      found = (FileSystem.exists(frag) || FileSystem.exists(vert));

      if (found)
      {
        runtimeShaders.set(name, [frag, vert]);
        return true;
      }
    }
    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
    #else
    FlxG.log.warn('Missing shader $name .frag AND .vert files!');
    #end
    #else
    FlxG.log.warn('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
    #end
    return false;
  }
  #end

  // does this work. right? -- future me here. yes it does.
  public function changeStage(id:String)
  {
    if (!ClientPrefs.data.background) return;
    if (ClientPrefs.data.characters) for (character in [gf, dad, mom, boyfriend])
      if (character != null) remove(character);
    if (stage != null) stage.onDestroy();

    stage = new Stage(id);
    stage.setupStageProperties(SONG.getSongData('songId'), true);
    stage.curStage = curStage = id;
    defaultCamZoom = stage.camZoom;
    cameraSpeed = stage.stageCameraSpeed;

    for (i in stage.toAdd)
      add(i);

    for (index => array in stage.layInFront)
    {
      switch (index)
      {
        case 0:
          if (ClientPrefs.data.characters) if (gf != null) add(gf);
          for (bg in array)
            add(bg);
        case 1:
          if (ClientPrefs.data.characters) add(dad);
          for (bg in array)
            add(bg);
        case 2:
          if (ClientPrefs.data.characters) if (mom != null) add(mom);
          for (bg in array)
            add(bg);
        case 3:
          if (ClientPrefs.data.characters) add(boyfriend);
          for (bg in array)
            add(bg);
        case 4:
          if (ClientPrefs.data.characters)
          {
            if (gf != null) add(gf);
            add(dad);
            if (mom != null) add(mom);
            add(boyfriend);
          }
          for (bg in array)
            add(bg);
      }
    }

    if (stage.isCustomStage) stage.callOnScripts('onCreatePost'); // i swear if this starts crashing stuff i'mma cry
    setCameraOffsets();
  }
}
