package scfunkin.play.song.data;

import tjson.TJSON as Json;
import lime.utils.Assets;
import scfunkin.objects.note.Note;
import scfunkin.utils.ReflectUtil;

using scfunkin.play.song.data.SongData;

class SongJsonData
{
  public static function convert(songJson:Dynamic) // Convert old charts to psych_v1 format
  {
    function checkToString(e:Dynamic)
    {
      if (e == null) return "";
      final a:String = !Std.isOfType(e, String) ? Std.string(e) : e;
      return a;
    }
    if (songJson.events == null)
    {
      songJson.events = [];
      for (secNum in 0...songJson.notes.length)
      {
        var sec:SwagSection = songJson.notes[secNum];

        var i:Int = 0;
        var notes:Array<Dynamic> = sec.sectionNotes;
        var len:Int = notes.length;
        while (i < len)
        {
          var note:Array<Dynamic> = notes[i];
          if (note[1] < 0)
          { // StrumTime /EventName,         V1,   V2,     V3,      V4,      V5,      V6,      V7,      V8,       V9,       V10,      V11,      V12,      V13,      V14
            songJson.events.push([
              note[0],
              [
                [
                  note[2],
                  [
                    checkToString(note[3]),
                    checkToString(note[4]),
                    checkToString(note[5]),
                    checkToString(note[6]),
                    checkToString(note[7]),
                    checkToString(note[8])
                  ]
                ]
              ]
            ]);
            notes.remove(note);
            len = notes.length;
          }
          else
            i++;
        }
      }
    }

    var sectionsData:Array<SwagSection> = songJson.notes;
    if (sectionsData == null) return;

    for (section in sectionsData)
    {
      var beats:Null<Float> = cast section.sectionBeats;
      if (beats == null || Math.isNaN(beats))
      {
        section.sectionBeats = 4;
        if (Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
      }

      // NOTE: Psych Engine does NOT have multikey out of the box, this is simply done in case you WANT to add it via scripting
      // there's no UI element in the chart editor to modify the value of `totalColumns` so you might wanna change that manually yourself
      // if you're forking the engine, you might wanna add that
      var totalColumns:Int = cast(songJson.totalColumns, Int);
      if (totalColumns < 1) totalColumns = 4; // just in case

      for (note in section.sectionNotes)
      {
        var gottaHitNote:Bool = (note[1] < totalColumns) ? section.mustHitSection : !section.mustHitSection;
        note[1] = (note[1] % totalColumns) + (gottaHitNote ? 0 : totalColumns);

        if (note[3] != null && !Std.isOfType(note[3], String)) note[3] = Note.defaultNoteTypes[note[3]]; // compatibility with Week 7 and 0.1-0.3 psych charts
      }
    }
  }

  public static function generalChecks(songJson:Dynamic)
  {
    if (songJson.totalColumns == null || songJson.totalColumns < 1) songJson.totalColumns = 4;
    if (songJson.strumLineIds == null || songJson.strumLineIds.length < 1) songJson.strumLineIds = [0, 1];
    if (songJson.offset == null) songJson.offset = 0; // Offset can be negative
  }

  public static var chartPath:String;
  public static var chartProgress:SCSwagProgress =
    {
      preconvert: null,
      convert: null,
      postconvert: null,
    };

  public static var loadedSongName:String;
  public static var formattedSongName:String;
  public static var displayedName:String;
  public static var formattedDisplayedName:String;

  public static function loadFromJson(swagInput:SwagJsonInput, ?isExternal:Bool = false):Song
  {
    if (swagInput.folder == null) swagInput.folder = swagInput.jsonInput;
    loadedSongName = swagInput.folder;

    final songMap:SCSongMap = getSongMap(swagInput, isExternal);
    currentSongMap.songName = swagInput.folder;
    currentSongMap.songMap.charts = songMap.charts;
    currentSongMap.songMap.difficulties = songMap.difficulties;

    final difficulty:String = swagInput.difficulty.replace('-', '');
    final swagSong:SwagSong = songFromDifficulty(difficulty);
    PlayState.SONG = new Song(swagSong).loadFromCurrentSong();

    chartPath = _lastPath.replace('/', '\\');
    formattedSongName = Paths.formatToSongPath(PlayState.SONG.getSongData('songId'));
    Debug.logInfo(_lastPath);
    Debug.logInfo(chartPath);
    StageData.loadDirectory(PlayState.SONG);
    displayedName = PlayState.SONG.getSongData('displayName') != null ? PlayState.SONG.getSongData('displayName') : swagInput.folder;
    formattedDisplayedName = PlayState.SONG.getSongData('displayName') != null ? Paths.formatToSongPath(displayedName,
      '') : Paths.formatToSongPath(PlayState.SONG.getSongData('songId'), '');
    return PlayState.SONG;
  }

  static function getDifficultyFromString(s:String):String
  {
    final split:Array<String> = s.split('-');
    final trueInput:String = split.length > 1 ? split[1] : 'normal';
    return trueInput.replace('-', '').replace('.json', '').toLowerCase();
  }

  static var _lastPath:String;
  static var _lastLastPath:String;

  public static function getChart(swagInput:SwagJsonInput, ?isExternal:Bool = false):SwagSong
  {
    if (swagInput.folder == null) swagInput.folder = swagInput.jsonInput;
    var rawData:String = null;

    var formattedFolder:String = Paths.formatToSongPath(swagInput.folder, isExternal ? '' : 'lowercased');
    var formattedSong:String = Paths.formatToSongPath(swagInput.jsonInput, isExternal ? '' : 'lowercased');
    _lastLastPath = isExternal ? Paths.getPath('$formattedFolder$formattedSong.json') : Paths.json('songs/$formattedFolder/$formattedSong');
    Debug.logInfo('$_lastLastPath');
    rawData = getFileContent(_lastLastPath);
    return rawData != null ? parseJSON(rawData, swagInput.jsonInput) : null;
  }

  public static var currentSongMap:SCCharts =
    {
      songName: null,
      songMap:
        {
          charts: [],
          difficulties: []
        }
    };

  public static function chartFromDifficulty(difficulty:String):SwagChart
    return currentSongMap.songMap.charts.get(difficulty) ?? null;

  public static function diffFromDifficulty(difficulty:String):SwagDifficulty
    return currentSongMap.songMap.difficulties.get(difficulty) ?? null;

  public static function songFromDifficulty(difficulty:String):SwagSong
  {
    final chart:SwagChart = chartFromDifficulty(difficulty);
    final diff:SwagDifficulty = diffFromDifficulty(difficulty);
    final swag:SwagSong =
      {
        song: diff.song,
        songId: diff.songId,
        displayName: diff.displayName,
        bpm: diff.bpm,
        needsVoices: diff.needsVoices,
        speed: diff.speed,
        offset: diff.offset,
        stage: diff.stage,
        format: diff.format,
        options: diff.options,
        gameOverData: diff.gameOverData,
        characters: diff.characters,
        _extraData: diff._extraData,
        strumLineIds: diff.strumLineIds,
        totalColumns: diff.totalColumns,
        notes: chart.notes,
        events: chart.events
      };
    return swag;
  }

  public static function convertToSongMap(swagInput:SwagJsonInput, isExternal):SCSongMap
  {
    swagInput.folder = swagInput.inputNoDiff;
    var songTemp:SCSongMap =
      {
        charts: [],
        difficulties: []
      };

    for (difficulty in Difficulty.list)
    {
      difficulty = difficulty.toLowerCase();
      final diff:String = difficulty == 'normal' ? '' : difficulty;
      final sufDiff:String = difficulty == 'normal' ? '' : '-$diff';
      final sufJDiff:String = sufDiff + '.json';
      final lowered:String = isExternal ? '' : 'lowercased';
      final formattedFolder:String = Paths.formatToSongPath(swagInput.folder, lowered);
      final formattedSong:String = Paths.formatToSongPath(swagInput.inputNoDiff, lowered);

      final singalPath:String = '$formattedFolder$formattedSong';
      final doublePath:String = '$formattedFolder/$formattedSong';

      var _lastGivenSongPath:String = isExternal ? Paths.getPath('$singalPath.json') : Paths.json('songs/$doublePath');

      if (!_lastGivenSongPath.contains(sufJDiff)) _lastGivenSongPath = _lastGivenSongPath.replace('.json', sufJDiff);

      final swagSong:SwagSong = parseJSON(getFileContent(_lastGivenSongPath), swagInput.inputNoDiff + difficulty);
      final tempChart:SwagChart =
        {
          notes: swagSong.notes,
          events: swagSong.events
        }
      final tempDifficulty:SwagDifficulty =
        {
          song: swagSong.song,
          songId: swagSong.songId,
          displayName: swagSong.displayName,
          bpm: swagSong.bpm,
          needsVoices: swagSong.needsVoices,
          speed: swagSong.speed,
          offset: swagSong.offset,
          stage: swagSong.stage,
          format: swagSong.format,
          options: swagSong.options,
          gameOverData: swagSong.gameOverData,
          characters: swagSong.characters,
          _extraData: swagSong._extraData,
          strumLineIds: swagSong.strumLineIds,
          totalColumns: swagSong.totalColumns
        }
      songTemp.charts.set(difficulty, tempChart);
      songTemp.difficulties.set(difficulty, tempDifficulty);
    }
    return songTemp;
  }

  static function getFileContent(file:String):String
  {
    return #if MODS_ALLOWED FileSystem.exists(file) ? File.getContent(file) : Assets.getText(file); #else Assets.getText(file); #end
  }

  static function objectCheck(rawData:String):SwagSong
  {
    var songJson:SwagSong = cast Json.parse(rawData);
    if (Reflect.hasField(songJson, 'song'))
    {
      var subSong:SwagSong = Reflect.field(songJson, 'song');
      if (subSong != null && Type.typeof(subSong) == TObject) songJson = subSong;
    }
    return songJson;
  }

  public static function getSongMap(swagInput:SwagJsonInput, ?isExternal:Bool = false):SCSongMap
  {
    swagInput.folder = swagInput.inputNoDiff;
    final lowered:String = isExternal ? '' : 'lowercased';
    final formattedFolder:String = Paths.formatToSongPath(swagInput.folder, lowered);
    final formattedSong:String = Paths.formatToSongPath(swagInput.inputNoDiff, lowered);
    final difficulty:String = swagInput.difficulty.replace('-', '');

    final singalPath:String = '$formattedFolder$formattedSong';
    final doublePath:String = '$formattedFolder/$formattedSong';

    final _lastGivenChartsPath:String = isExternal ? Paths.getPath('$singalPath-charts.json') : Paths.json('songs/$doublePath-charts');
    final _lastGivenDifficultiesPath:String = isExternal ? Paths.getPath('$singalPath-difficulties.json') : Paths.json('songs/$doublePath-difficulties');

    _lastPath = _lastGivenChartsPath.replace('-charts.json', '');
    Debug.logInfo(_lastPath);

    final chartsPath:String = getFileContent(_lastGivenChartsPath);
    final difficultiesPath:String = getFileContent(_lastGivenDifficultiesPath);

    final converted:SCSongMap = convertToSongMap(swagInput, isExternal);

    final parsedDifficulties:Dynamic = cast Json.parse(difficultiesPath);
    final parsedCharts:Dynamic = cast Json.parse(chartsPath);

    var parsedMaps:SCSongMap =
      {
        charts: converted?.charts ?? [],
        difficulties: converted?.difficulties ?? []
      }
    if (parsedDifficulties != null && Reflect.hasField(parsedDifficulties, 'difficulties'))
    {
      for (field in Reflect.fields(parsedDifficulties.difficulties))
      {
        parsedMaps.difficulties.set(field, Reflect.field(parsedDifficulties.difficulties, field));
      }
    }
    if (parsedCharts != null && Reflect.hasField(parsedCharts, 'charts'))
    {
      for (field in Reflect.fields(parsedCharts.charts))
      {
        parsedMaps.charts.set(field, Reflect.field(parsedCharts.charts, field));
      }
    }

    return parsedMaps;
  }

  public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
  {
    var songJson:SwagSong = objectCheck(rawData);

    chartProgress.preconvert = songJson;

    generalChecks(songJson);

    if (convertTo != null && convertTo.length > 0)
    {
      var fmt:String = songJson.format;
      if (fmt == null) fmt = songJson.format = 'unknown';

      switch (convertTo)
      {
        case 'psych_v1':
          if (!fmt.startsWith('psych_v1')) // Convert to Psych 1.0 format
          {
            Debug.logInfo('converting chart $nameForError with format $fmt to psych_v1 format...');
            songJson.format = 'psych_v1_convert';
            convert(songJson);
          }
      }
    }

    processSongDataToSCEData(songJson);

    chartProgress.convert = songJson;

    var sectionsData:Array<SwagSection> = songJson.notes;
    if (sectionsData != null)
    {
      for (index => section in sectionsData)
      {
        section.index = index;

        var totalColumns:Int = songJson.totalColumns != null ? songJson.totalColumns : 4;
        if (totalColumns < 1) totalColumns = 4; // just in case

        var ids:Array<Int> = songJson.strumLineIds != null ? songJson.strumLineIds : [0, 1];
        if (ids.length < 1) ids = [0, 1]; // just in case

        for (note in section.sectionNotes)
        {
          if (note[4] == null) note[4] = ids[note[1] >= totalColumns ? 1 : 0];
          else
          {
            if (note[1] < totalColumns && note[4] == ids[1]) note[4] = ids[0];
            if (note[1] >= totalColumns && note[4] == ids[0]) note[4] = ids[1];
          }
        }
      }
    }

    chartProgress.postconvert = songJson;
    return songJson;
  }

  /**
   * Use when loading an unknown song json or when song json is newly created in the chart editor. (new json without data / null json).
   * @param songJson
   */
  public static function defaultIfNotFound(songJson:Dynamic)
  {
    if (songJson.options == null)
    {
      songJson.options =
        {
          disableNoteRGB: false,
          disableNoteCustomRGB: false,
          disableStrumRGB: false,
          disableSplashRGB: false,
          disableHoldCoversRGB: false,
          disableHoldCovers: false,
          disableCaching: false,
          notITG: false,
          usesHUD: false,
          oldBarSystem: false,
          rightScroll: false,
          middleScroll: false,
          blockOpponentMode: false,
          arrowSkin: "",
          strumSkin: "",
          splashSkin: "",
          holdCoverSkin: "",
          opponentNoteStyle: "",
          opponentStrumStyle: "",
          playerNoteStyle: "",
          playerStrumStyle: "",
          vocalsPrefix: "",
          vocalsSuffix: "",
          instrumentalPrefix: "",
          instrumentalSuffix: ""
        }
    }
    if (songJson.gameOverData == null)
    {
      songJson.gameOverData =
        {
          gameOverChar: "bf-dead",
          gameOverSound: "fnf_loss_sfx",
          gameOverLoop: "gameOver",
          gameOverEnd: "gameOverEnd"
        }
    }
    if (songJson.characters == null)
    {
      songJson.characters =
        {
          player: "bf",
          girlfriend: "dad",
          opponent: "gf",
          secondOpponent: "",
        }
    }
  }

  /**
   * Use to transform old data into new data from psych to SCE format to be able to load the Json when not null!
   * @param songJson
   */
  public static function processSongDataToSCEData(songJson:Dynamic)
  {
    function checkToString(e:Dynamic)
    {
      if (e == null) return "";
      final a:String = !Std.isOfType(e, String) ? Std.string(e) : e;
      return a;
    }
    try
    {
      if (songJson.options == null) songJson.options = {}
      if (songJson.gameOverData == null) songJson.gameOverData = {}
      if (songJson.characters == null) songJson.characters = {}

      /*
        Original Event Format
          event = [
            strumTime,
            [
              event,
              param1,
              param2
            ]
          ]
        Compared to SCE
          event = [
            strumTime,
            [
              events,
              [
                amount of values.
              ]
            ]
          ]
       */
      if (songJson.events != null)
      {
        // Old Format
        var oldEvents:Array<Dynamic> = songJson.events;

        // New Format
        var newEvents:Array<Dynamic> = [];

        function checkToString(e:Dynamic)
        {
          if (e == null) return "";
          final a:String = !Std.isOfType(e, String) ? Std.string(e) : e;
          return a;
        }

        // Formatting Events
        for (event in oldEvents)
        {
          for (i in 0...event[1].length)
          {
            // Comp for old event loading
            var params:Array<String> = [];
            if (Std.isOfType(event[1][i][1], Array)) params = event[1][i][1]; // Undefined amount
            else if (Std.isOfType(event[1][i][1], String)) // Default Standard would be 6
            {
              for (j in 1...6)
              {
                params.push(checkToString(event[1][i][j]));
              }
            }

            newEvents.push([event[0], [[event[1][i][0], params]]]);
          }
        }

        // Old is now New.
        songJson.events = newEvents;
      }

      final options:Array<String> = [
        // RGB Bools
        'disableNoteRGB',
        'disableNoteCustomRGB',
        'disableStrumRGB',
        'disableSplashRGB',
        'disableHoldCoversRGB',
        // Bools
        'disableHoldCovers',
        'disableCaching',
        'notITG',
        'usesHUD',
        'oldBarSystem',
        'rightScroll',
        'middleScroll',
        'blockOpponentMode',
        // Strings
        'arrowSkin',
        'strumSkin',
        'splashSkin',
        'holdCoverSkin',
        'opponentNoteStyle',
        'opponentStrumStyle',
        'playerNoteStyle',
        'playerStrumStyle',
        // Music Strings
        'vocalsPrefix',
        'vocalsSuffix',
        'instrumentalPrefix',
        'instrumentalSuffix'
      ];

      final defaultOptionValues:Map<String, Dynamic> = [
        'disableNoteRGB' => false,
        'disableNoteCustomRGB' => false,
        'disableStrumRGB' => false,
        'disableSplashRGB' => false,
        'disableHoldCoversRGB' => false,

        'disableHoldCovers' => false,
        'disableCaching' => false,
        'notITG' => false,
        'usesHUD' => true,
        'oldBarSystem' => true,
        'rightScroll' => false,
        'middleScroll' => false,
        'blockOpponentMode' => false,

        'arrowSkin' => "",
        'strumSkin' => "",
        'splashSkin' => "",
        'holdCoverSkin' => "",
        'opponentNoteSyle' => "",
        'opponentStrumStyle' => "",
        'playerNoteStyle' => "",
        'playerStrumStyle' => "",

        'vocalsPrefix' => "",
        'vocalsSuffix' => "",
        'instrumentalPrefix' => "",
        'instrumentalSuffix' => ""
      ];

      final gameOverData:Array<String> = ['gameOverChar', 'gameOverSound', 'gameOverLoop', 'gameOverEnd'];
      final defaultGameOverValues:Map<String, String> = [
        'gameOverChar' => "bf-dead",
        'gameOverSound' => "fnf_loss_sfx",
        'gameOverLoop' => "gameOver",
        'gameOverEnd' => 'gameOverEnd'
      ];

      final characters:Array<String> = ['player', 'opponent', 'girlfriend', 'secondOpponent'];
      final originalChars:Array<String> = ['player1', 'player2', 'gfVersion', 'player4'];

      final defaultCharacters:Map<String, String> = [
        'player' => "bf",
        'opponent' => "dad",
        'girlfriend' => "gf",
        'secondOpponent' => ""
      ];

      for (index => field in ['options', 'gameOverData', 'characters'])
      {
        final fieldObjects:Array<Array<Array<String>>> = [[options], [gameOverData], [characters, originalChars]];
        final fieldMaps:Array<Map<String, Dynamic>> = [defaultOptionValues, defaultGameOverValues, defaultCharacters];
        final certainField:CertainFields =
          {
            fields: fieldObjects[index][0],
            originalFields: field == 'characters' ? fieldObjects[index][1] : null
          };
        ReflectUtil.searchField(songJson, field, certainField, fieldMaps[index]);
      }

      if (Reflect.hasField(songJson, 'player3'))
      {
        if (songJson.characters.girlfriend != songJson.player3) songJson.characters.girlfriend = songJson.player3;
        Reflect.deleteField(songJson, 'player3');
      }

      if (Reflect.hasField(songJson, 'validScore')) Reflect.deleteField(songJson, 'validScore');

      if (songJson.options.arrowSkin == null || songJson.options.arrowSkin.length < 1) songJson.options.arrowSkin = "noteSkins/NOTE_assets"
        + Note.getNoteSkinPostfix();
      if (songJson.options.strumSkin == null || songJson.options.strumSkin.length < 1) songJson.options.strumSkin = "noteSkins/NOTE_assets"
        + Note.getNoteSkinPostfix();

      if (songJson.song != null && songJson.songId == null) songJson.songId = songJson.song;
      else if (songJson.songId != null && songJson.song == null) songJson.song = songJson.songId;

      if (songJson._extraData == null) songJson._extraData = {};
    }
    catch (e:haxe.Exception)
    {
      Debug.logInfo('FAILED TO LOAD CONVERSION JSON DATA FOR SCE ${e.message + e.stack}');
    }
  }
}
