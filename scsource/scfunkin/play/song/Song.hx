package scfunkin.play.song;

import scfunkin.utils.ReflectUtil;

using scfunkin.play.song.data.SongData;

enum abstract ChartStatus(String) from String to String
{
  var DELETED = 'Deleted';
  var REMOVED = 'Removed';
  var SAVED = 'Saved';
  var OPENED = 'Opened';
}

typedef Chart =
{
  var name:String;
  var chart:Song;
  @:optional var index:Int;
  @:optional var extraData:Dynamic;
  var chartStatus:ChartStatus;
}

class Song
{
  public var songFields(default, set):Array<String> = [];
  public var songData:Map<String, Dynamic> = [
    'song' => null,
    'songId' => null,
    'displayName' => null,
    'notes' => [],
    'events' => [],
    'bpm' => 100.0,
    'speed' => 1.0,
    'offset' => 0.0,
    'format' => null,
    'needsVoices' => false,
    'stage' => null,
    'options' => {},
    'gameOverData' => {},
    'characters' => {},
    '_extraData' => null,
    'strumLineIds' => [],
    'totalColumns' => 4
  ];

  public var excludedFields(default, set):Array<String> = [];
  public var excludedData:Map<String, Dynamic> = new Map<String, Dynamic>();

  function set_excludedFields(value:Array<String>):Array<String>
  {
    Debug.logInfo(value);
    excludedFields = value;
    for (exField in excludedFields)
    {
      if (!Reflect.hasField(currentSong, exField)) continue;
      setExcludedData(exField, Reflect.field(currentSong, exField));
    }
    return value;
  }

  function set_songFields(value:Array<String>):Array<String>
  {
    excludedFields = [for (field in value) if (!songData.exists(field)) field];
    songFields = [for (field in value) if (songData.exists(field)) field];
    for (field in songFields)
    {
      if (!Reflect.hasField(currentSong, field)) continue;
      setSongData(field, Reflect.field(currentSong, field));
    }
    Debug.logInfo(songFields);
    return songFields;
  }

  public var currentSong(default, set):SwagSong = null;
  public var currentDifficulty:SwagDifficulty =
    {
      song: "",
      songId: "",
      displayName: "",
      bpm: 100.0,
      needsVoices: false,
      speed: 1.0,
      offset: 0.0,
      stage: "",
      format: "",
      options: {},
      gameOverData: {},
      characters: {},
      _extraData: null,
      strumLineIds: [],
      totalColumns: 4
    }
  public var currentChart:SwagChart =
    {
      notes: [],
      events: []
    }

  function set_currentSong(value:SwagSong):SwagSong
  {
    currentSong = value;
    set_songFields([for (songField in Reflect.fields(currentSong)) Std.string(songField)]);
    return currentSong;
  }

  public function new(swagSong:SwagSong)
  {
    this.currentSong = swagSong;
    loadFromCurrentSong();
  }

  public function chartLoadFromCurrentSong(swag:SwagSong)
  {
    currentChart =
      {
        notes: swag.notes,
        events: swag.events
      }
    currentDifficulty =
      {
        song: swag.song,
        songId: swag.songId,
        displayName: swag.displayName,
        bpm: swag.bpm,
        needsVoices: swag.needsVoices,
        speed: swag.speed,
        offset: swag.offset,
        stage: swag.stage,
        format: swag.format,
        options: swag.options,
        gameOverData: swag.gameOverData,
        characters: swag.characters,
        _extraData: swag._extraData,
        strumLineIds: swag.strumLineIds,
        totalColumns: swag.totalColumns
      }
  }

  public function loadFromCurrentSong():Song
  {
    for (songField in songFields)
      setSongData(songField, Reflect.getProperty(currentSong, songField));
    chartLoadFromCurrentSong(currentSong);
    return this;
  }

  public function saveToCurrentSong():SwagSong
  {
    for (songField in songFields)
      Reflect.setProperty(currentSong, songField, getSongData(songField));
    chartLoadFromCurrentSong(currentSong);
    return currentSong;
  }

  public function getSongData(field:String):Dynamic
    return songData.get(field);

  public function setSongData(field:String, value:Dynamic)
    songData.set(field, value);

  public function getExcludedData(field:String):Dynamic
    return excludedData.get(field);

  public function setExcludedData(field:String, value:Dynamic)
    excludedData.set(field, value);
}
