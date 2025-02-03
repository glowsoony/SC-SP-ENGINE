package scfunkin.states.editors.content.charting;

import flixel.util.FlxDestroyUtil;
import scfunkin.objects.note.Note;
import scfunkin.shaders.RGBPalette;

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

typedef ChartEventJson =
{
  var ?animations:EventAnimations;
  var image:String;
  var name:String;
  var ?displayParamNames:Array<String>;
  var ?scale:Null<Float>;
}

class CombinedMetaNote extends MetaNote
{
  public function new(noteData:Int, data:Array<Dynamic>)
  {
    super(0, noteData, data);
  }

  public override function reloadNote(text:String = '', post:String = '')
  {
    super.reloadNote(text, post);
    if (noteData < 0) loadGraphic(Paths.image('editors/chartEditor/events/eventIcon'));
  }

  override public function changeNoteData(v:Int)
  {
    this.chartNoteData = v; // despite being so arbitrary its sadly needed to fix a bug on moving notes
    this.songData[1] = v;
    this.noteData = v % ChartingState.GRID_COLUMNS_PER_PLAYER;
    if (v >= 0)
    {
      this.texture = this.noteSkin;

      loadNoteAnims(containsPixelTexture);

      if (Note.globalRgbShaders.contains(rgbShader.parent)) // Is using a default shader
        rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));

      setShaderEnabled(PlayState.SONG.options.disableNoteRGB ? false : true);

      animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'Scroll');
      updateHitbox();
      if (width > height) setGraphicSize(ChartingState.GRID_SIZE);
      else
        setGraphicSize(0, ChartingState.GRID_SIZE);

      updateHitbox();
    }
    else
    {
      if (rgbShader != null) setShaderEnabled(false);
      loadGraphic(Paths.image('editors/chartEditor/events/eventIcon'));
      if (width > height) setGraphicSize(ChartingState.GRID_SIZE);
      else
        setGraphicSize(0, ChartingState.GRID_SIZE);
      updateHitbox();
    }
  }
}

class MetaNote extends Note
{
  public static var noteTypeTexts:Map<Int, FlxText> = [];

  public var isEvent:Bool = false;
  public var songData:Array<Dynamic>;
  public var sustainSprite:EditorSustain;
  public var endSprite:Note;
  public var chartY:Float = 0;
  public var chartNoteData:Int = 0;
  public var oldXPos:Float = 0;

  public function new(time:Float, nData:Int, songData:Array<Dynamic>)
  {
    super(
      {
        strumTime: time,
        noteData: nData,
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
    this.chartNoteData = nData;
    this.realNoteData = songData[1];
    this.setStrumLineID(songData[4]);
  }

  public override function reloadNote(tex:String = '', postfix:String = '')
  {
    super.reloadNote(tex, postfix);
    if (sustainSprite != null) sustainSprite.reloadNote(tex, postfix);
  }

  public function changeNoteData(v:Int)
  {
    this.chartNoteData = v; // despite being so arbitrary its sadly needed to fix a bug on moving notes
    this.songData[1] = v;
    this.noteData = v % ChartingState.GRID_COLUMNS_PER_PLAYER;
    this.realNoteData = v;
    this.setStrumLineID((v < ChartingState.GRID_COLUMNS_PER_PLAYER) ? PlayState.SONG.strumLineIds[0] : PlayState.SONG.strumLineIds[1]);

    loadNoteAnims(containsPixelTexture);

    if (Note.globalRgbShaders.contains(rgbShader.parent)) // Is using a default shader
      rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));

    setShaderEnabled((PlayState.SONG.options.disableNoteRGB || v <= -1) ? false : true);

    animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'Scroll');
    updateHitbox();
    if (width > height) setGraphicSize(ChartingState.GRID_SIZE);
    else
      setGraphicSize(0, ChartingState.GRID_SIZE);

