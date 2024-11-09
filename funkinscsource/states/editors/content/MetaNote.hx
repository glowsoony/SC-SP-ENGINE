package states.editors.content;

import objects.note.Note;
import shaders.RGBPalette;
import flixel.util.FlxDestroyUtil;

enum abstract EventAnimAction(String) to String from String
{
  var IDLE = 'Idle';
  var SELECTED = 'Selected';
  var REMOVED = 'Removed';
}

typedef EventAnimationData =
{
  var name:String;
  var ?loop:Bool;
  var ?fps:Int;
  var ?indices:Array<Int>;
}

typedef EventAnimations =
{
  var idle_anim:EventAnimationData;
  var ?selected_anim:EventAnimationData;
  var ?removed_anim:EventAnimationData;
}

typedef EventJson =
{
  var ?animations:EventAnimations;
  var image:String;
  var name:String;
  var ?displayParamNames:Array<String>;
  var ?scale:Null<Float>;
}

class MetaNote extends Note
{
  public static var noteTypeTexts:Map<Int, FlxText> = [];

  public var isEvent:Bool = false;
  public var songData:Array<Dynamic>;
  public var sustainSprite:Note;
  public var endSprite:Note;
  public var chartY:Float = 0;
  public var chartNoteData:Int = 0;

  public function new(time:Float, data:Int, songData:Array<Dynamic>)
  {
    super(
      {
        strumTime: time,
        noteData: data,
        isSustainNote: false,
        noteSkin: PlayState.SONG?.options?.arrowSkin,
        prevNote: null,
        createdFrom: null,
        scrollSpeed: 1.0,
        parentStrumline: null,
        inEditor: true
      });
    this.songData = songData;
    this.strumTime = time;
    this.chartNoteData = data;

    updateSustain();
    updateSustainEnd();
  }

