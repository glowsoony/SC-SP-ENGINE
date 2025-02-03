package scfunkin.play.song;

import tjson.TJSON as Json;
import lime.utils.Assets;
import scfunkin.objects.note.Note;

using scfunkin.play.song.data.SongData;

class Song
{
  public var song:String;
  public var songId:String;
  public var displayName:String;

  public var notes:Array<SwagSection>;
  public var events:Array<Dynamic>;
  public var bpm:Float = 100.0;
  public var speed:Float = 1.0;
  public var offset:Float = 0.0;
  public var needsVoices:Bool = true;

  public var stage:String = null;
  public var format:String = '';

  public var options:OptionsData;
  public var gameOverData:GameOverData;
  public var characters:CharacterData;

  public var extraData:Dynamic;

  public var totalColumns:Int = 4;

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

  public static var loadedSongName:String;
  public static var formattedSongName:String;
  public static var displayedName:String;
  public static var formattedDisplayedName:String;

  public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
  {
    if (folder == null) folder = jsonInput;
    PlayState.SONG = getChart(jsonInput, folder);
    loadedSongName = folder;
    chartPath = _lastPath.replace('/', '\\');
    formattedSongName = Paths.formatToSongPath(PlayState.SONG.songId);
    Debug.logInfo(_lastPath);
    Debug.logInfo(chartPath);
    StageData.loadDirectory(PlayState.SONG);
    displayedName = PlayState.SONG.displayName != null ? PlayState.SONG.displayName : folder;
    formattedDisplayedName = PlayState.SONG.displayName != null ? Paths.formatToSongPath(displayedName, '') : Paths.formatToSongPath(PlayState.SONG.songId, '');
    return PlayState.SONG;
  }

  static var _lastPath:String;

  public static function getChart(jsonInput:String, ?folder:String, ?isExternal:Bool = false):SwagSong
  {
    if (folder == null) folder = jsonInput;
    var rawData:String = null;

    var formattedFolder:String = Paths.formatToSongPath(folder, isExternal ? '' : 'lowercased');
    var formattedSong:String = Paths.formatToSongPath(jsonInput, isExternal ? '' : 'lowercased');
    _lastPath = isExternal ? Paths.getPath('$formattedFolder$formattedSong.json') : Paths.json('songs/$formattedFolder/$formattedSong');
    Debug.logInfo('$_lastPath');
    #if MODS_ALLOWED
    if (FileSystem.exists(_lastPath)) rawData = File.getContent(_lastPath);
    else
    #end
    rawData = Assets.getText(_lastPath);
    return rawData != null ? parseJSON(rawData, jsonInput) : null;
  }

  public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
  {
    var songJson:SwagSong = cast Json.parse(rawData);
    if (Reflect.hasField(songJson, 'song'))
    {
      var subSong:SwagSong = Reflect.field(songJson, 'song');
      if (subSong != null && Type.typeof(subSong) == TObject) songJson = subSong;
    }

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

      for (field in options)
      {
        if (Reflect.hasField(songJson, field))
        {
          if (!Reflect.hasField(songJson.options, field)) Reflect.setProperty(songJson.options, field, Reflect.getProperty(songJson, field));
          Reflect.deleteField(songJson, field);
        }
        else
        {
          if (!Reflect.hasField(songJson.options, field)) Reflect.setProperty(songJson.options, field, defaultOptionValues.get(field));
        }
      }

      final gameOverData:Array<String> = ['gameOverChar', 'gameOverSound', 'gameOverLoop', 'gameOverEnd'];
      final defaultGameOverValues:Map<String, String> = [
        'gameOverChar' => "bf-dead",
        'gameOverSound' => "fnf_loss_sfx",
        'gameOverLoop' => "gameOver",
        'gameOverEnd' => 'gameOverEnd'
      ];

      for (field in gameOverData)
      {
        if (Reflect.hasField(songJson, field))
        {
          if (!Reflect.hasField(songJson.options, field)) Reflect.setProperty(songJson.gameOverData, field, Reflect.getProperty(songJson, field));
          Reflect.deleteField(songJson, field);
        }
        else
        {
          if (Reflect.hasField(songJson, field)) Reflect.setProperty(songJson.gameOverData, field, defaultGameOverValues.get(field));
        }
      }

      final characters:Array<String> = ['player', 'opponent', 'girlfriend', 'secondOpponent'];
      final originalChar:Array<String> = ['player1', 'player2', 'gfVersion', 'player4'];

      final defaultCharacters:Map<String, String> = [
        'player' => "bf",
        'opponent' => "dad",
        'girlfriend' => "gf",
        'secondOpponent' => ""
      ];

      for (field in 0...characters.length)
      {
        if (Reflect.hasField(songJson, originalChar[field]))
        {
          if (!Reflect.hasField(songJson.characters,
            characters[field])) Reflect.setProperty(songJson.characters, characters[field], Reflect.getProperty(songJson, originalChar[field]));
          Reflect.deleteField(songJson, originalChar[field]);
        }
        else
        {
          if (!Reflect.hasField(songJson.characters,
            characters[field])) Reflect.setProperty(songJson.characters, characters[field], defaultCharacters.get(characters[field]));
        }
      }

      if (songJson.characters.girlfriend != songJson.player3 && songJson.player3 != null)
      {
        songJson.characters.girlfriend = songJson.player3;
        if (Reflect.hasField(songJson, 'player3')) Reflect.deleteField(songJson, 'player3');
      }

      if (songJson.options.arrowSkin == null || songJson.options.arrowSkin.length < 1) songJson.options.arrowSkin = "noteSkins/NOTE_assets"
        + Note.getNoteSkinPostfix();
      if (songJson.options.strumSkin == null || songJson.options.strumSkin.length < 1) songJson.options.strumSkin = "noteSkins/NOTE_assets"
        + Note.getNoteSkinPostfix();

      if (songJson.song != null && songJson.songId == null) songJson.songId = songJson.song;
      else if (songJson.songId != null && songJson.song == null) songJson.song = songJson.songId;
    }
    catch (e:haxe.Exception)
    {
      Debug.logInfo('FAILED TO LOAD CONVERSION JSON DATA FOR SCE ${e.message + e.stack}');
    }
  }
}