    updateHitbox();
    if (sustainSprite != null) sustainSprite.changeNoteData(this.noteData, this.noteSkin);
  }

  public function setStrumLineID(v:Int)
  {
    this.actualStrumLineID = songData[1] < ChartingState.GRID_COLUMNS_PER_PLAYER ? 0 : 1;
    this.songData[4] = v;
    this.strumLineID = v;
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

    if (sustainLength > 0)
    {
      if (sustainSprite == null) sustainSprite = new EditorSustain(noteData, noteSkin);
      sustainSprite.scrollFactor.x = 0;
      sustainSprite.setGraphicSize(ChartingState.GRID_SIZE * 0.5, ChartingState.GRID_SIZE * 0.5);
      sustainSprite.sustainHeight = _lastEditorVisualSusLength;
      sustainSprite.updateHitbox();
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
      sustainSprite.setColorTransform(colorTransform.redMultiplier, sustainSprite.colorTransform.blueMultiplier, colorTransform.redMultiplier);
      sustainSprite.setGraphicSize(ChartingState.GRID_SIZE * 0.5, ChartingState.GRID_SIZE * 0.5);
      sustainSprite.updateHitbox();
      sustainSprite.x = this.x + (this.width - sustainSprite.width) / 2;
      sustainSprite.y = this.y + this.height / 2;
      sustainSprite.alpha = this.alpha;
      sustainSprite.draw();
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

  public function setShaderEnabled(isEnabled:Bool)
  {
    rgbShader.enabled = isEnabled;
    if (_lastEditorVisualSusLength > 0)
    {
      if (sustainSprite != null) sustainSprite.setShaderEnabled(isEnabled);
    }
  }

  override function destroy()
  {
    sustainSprite = FlxDestroyUtil.destroy(sustainSprite);
    super.destroy();
  }
}

class EditorSustain extends Note
{
  public var sustainTile:EditorSustainHold;
  public var sustainHeight(default, set):Float = 0;

  function set_sustainHeight(value:Float):Float
  {
    sustainHeight = value;
    sustainTile.setGraphicSize(ChartingState.GRID_SIZE * 0.5);
    sustainTile.scale.y = sustainHeight;
    return sustainHeight;
  }

  public function setShaderEnabled(enabled:Bool)
  {
    rgbShader.enabled = sustainTile.rgbShader.enabled = enabled;
  }

  public function new(nData:Int, skin:String)
  {
    sustainTile = new EditorSustainHold(nData, skin, sustainHeight);
    sustainTile.scrollFactor.x = 0;
    sustainTile.flipY = false;

    super(
      {
        strumTime: 0,
        noteData: nData,
        isSustainNote: true,
        noteSkin: skin
      });

    animation.play(Note.colArray[noteData] + 'holdend');
    setGraphicSize(ChartingState.GRID_SIZE * 0.5, ChartingState.GRID_SIZE * 0.5);
    updateHitbox();
    flipY = false;
  }

  override function update(elapsed:Float)
  {
    sustainTile.update(elapsed);
    super.update(elapsed);
  }

  override function draw()
  {
    if (!visible) return;

    sustainTile.setColorTransform(colorTransform.redMultiplier, colorTransform.blueMultiplier, colorTransform.redMultiplier);
    sustainTile.setGraphicSize(ChartingState.GRID_SIZE * 0.5);
    sustainTile.scale.y = sustainHeight;
    sustainTile.updateHitbox();
    sustainTile.setPosition(this.x, this.y - sustainHeight);
    sustainTile.alpha = this.alpha;
    sustainTile.draw();

    y += sustainHeight;
    super.draw();
    y -= sustainHeight;
  }

  public function reloadSustainTile()
  {
    sustainTile.antialiasing = this.antialiasing;
    sustainTile.animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'hold');
    sustainTile.clipRect = new flixel.math.FlxRect(0, 1, sustainTile.frameWidth, 1);
  }

  public function changeNoteData(v:Int, skin:String)
  {
    this.noteData = v;
    this.texture = skin;

    loadNoteAnims(containsPixelTexture);

    if (Note.globalRgbShaders.contains(rgbShader.parent)) // Is using a default shader
      rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));

    setShaderEnabled((PlayState.SONG.options.disableNoteRGB || v <= -1) ? false : true);

    sustainTile.changeNoteData(noteData, texture);
    reloadSustainTile();
    animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'holdend');
  }

  public override function reloadNote(tex:String = '', postfix:String = '')
  {
    super.reloadNote(tex, postfix);
    sustainTile.reloadNote(tex, postfix);
    reloadSustainTile();
  }
}

class EditorSustainHold extends Note
{
  public function new(nData:Int, skin:String, height:Float)
  {
    super(
      {
        strumTime: 0,
        noteData: nData,
        isSustainNote: true,
        noteSkin: skin
      });
    setGraphicSize(ChartingState.GRID_SIZE * 0.5);
    scale.y = height;
  }

  public function changeNoteData(v:Int, skin:String)
  {
    this.noteData = v;
    this.texture = skin;

    loadNoteAnims(containsPixelTexture);

    if (Note.globalRgbShaders.contains(rgbShader.parent)) // Is using a default shader
      rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));

    rgbShader.enabled = ((PlayState.SONG.options.disableNoteRGB || v <= -1) ? false : true);

    animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'hold');
  }
}

class EventMetaNote extends MetaNote
{
  public var eventText:FlxText;
  public var eventDescription:String = "";
  public var eventJson:ChartEventJson = null;

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

  public function findEventJson(event:String):ChartEventJson
  {
    if (Paths.fileExists('data/chart/events/$event.json', TEXT))
    {
      final rawFile:String = Paths.getTextFromFile('data/chart/events/$event.json');
      if (rawFile != null && rawFile.length > 0)
      {
        final rawJson = tjson.TJSON.parse(rawFile);
        if (rawJson != null)
        {
          final newEventJson:ChartEventJson =
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

  public function loadFromJson(event:ChartEventJson = null)
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