  public function updateSustain(setData:Bool = true)
  {
    if (_lastEditorVisualSusLength <= 0) return;
    if (sustainSprite != null)
    {
      if (setData)
      {
        sustainSprite.startNoteData(
          {
            strumTime: this.strumTime,
            noteData: this.noteData,
            isSustainNote: true,
            noteSkin: this.noteSkin,
            prevNote: null,
            createdFrom: null,
            scrollSpeed: 1.0,
            parentStrumline: null,
            inEditor: true
          });
      }
      sustainSprite.rgbShader = this.rgbShader;
      sustainSprite.scrollFactor.x = 0;
      sustainSprite.animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'hold');
      sustainSprite.setGraphicSize(ChartingState.GRID_SIZE * 0.5, _lastEditorVisualSusLength);
      sustainSprite.updateHitbox();
    }
  }

  public function updateSustainEnd(setData:Bool = true)
  {
    if (_lastEditorVisualSusLength <= 0) return;
    if (endSprite != null)
    {
      if (setData)
      {
        endSprite.startNoteData(
          {
            strumTime: this.strumTime,
            noteData: this.noteData,
            isSustainNote: true,
            noteSkin: this.noteSkin,
            prevNote: null,
            createdFrom: null,
            scrollSpeed: 1.0,
            parentStrumline: null,
            inEditor: true
          });
      }
      endSprite.scrollFactor.x = 0;
      endSprite.animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'holdend');
      endSprite.setGraphicSize(ChartingState.GRID_SIZE * 0.5, ChartingState.GRID_SIZE * 0.5);
      endSprite.updateHitbox();
    }
  }

  public function changeNoteData(v:Int)
  {
    this.chartNoteData = v; // despite being so arbitrary its sadly needed to fix a bug on moving notes
    this.songData[1] = v;
    this.noteData = v % ChartingState.GRID_COLUMNS_PER_PLAYER;
    this.mustPress = (v < ChartingState.GRID_COLUMNS_PER_PLAYER);

    loadNoteAnims(containsPixelTexture);

    if (Note.globalRgbShaders.contains(rgbShader.parent)) // Is using a default shader
      rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));

    animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'Scroll');
    updateHitbox();
    if (width > height) setGraphicSize(ChartingState.GRID_SIZE);
    else
      setGraphicSize(0, ChartingState.GRID_SIZE);

    updateHitbox();
    updateSustain();
    updateSustainEnd();
  }

  public function setStrumTime(v:Float)
  {
    this.songData[0] = v;
    this.strumTime = v;
  }

  var _lastZoom:Float = -1;
  var _lastEditorVisualSusLength:Float = 0;

  public function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1)
  {
    _lastZoom = zoom;
    _lastEditorVisualSusLength = Math.max(ChartingState.GRID_SIZE / 4,
      (Math.round((v * ChartingState.GRID_SIZE + ChartingState.GRID_SIZE) / stepCrochet) * zoom) - ChartingState.GRID_SIZE / 2);
    v = Math.round(v / (stepCrochet / 2)) * (stepCrochet / 2);
    songData[2] = sustainLength = Math.max(Math.min(v, stepCrochet * 128), 0);

    if (_lastEditorVisualSusLength > 0)
    {
      if (sustainSprite == null)
      {
        sustainSprite = new Note(
          {
            strumTime: this.strumTime,
            noteData: this.noteData,
            isSustainNote: true,
            noteSkin: this.noteSkin,
            prevNote: null,
            createdFrom: null,
            scrollSpeed: 1.0,
            parentStrumline: null,
            inEditor: true
          });
      }
      if (endSprite == null)
      {
        endSprite = new Note(
          {
            strumTime: this.strumTime,
            noteData: this.noteData,
            isSustainNote: true,
            noteSkin: this.noteSkin,
            prevNote: null,
            createdFrom: null,
            scrollSpeed: 1.0,
            parentStrumline: null,
            inEditor: true
          });
      }
      updateSustain(false);
      updateSustainEnd(false);
    }
  }

  public var hasSustain(get, never):Bool;

  function get_hasSustain()
    return (!isEvent && sustainLength > 0);

  public function updateSustainToZoom(stepCrochet:Float, zoom:Float = 1)
  {
    if (_lastZoom == zoom) return;
    setSustainLength(sustainLength, stepCrochet, zoom);
  }

  public function updateSustainToStepCrochet(stepCrochet:Float)
  {
    if (_lastZoom < 0) return;
    setSustainLength(sustainLength, stepCrochet, _lastZoom);
  }

  var _noteTypeText:FlxText;

  public function findNoteTypeText(num:Int)
  {
    var txt:FlxText = null;
    if (num != 0)
    {
      if (!noteTypeTexts.exists(num))
      {
        txt = new FlxText(0, 0, ChartingState.GRID_SIZE, (num > 0) ? Std.string(num) : '?', 16);
        txt.autoSize = false;
        txt.alignment = CENTER;
        txt.borderStyle = SHADOW;
        txt.shadowOffset.set(2, 2);
        txt.borderColor = FlxColor.BLACK;
        txt.scrollFactor.x = 0;
        noteTypeTexts.set(num, txt);
      }
      else
        txt = noteTypeTexts.get(num);
    }
    return (_noteTypeText = txt);
  }

  override function draw()
  {
    if (sustainSprite != null && sustainSprite.exists && sustainSprite.visible && sustainLength > 0)
    {
      sustainSprite.x = this.x + this.width / 2 - sustainSprite.width / 2;
      sustainSprite.y = this.y + this.height / 2;
      sustainSprite.alpha = this.alpha;
      sustainSprite.draw();
    }
    if (endSprite != null && endSprite.exists && endSprite.visible && sustainLength > 0)
    {
      endSprite.x = this.x + this.width / 2 - endSprite.width / 2;
      endSprite.y = grabNoteY(endSprite, sustainSprite); // 4 pixels LOL
      endSprite.alpha = this.alpha;
      endSprite.draw();
    }
    super.draw();

    if (_noteTypeText != null && _noteTypeText.exists && _noteTypeText.visible)
    {
      _noteTypeText.x = this.x + this.width / 2 - _noteTypeText.width / 2;
      _noteTypeText.y = this.y + this.height / 2 - _noteTypeText.height / 2;
      _noteTypeText.alpha = this.alpha;
      _noteTypeText.draw();
    }
  }

  public function reloadToNewTexture(texture:String)
  {
    reloadNote(texture);
    if (width > height) setGraphicSize(ChartingState.GRID_SIZE);
    else
      setGraphicSize(0, ChartingState.GRID_SIZE);

    updateHitbox();

    if (_lastEditorVisualSusLength > 0)
    {
      if (sustainSprite != null)
      {
        sustainSprite.reloadNote(texture);
        updateSustain();
      }
      if (endSprite != null)
      {
        endSprite.reloadNote(texture);
        updateSustainEnd();
      }
    }
  }

  public function setShaderEnabled(isEnabled:Bool)
  {
    rgbShader.enabled = isEnabled;
    if (_lastEditorVisualSusLength > 0)
    {
      if (endSprite != null)
      {
        endSprite.rgbShader.enabled = isEnabled;
        updateSustainEnd();
      }
      if (sustainSprite != null)
      {
        sustainSprite.rgbShader.enabled = isEnabled;
        updateSustain();
      }
    }
  }

  public function grabNoteY(end:Note, sus:Note):Float
  {
    var diff:Float = (sus.y + sus.height) - 5;
    if (end.y > diff) diff = (sus.y + (sus.height - end.y) - 5);
    return diff;
  }

  override function destroy()
  {
    sustainSprite = FlxDestroyUtil.destroy(sustainSprite);
    endSprite = FlxDestroyUtil.destroy(endSprite);
    super.destroy();
  }
}

