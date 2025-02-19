package scfunkin.states;

import lime.app.Future;
import sys.thread.FixedThreadPool;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.media.Sound;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;
import sys.thread.Thread;
import sys.thread.Mutex;
import scfunkin.backend.data.StageData;
import scfunkin.objects.ui.Character;
import scfunkin.objects.note.Note;
import scfunkin.objects.note.NoteSplash;

#if cpp
@:headerCode('
#include <iostream>
#include <thread>
')
#end
class LoadingState extends MusicBeatState
{
  public static var loaded:Int = 0;
  public static var loadMax:Int = 0;

  static var originalBitmapKeys:Map<String, String> = [];
  static var requestedBitmaps:Map<String, BitmapData> = [];
  static var mutex:Mutex;
  static var threadPool:FixedThreadPool = null;

  function new(target:FlxState, stopMusic:Bool)
  {
    this.target = target;
    this.stopMusic = stopMusic;

    super();
  }

  inline static public function loadAndSwitchState(target:FlxState, stopMusic = false, intrusive:Bool = true)
    MusicBeatState.switchState(getNextState(target, stopMusic, intrusive));

  var target:FlxState = null;
  var stopMusic:Bool = false;

  var dontUpdate:Bool = false;

  var bar:FlxSprite;
  var barWidth:Int = 0;
  var intendedPercent:Float = 0;
  var curPercent:Float = 0;
  var canChangeState:Bool = true;

  var funkay:FlxSprite;

  override function create()
  {
    #if !SHOW_LOADING_SCREEN
    while (true)
    #end
    {
      if (checkLoaded())
      {
        dontUpdate = true;
        super.create();
        onLoad();
        return;
      }
      #if !SHOW_LOADING_SCREEN
      Sys.sleep(0.001);
      #end
    }

    // BASE GAME LOADING SCREEN
    var bg = new FlxSprite().makeGraphic(1, 1, 0xFFCAFF4D);
    bg.scale.set(FlxG.width, FlxG.height);
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    funkay = new FlxSprite(0, 0).loadGraphic(Paths.image('funkay'));
    funkay.antialiasing = ClientPrefs.data.antialiasing;
    funkay.setGraphicSize(0, FlxG.height);
    funkay.updateHitbox();
    add(funkay);

    var bg:FlxSprite = new FlxSprite(0, 660).makeGraphic(1, 1, FlxColor.BLACK);
    bg.scale.set(FlxG.width - 300, 25);
    bg.updateHitbox();
    bg.screenCenter(X);
    add(bg);

    bar = new FlxSprite(bg.x + 5, bg.y + 5).makeGraphic(1, 1, FlxColor.WHITE);
    bar.scale.set(0, 15);
    bar.updateHitbox();
    add(bar);
    barWidth = Std.int(bg.width - 10);

    persistentUpdate = true;
    super.create();
  }

  var transitioning:Bool = false;

  override function update(elapsed:Float)
  {
    super.update(elapsed);
    if (dontUpdate) return;

    if (!transitioning)
    {
      if (canChangeState && !finishedLoading && checkLoaded())
      {
        transitioning = true;
        onLoad();
        return;
      }
      intendedPercent = loaded / loadMax;
    }

    if (curPercent != intendedPercent)
    {
      if (Math.abs(curPercent - intendedPercent) < 0.001) curPercent = intendedPercent;
      else
        curPercent = FlxMath.lerp(intendedPercent, curPercent, Math.exp(-elapsed * 15));

      bar.scale.x = barWidth * curPercent;
      bar.updateHitbox();
    }
  }

  var finishedLoading:Bool = false;

  function onLoad()
  {
    _loaded();

    if (stopMusic && FlxG.sound.music != null) FlxG.sound.music.stop();

    FlxG.camera.visible = false;
    MusicBeatState.switchState(target);
    transitioning = true;
    finishedLoading = true;
  }

  static function _loaded()
  {
    loaded = 0;
    loadMax = 0;
    initialThreadCompleted = true;
    isIntrusive = false;

    FlxTransitionableState.skipNextTransIn = true;
    if (threadPool != null) threadPool.shutdown(); // kill all workers safely
    threadPool = null;
    mutex = null;
  }

  public static function checkLoaded():Bool
  {
    for (key => bitmap in requestedBitmaps)
    {
      if (bitmap != null
        && Paths.cacheBitmap(originalBitmapKeys.get(key), bitmap) != null) Debug.logInfo('finished preloading image $key');
      else
        Debug.logError('failed to cache image $key');
    }
    requestedBitmaps.clear();
    originalBitmapKeys.clear();
    return (loaded >= loadMax && initialThreadCompleted);
  }

  public static function loadNextDirectory()
  {
    var directory:String = 'shared';
    var weekDir:String = StageData.forceNextDirectory;
    StageData.forceNextDirectory = null;

    if (weekDir != null && weekDir.length > 0) directory = weekDir;

    Paths.setCurrentLevel(directory);
    Debug.logInfo('Setting asset folder to ' + directory);
  }

  static var isIntrusive:Bool = false;

  static function getNextState(target:FlxState, stopMusic = false, intrusive:Bool = true):FlxState
  {
    LoadingState.isIntrusive = intrusive;
    _startPool();
    loadNextDirectory();

    if (intrusive) return new LoadingState(target, stopMusic);

    if (stopMusic && FlxG.sound.music != null) FlxG.sound.music.stop();

    while (true)
    {
      if (checkLoaded())
      {
        _loaded();
        break;
      }
      else
        Sys.sleep(0.001);
    }
    return target;
  }

  static var imagesToPrepare:Array<String> = [];
  static var soundsToPrepare:Array<String> = [];
  static var musicToPrepare:Array<String> = [];
  static var songsToPrepare:Array<String> = [];

  public static function prepare(images:Array<String> = null, sounds:Array<String> = null, music:Array<String> = null)
  {
    if (images != null) imagesToPrepare = imagesToPrepare.concat(images);
    if (sounds != null) soundsToPrepare = soundsToPrepare.concat(sounds);
    if (music != null) musicToPrepare = musicToPrepare.concat(music);
  }

  static var initialThreadCompleted:Bool = true;
  static var dontPreloadDefaultVoices:Bool = false;

  static function _startPool()
  {
    threadPool = new FixedThreadPool(#if MULTITHREADED_LOADING #if cpp getCPUThreadsCount() #else 8 #end #else 1 #end);
  }

  public static function prepareToSong()
  {
    if (PlayState.SONG == null)
    {
      imagesToPrepare = [];
      soundsToPrepare = [];
      musicToPrepare = [];
      songsToPrepare = [];
      loaded = 0;
      loadMax = 0;
      initialThreadCompleted = true;
      isIntrusive = false;
      return;
    }

    _startPool();
    imagesToPrepare = [];
    soundsToPrepare = [];
    musicToPrepare = [];
    songsToPrepare = [];

    initialThreadCompleted = false;
    var threadsCompleted:Int = 0;
    var threadsMax:Int = 0;
    function completedThread()
    {
      threadsCompleted++;
      if (threadsCompleted == threadsMax)
      {
        clearInvalids();
        startThreads();
        initialThreadCompleted = true;
      }
    }

    final song:Song = PlayState.SONG;
    final folder:String = Paths.formatToSongPath(SongJsonData.loadedSongName);
    new Future<Bool>(() -> {
      // LOAD NOTE IMAGE
      var noteSkin:String = Note.defaultNoteSkin;
      if (song.getSongData('options').arrowSkin != null
        && song.getSongData('options').arrowSkin.length > 1) noteSkin = song.getSongData('options').arrowSkin;

      var customSkin:String = noteSkin + Note.getNoteSkinPostfix();
      if (Paths.fileExists('images/$customSkin.png', IMAGE)) noteSkin = customSkin;
      if (!song.getSongData('options').notITG && noteSkin.length > 0) imagesToPrepare.push(noteSkin);
      //

      // LOAD NOTE SPLASH IMAGE
      var noteSplash:String = NoteSplash.defaultNoteSplash;
      if (song.getSongData('options').splashSkin != null
        && song.getSongData('options').splashSkin.length > 0) noteSplash = song.getSongData('options').splashSkin;
      else
        noteSplash += NoteSplash.getSplashSkinPostfix();
      if (!song.getSongData('options').notITG && noteSplash.length > 0) imagesToPrepare.push(noteSplash);
      //

      // LOAD HOLD COVER IMAGE
      var holdCoverSkin:String = "";
      if (song.getSongData('options').holdCoverSkin != null
        && song.getSongData('options').holdCoverSkin.length > 1) noteSkin = song.getSongData('options').holdCoverSkin;
      else
        holdCoverSkin = "holdCover";

      var pref:String = "";
      if (!holdCoverSkin.startsWith("HoldNoteEffect/")) pref = "HoldNoteEffect/";
      if (!song.getSongData('options').disableHoldCovers && !song.getSongData('options').notITG && holdCoverSkin.length > 0)
      {
        if (song.getSongData('options').disableHoldCoversRGB) imagesToPrepare.push(pref + holdCoverSkin);
        else
        {
          var colors:Array<String> = ["Purple", "Blue", "Green", "Purple"];
          for (i in 0...colors.length)
            imagesToPrepare.push(pref + holdCoverSkin + colors[i]);
        }
      }
      //

      // LOAD STRUM NOTE IMAGE
      var strumSkin:String = "";
      if (song.getSongData('options').strumSkin != null
        && song.getSongData('options').strumSkin.length > 1) strumSkin = song.getSongData('options').strumSkin;
      if (!song.getSongData('options').notITG && strumSkin.length > 0) imagesToPrepare.push(strumSkin);
      //

      try
      {
        var path:String = Paths.json('songs/$folder/preload');
        var json:Dynamic = null;

        #if MODS_ALLOWED
        var moddyFile:String = Paths.modsJson('songs/$folder/preload');
        if (FileSystem.exists(moddyFile)) json = Json.parse(File.getContent(moddyFile));
        else
          json = Json.parse(File.getContent(path));
        #else
        json = Json.parse(Assets.getText(path));
        #end

        if (json != null)
        {
          var imgs:Array<String> = [];
          var snds:Array<String> = [];
          var mscs:Array<String> = [];
          for (asset in Reflect.fields(json))
          {
            var filters:Int = Reflect.field(json, asset);
            var asset:String = asset.trim();

            if (filters < 0 || StageData.validateVisibility(filters))
            {
              if (asset.startsWith('images/')) imgs.push(asset.substr('images/'.length));
              else if (asset.startsWith('sounds/')) snds.push(asset.substr('sounds/'.length));
              else if (asset.startsWith('music/')) mscs.push(asset.substr('music/'.length));
            }
          }
          prepare(imgs, snds, mscs);
        }
      }
      catch (e:Dynamic) {}
      return true;
    }, isIntrusive).then((_) -> new Future<Bool>(() -> {
      if (song.getSongData('stage') == null || song.getSongData('stage').length < 1) song.setSongData('stage', StageData.vanillaSongStage(folder));

      final stageData:StageFile = StageData.getStageFile(song.getSongData('stage'));
      if (stageData != null)
      {
        var imgs:Array<String> = [];
        var snds:Array<String> = [];
        var mscs:Array<String> = [];
        if (stageData.preload != null)
        {
          for (asset in Reflect.fields(stageData.preload))
          {
            var filters:Int = Reflect.field(stageData.preload, asset);
            var asset:String = asset.trim();
            if (filters < 0 || StageData.validateVisibility(filters))
            {
              if (asset.startsWith('images/')) imgs.push(asset.substr('images/'.length));
              else if (asset.startsWith('sounds/')) snds.push(asset.substr('sounds/'.length));
              else if (asset.startsWith('music/')) mscs.push(asset.substr('music/'.length));
            }
          }
        }

        if (stageData.objects != null)
        {
          for (sprite in stageData.objects)
          {
            if (sprite.type == 'sprite' || sprite.type == 'animatedSprite') if ((sprite.filters < 0
              || StageData.validateVisibility(sprite.filters))
              && !imgs.contains(sprite.image)) imgs.push(sprite.image);
          }
        }

        prepare(imgs, snds, mscs);
      }

      var suffixedInst:String = '';
      var prefixedInst:String = '';
      var prefixInst:String = '';

      prefixedInst = (song.getSongData('options').instrumentalPrefix != null ? song.getSongData('options').instrumentalPrefix : '');
      suffixedInst = (song.getSongData('options').instrumentalSuffix != null ? song.getSongData('options').instrumentalSuffix : '');
      prefixInst = '$folder/${prefixedInst}Inst${suffixedInst}';

      songsToPrepare.push(prefixInst);

      var player1:String = song.getSongData('characters').player;
      var player2:String = song.getSongData('characters').opponent;
      var gfVersion:String = song.getSongData('characters').girlfriend;
      var prefixedVocals:String = '';
      var suffixedVocals:String = '';
      var prefixVocals:String = '';
      if (song.getSongData('needsVoices'))
      {
        prefixedVocals = (song.getSongData('options').vocalsPrefix != null ? song.getSongData('options').vocalsPrefix : '');
        suffixedVocals = (song.getSongData('options').vocalsSuffix != null ? song.getSongData('options').vocalsSuffix : '');
        prefixVocals = '$folder/${prefixedVocals}Voices${suffixedVocals}';
      }
      else
        prefixVocals = null;
      if (gfVersion == null) gfVersion = 'gf';

      dontPreloadDefaultVoices = false;
      preloadCharacter(player1, song.getSongData('characters').player, prefixVocals);
      if (!dontPreloadDefaultVoices && prefixVocals != null)
      {
        if (Paths.fileExists('$prefixVocals-Player.${Paths.SOUND_EXT}', SOUND, false, 'songs')
          && Paths.fileExists('$prefixVocals-Opponent.${Paths.SOUND_EXT}', SOUND, false, 'songs'))
        {
          songsToPrepare.push('$prefixVocals-Player');
          songsToPrepare.push('$prefixVocals-Opponent');
        }
        else if (Paths.fileExists('$prefixVocals-$player1.${Paths.SOUND_EXT}', SOUND, false, 'songs')
          && Paths.fileExists('$prefixVocals-$player2.${Paths.SOUND_EXT}', SOUND, false, 'songs'))
        {
          songsToPrepare.push('$prefixVocals-$player1');
          songsToPrepare.push('$prefixVocals-$player2');
        }
        else if (Paths.fileExists('$prefixVocals.${Paths.SOUND_EXT}', SOUND, false, 'songs')) songsToPrepare.push(prefixVocals);
      }

      if (player2 != player1)
      {
        threadsMax++;
        threadPool.run(() -> {
          try
          {
            preloadCharacter(player2, prefixVocals);
          }
          catch (e:Dynamic) {}
          completedThread();
        });
      }
      if (!stageData.hide_girlfriend && gfVersion != player2 && gfVersion != player1)
      {
        threadsMax++;
        threadPool.run(() -> {
          try
          {
            preloadCharacter(gfVersion);
          }
          catch (e:Dynamic) {}
          completedThread();
        });
      }
      if (threadsCompleted == threadsMax)
      {
        clearInvalids();
        startThreads();
        initialThreadCompleted = true;
      }
      return true;
    }, isIntrusive)).onError((err:Dynamic) -> {
      Debug.logInfo('ERROR! while preparing song: $err');
    });
  }

  public static function clearInvalids()
  {
    clearInvalidFrom(imagesToPrepare, 'images', '.png', IMAGE);
    clearInvalidFrom(soundsToPrepare, 'sounds', '.${Paths.SOUND_EXT}', SOUND);
    clearInvalidFrom(musicToPrepare, 'music', ' .${Paths.SOUND_EXT}', SOUND);
    clearInvalidFrom(songsToPrepare, 'songs', '.${Paths.SOUND_EXT}', SOUND, 'songs');

    for (arr in [imagesToPrepare, soundsToPrepare, musicToPrepare, songsToPrepare])
      while (arr.contains(null))
        arr.remove(null);
  }

  static function clearInvalidFrom(arr:Array<String>, prefix:String, ext:String, type:AssetType, ?parentfolder:String = null)
  {
    for (folder in arr.copy())
    {
      var nam:String = folder.trim();
      if (nam.endsWith('/'))
      {
        for (subfolder in Mods.directoriesWithFile(Paths.getSharedPath(), '$prefix/$nam'))
        {
          for (file in FileSystem.readDirectory(subfolder))
          {
            if (file.endsWith(ext))
            {
              var toAdd:String = nam + haxe.io.Path.withoutExtension(file);
              if (!arr.contains(toAdd)) arr.push(toAdd);
            }
          }
        }
      }
    }

    var i:Int = 0;
    while (i < arr.length)
    {
      var member:String = arr[i];
      var myKey = '$prefix/$member$ext';
      if (parentfolder == 'songs') myKey = '$member$ext';

      var doTrace:Bool = false;
      if (member.endsWith('/') || (!Paths.fileExists(myKey, type, false, parentfolder) && (doTrace = true)))
      {
        arr.remove(member);
        if (doTrace) Debug.logWarn('Removed invalid $prefix: $member');
      }
      else
        i++;
    }
  }

  public static function startThreads()
  {
    mutex = new Mutex();
    loadMax = imagesToPrepare.length + soundsToPrepare.length + musicToPrepare.length + songsToPrepare.length;
    loaded = 0;

    // then start threads
    _threadFunc();
  }

  static function _threadFunc()
  {
    _startPool();
    for (sound in soundsToPrepare)
      initThread(() -> preloadSound('sounds/$sound'), 'sound $sound');
    for (music in musicToPrepare)
      initThread(() -> preloadSound('music/$music'), 'music $music');
    for (song in songsToPrepare)
      initThread(() -> preloadSound(song, 'songs', true, false), 'song $song');

    // for images, they get to have their own thread
    for (image in imagesToPrepare)
      initThread(() -> preloadGraphic(image), 'image $image');
  }

  static function initThread(func:Void->Dynamic, traceData:String)
  {
    // trace('scheduled $func in threadPool');
    #if debug
    var threadSchedule = Sys.time();
    #end
    threadPool.run(() -> {
      #if debug
      var threadStart = Sys.time();
      trace('$traceData took ${threadStart - threadSchedule}s to start preloading');
      #end

      try
      {
        if (func() != null)
        {
          #if debug
          var diff = Sys.time() - threadStart;
          trace('finished preloading $traceData in ${diff}s');
          #end
        }
        else
          trace('ERROR! fail on preloading $traceData ');
      }
      catch (e:Dynamic)
      {
        trace('ERROR! fail on preloading $traceData: $e');
      }
      // mutex.acquire();
      loaded++;
      // mutex.release();
    });
  }

  inline private static function preloadCharacter(char:String, ?player:String, ?prefixVocals:String)
  {
    try
    {
      var path:String = Paths.getPath('data/characters/$char.json', TEXT);
      var character:Dynamic = Json.parse(#if MODS_ALLOWED File.getContent(path) #else Assets.getText(path) #end);

      var isAnimateAtlas:Bool = false;
      var img:String = character.image;
      img = img.trim();
      #if flxanimate
      var animToFind:String = Paths.getPath('images/$img/Animation.json', TEXT);
      if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind)) isAnimateAtlas = true;
      #end

      if (!isAnimateAtlas)
      {
        var split:Array<String> = img.split(',');
        for (file in split)
        {
          imagesToPrepare.push(file.trim());
        }
      }
      #if flxanimate
      else
      {
        for (i in 0...10)
        {
          var st:String = '$i';
          if (i == 0) st = '';

          if (Paths.fileExists('images/$img/spritemap$st.png', IMAGE))
          {
            // trace('found Sprite PNG');
            imagesToPrepare.push('$img/spritemap$st');
            break;
          }
        }
      }
      #end

      if (prefixVocals != null && character.vocals_file != null && character.vocals_file.length > 0)
      {
        songsToPrepare.push(prefixVocals + "-" + character.vocals_file);
        if (char == player) dontPreloadDefaultVoices = true;
      }
    }
    catch (e:haxe.Exception)
    {
      Debug.logError(e.details());
    }
  }

  // thread safe sound loader
  static function preloadSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true):Null<Sound>
  {
    var file:String = Paths.getPath(Language.getFileTranslation(key) + '.${Paths.SOUND_EXT}', SOUND, path, modsAllowed);

    // trace('precaching sound: $file');
    if (!Paths.currentTrackedSounds.exists(file))
    {
      if (#if sys FileSystem.exists(file) || #end OpenFlAssets.exists(file, SOUND))
      {
        var sound:Sound = #if sys Sound.fromFile(file) #else OpenFlAssets.getSound(file, false) #end;
        mutex.tryAcquire();
        Paths.currentTrackedSounds.set(file, sound);
        mutex.release();
      }
      else if (beepOnNull)
      {
        Debug.logError('SOUND NOT FOUND: $key, PATH: $path');
        return FlxAssets.getSound('flixel/sounds/beep');
      }
    }
    mutex.tryAcquire();
    Paths.localTrackedAssets.push(file);
    mutex.release();

    return Paths.currentTrackedSounds.get(file);
  }

  // thread safe sound loader
  static function preloadGraphic(key:String):Null<BitmapData>
  {
    try
    {
      var requestKey:String = 'images/$key';
      #if TRANSLATIONS_ALLOWED requestKey = Language.getFileTranslation(requestKey); #end
      if (requestKey.lastIndexOf('.') < 0) requestKey += '.png';

      if (!Paths.currentTrackedAssets.exists(requestKey))
      {
        var file:String = Paths.getPath(requestKey, IMAGE);
        if (#if sys FileSystem.exists(file) || #end OpenFlAssets.exists(file, IMAGE))
        {
          var bitmap:BitmapData = #if sys BitmapData.fromFile(file) #else OpenFlAssets.getBitmapData(file, false) #end;
          mutex.tryAcquire();
          requestedBitmaps.set(file, bitmap);
          originalBitmapKeys.set(file, requestKey);
          mutex.release();
          return bitmap;
        }
        else
          Debug.logWarn('no such image $key exists');
      }

      return Paths.currentTrackedAssets.get(requestKey).bitmap;
    }
    catch (e:haxe.Exception)
    {
      Debug.logError('ERROR! fail on preloading image $key');
    }

    return null;
  }

  #if cpp
  @:functionCode('
		return std::thread::hardware_concurrency();
    	')
  @:noCompletion
  public static function getCPUThreadsCount():Int
  {
    return -1;
  }
  #end
}
