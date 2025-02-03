package scfunkin.states.substates.options;

import flixel.FlxSubState;
import scfunkin.states.editors.content.Prompt;
import scfunkin.states.editors.content.*;
import scfunkin.states.substates.options.ui.*;
import scfunkin.utils.GenericUtil;

enum abstract BuildOption(String) to String from String
{
  var TOGGLE = "Toggle";
  var ARRAY = "Array";
  var SHIFT = "Shift";
  var DROPDOWN = "DropDown";
  var KEYBIND = "KeyBind";
  var SLIDER = "Slider";
  var NUMBER = "Number";
}

class OptionCategoryHeader extends FlxSpriteGroup
{
  public var categorys:Array<String> = [];
  public var curSelectedCata:Int = 0;

  public var currentCata:{cata:String, cataNum:Int};

  public var background:FlxSprite;
  public var category:FlxText;

  public var leftArrow:UIArrow;
  public var rightArrow:UIArrow;

  public function new(x:Float, y:Float, cates:Array<String>)
  {
    this.categorys = cates;
    super(x, y);
    background = new FlxSprite(20, 40).makeGraphic(1240, 70, FlxColor.BLACK);
    background.alpha = 0.5;
    add(background);
    category = new FlxText(background.x + 460, 40, background.width / 2, "", 50);
    add(category);
    leftArrow = new UIArrow(category.x - 75, category.y - 13);
    GenericUtil.transformSpriteColor(leftArrow.arrow, [0, 0, 0, 1, 0, 0, 0]);
    leftArrow.flipX = true;
    add(leftArrow);

    rightArrow = new UIArrow(0, category.y - 13);
    GenericUtil.transformSpriteColor(rightArrow.arrow, [0, 0, 0, 1, 0, 0, 0]);
    add(rightArrow);

    rightArrow.onPressed = function() {
      GenericUtil.transformSpriteColor(rightArrow.arrow, [1, 1, 1, 1, 255, 255, 0]);
    }
    leftArrow.onPressed = function() {
      GenericUtil.transformSpriteColor(leftArrow.arrow, [1, 1, 1, 1, 255, 255, 0]);
    }

    background.antialiasing = category.antialiasing = ClientPrefs.data.antialiasing;
    onChangeCata();
  }

  public var yellowTimerL:FlxTimer;
  public var yellowTimerR:FlxTimer;

  public function onChangeCata(change:Int = 0)
  {
    curSelectedCata = FlxMath.wrap(curSelectedCata + change, 0, categorys.length - 1);
    category.text = categorys[curSelectedCata];
    currentCata =
      {
        cata: category.text,
        cataNum: curSelectedCata
      }
    switch (categorys[curSelectedCata])
    {
      case 'Gameplay':
        rightArrow.x = category.x + 270;
      case 'Misc':
        rightArrow.x = category.x + 100;
      case 'Appearance':
        rightArrow.x = category.x + 330;
      case 'Visuals':
        rightArrow.x = category.x + 190;
    }
    FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
    callWhiteTimerL();
    callWhiteTimerR();
  }

  public function callWhiteTimerL():Void
  {
    if (leftArrow.arrow.colorTransform.blueOffset == 255) return;
    yellowTimerL = new FlxTimer().start(0.06, function(tmr) {
      GenericUtil.transformSpriteColor(leftArrow.arrow, [1, 1, 1, 1, 255, 255, 255]);
      yellowTimerL = null;
    });
  }

  public function callWhiteTimerR():Void
  {
    if (rightArrow.arrow.colorTransform.blueOffset == 255) return;
    yellowTimerR = new FlxTimer().start(0.06, function(tmr) {
      GenericUtil.transformSpriteColor(rightArrow.arrow, [1, 1, 1, 1, 255, 255, 255]);
      yellowTimerR = null;
    });
  }
}

class OptionsBody extends FlxSpriteGroup
{
  public var toggles:Map<String, UIToggle> = [];
  public var background:FlxSprite;

  public function new(x:Float, y:Float)
  {
    super(x, y);
    background = new FlxSprite(40, 120).makeGraphic(1240, 570, FlxColor.BLACK);
    background.alpha = 0.5;
    add(background);
  }
}

// Work in progress
class OptionsMenu extends MusicBeatSubState
{
  public var header:OptionCategoryHeader;
  public var body:OptionsBody;
  public var camMain:FlxCamera;
  public var optionsCam:FlxCamera;

  public var options:Map<String, Array<String>> = ["Gameplay" => [], "Visual" => [], "Appearance" => [], "Misc" => []];

  public var buildOptionObjects:Map<String, BuildOption> = [];

  public var optionObjectsToBuild:Map<String, Dynamic> = [];

  public var cates:Array<String> = ['Gameplay', 'Visuals', 'Misc', 'Appearance'];

  public var currentLoadedOptions:Map<String, Dynamic> = [];

  public function new(?cates:Array<String> = null, ?options:Map<String, Array<String>> = null, ?buildOptionObjects:Map<String, BuildOption>,
      ?optionObjects:Map<String, Dynamic> = null)
  {
    if (cates != null) this.cates = cates;
    if (options != null) this.options = options;
    if (buildOptionObjects != null) this.buildOptionObjects = buildOptionObjects;
    if (optionObjects != null) this.optionObjectsToBuild = optionObjects;
    super();
    camMain = new FlxCamera(0, 0, FlxG.width, FlxG.height);
    optionsCam = new FlxCamera();
  }

  override public function create()
  {
    persistentDraw = persistentUpdate = true;

    FlxG.cameras.add(camMain, false);
    FlxG.cameras.setDefaultDrawTarget(camMain, true);
    this.camera = camMain;
    FlxG.mouse.visible = true;

    FlxG.camera.zoom = 1.0;

    header = new OptionCategoryHeader(0, 0, cates);
    header.camera = camMain;
    add(header);

    body = new OptionsBody(0, 0);
    body.camera = camMain;
    body.background.x = header.background.x;
    add(body);

    reloadOptions(header.currentCata.cata);

    super.create();
  }

  public function reloadOptions(curSelected:String)
  {
    currentLoadedOptions.clear();
    final optionChoices:Array<String> = options.get(curSelected);
    for (option in optionChoices)
    {
      final buildOption:BuildOption = buildOptionObjects.get(option);
      switch (buildOption)
      {
        case DROPDOWN:
        case ARRAY:
        case TOGGLE:
        case SHIFT:
        case NUMBER:
        case SLIDER:
        case KEYBIND:
      }
    }
  }

  override public function update(elapsed:Float)
  {
    if (FlxG.mouse.overlaps(header.leftArrow, camMain))
    {
      GenericUtil.transformSpriteColor(header.leftArrow.arrow, [1, 1, 1, 1, 255, 255, 0]);
      if (FlxG.mouse.justPressed)
      {
        header.onChangeCata(-1);
        reloadOptions(header.currentCata.cata);
      }
    }
    else
      header.callWhiteTimerL();

    if (FlxG.mouse.overlaps(header.rightArrow, camMain))
    {
      GenericUtil.transformSpriteColor(header.rightArrow.arrow, [1, 1, 1, 1, 255, 255, 0]);
      if (FlxG.mouse.justPressed)
      {
        header.onChangeCata(1);
        reloadOptions(header.currentCata.cata);
      }
    }
    else
      header.callWhiteTimerR();

    super.update(elapsed);
  }
}