class EventMetaNote extends MetaNote
{
  public var eventText:FlxText;
  public var eventDescription:String = "";
  public var eventJson:EventJson = null;

  public function setImage(value:String):String
  {
    if (value == null)
    {
      loadGraphic(Paths.image('editors/chartEditor/events/eventIcon'));
      value = 'eventIcon';
    }
    else
    {
      loadGraphic(Paths.image('editors/chartEditor/events/$value'));
      if (graphic == null)
      {
        loadGraphic(Paths.image('editors/chartEditor/events/eventIcon'));
        value = 'eventIcon';
      }
    }
    setGraphicSize(ChartingState.GRID_SIZE);
    updateHitbox();
    return value;
  }

  function checkToString(e:Dynamic)
  {
    if (e == null) return "";
    final a:String = !Std.isOfType(e, String) ? Std.string(e) : e;
    return a;
  }

  public function new(time:Float, eventData:Dynamic)
  {
    super(time, -1, eventData);
    this.isEvent = true;
    events = eventData[1];
    if (events.length > 1)
    {
      var eventNames:Array<String> = [for (event in events) event[0]];
      loadFromJson(findEventJson(checkToString(eventNames[0])));
    }
    else if (events.length == 1)
    {
      var event = events[0];
      loadFromJson(findEventJson(checkToString(event[0])));
    }
    else
    {
      isAnimated = false;
      setImage(null);
    }

    eventText = new FlxText(0, 0, 400, '', 12);
    eventText.setFormat(Paths.font('vcr.ttf'), 12, FlxColor.WHITE, RIGHT);
    eventText.scrollFactor.x = 0;
    updateEventText();
  }

  override function draw()
  {
    if (eventText != null && eventText.exists && eventText.visible)
    {
      eventText.y = this.y + this.height / 2 - eventText.height / 2;
      eventText.alpha = this.alpha;
      eventText.draw();
    }
    super.draw();
  }

  override function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1) {}

  public var events:Array<Array<Dynamic>>;

  public function updateEventText()
  {
    var myTime:Float = Math.floor(this.strumTime);
    if (events.length == 1)
    {
      var event = events[0];
      var toBuildArray:Array<String> = [];
      for (i in 0...6)
        toBuildArray.push(checkToString(event[1][i]));
      eventText.text = buildEventText(checkToString(event[0]), toBuildArray);
      loadFromJson(findEventJson(checkToString(event[0])));
    }
    else if (events.length > 1)
    {
      var eventNames:Array<String> = [for (event in events) event[0]];
      eventText.text = '${events.length} Events ($myTime ms):\n${eventNames.join(', ')}';
      loadFromJson(findEventJson(checkToString(eventNames[0])));
    }
    else
      eventText.text = 'ERROR FAILSAFE';
  }

  public function buildEventText(event:String, params:Array<String>):String
  {
    final finalEventText:String = 'Event: $event';
    var addedText:String = '';
    for (i in 0...params.length - 1)
    {
      if (params[i] != null && params[i].length > 0) addedText += '\nValue ' + Std.string(i + 1) + ': ' + params[i];
      else
        addedText += '';
    }
    if (!addedText.contains('Value')) addedText = '';
    final valuesText:String = addedText;
    return finalEventText + valuesText;
  }

  public function findEventJson(event:String):EventJson
  {
    if (Paths.fileExists('data/chart/events/$event.json', TEXT))
    {
      final rawFile:String = Paths.getTextFromFile('data/chart/events/$event.json');
      if (rawFile != null && rawFile.length > 0)
      {
        final rawJson = tjson.TJSON.parse(rawFile);
        if (rawJson != null)
        {
          final newEventJson:EventJson =
            {
              animations: null,
              image: null,
              name: null,
              displayParamNames: null,
              scale: null
            };
          final fields:Array<String> = ['animations', 'image', 'name', 'displayParamNames', 'scale'];
          for (field in fields)
          {
            if (Reflect.hasField(rawJson, field)) Reflect.setProperty(newEventJson, field, Reflect.getProperty(rawJson, field));
          }
          eventJson = newEventJson;
          return eventJson;
        }
      }
    }
    setImage(null);
    return null;
  }

  public var isAnimated:Bool = false;

  public var animationsToPush:Array<{action:EventAnimAction, anim:String}> = null;

  public function onEventAction(act:EventAnimAction = null)
  {
    if (!isAnimated || animationsToPush.length < 1) return;

    for (action in animationsToPush)
      if (action.action == act && hasAnimation(action.anim.toLowerCase())) playAnim(action.anim.toLowerCase());
  }

  public function loadFromJson(event:EventJson = null)
  {
    if (event == null) return;
    final imageFile:String = 'editors/chartEditor/events/' + event.image;
    loadFrameAtlas(Paths.checkForImage(imageFile), imageFile, imageFile);
    isAnimated = (frames != null);

    if (!isAnimated) setImage(event.image);
    else
    {
      function buildAnimation(action:String, anim:EventAnimationData)
      {
        final animName:String = '' + anim.name;
        final animFps:Int = anim.fps;
        final animLoop:Bool = !!anim.loop; // Bruh
        final animIndices:Array<Int> = anim.indices;
        if (animIndices != null && animIndices.length > 0) animation.addByIndices(action, animName, animIndices, "", animFps);
        else
          animation.addByPrefix(action, animName, animFps, animLoop);
      }

      setGraphicSize(ChartingState.GRID_SIZE * (event.scale != null && event.scale != 1 ? event.scale : 1));
      updateHitbox();

      if (eventJson.animations != null)
      {
        final idleAnim:EventAnimationData = eventJson.animations.idle_anim;
        final selectedAnim:EventAnimationData = eventJson.animations.selected_anim;
        final removedAnim:EventAnimationData = eventJson.animations.removed_anim;

        if (idleAnim != null)
        {
          buildAnimation('Idle', idleAnim);
          animationsToPush.push({action: IDLE, anim: 'Idle'});
        }

        if (selectedAnim != null)
        {
          buildAnimation('Selected', selectedAnim);
          animationsToPush.push({action: SELECTED, anim: 'Selected'});
        }

        if (removedAnim != null)
        {
          buildAnimation('Removed', removedAnim);
          animationsToPush.push({action: REMOVED, anim: 'Removed'});
        }

        onEventAction(IDLE);
      }
      else
      {
        setImage(event.image);
        isAnimated = false;
      }
    }
  }

  override function destroy()
  {
    eventText = FlxDestroyUtil.destroy(eventText);
    super.destroy();
  }
}
