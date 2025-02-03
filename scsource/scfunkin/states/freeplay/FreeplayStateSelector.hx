package scfunkin.states.freeplay;

import flixel.FlxObject;
import scfunkin.states.freeplay.CardSprite;

class FreeplayStateSelector extends MusicBeatState
{
  public var curCardSelected:Int = 0;
  public var cards:FlxTypedGroup<CardSprite> = new FlxTypedGroup<CardSprite>();

  var camFollow:FlxObject;
  var camFollowPos:FlxObject;

  var allowMouse:Bool = true; // Turn this off to block mouse movement in menus

  var noModsSine:Float = 0;
  var noModsTxt:FlxText;

  override public function create()
  {
    var directories:Array<String> = [#if MODS_ALLOWED Paths.mods(), #end Paths.getSharedPath()];

    #if MODS_ALLOWED
    for (mod in Mods.parseList().enabled)
      directories.push(Paths.mods(mod + '/'));
    #end

    for (index => directory in directories)
    {
      final data:CardData = grabJsonData(directory);
      if (data == null) continue;

      final cardSprite:CardSprite = new CardSprite(data);
      cardSprite.folder = directory;
      cardSprite.index = index;
      cards.add(cardSprite);
    }

    for (index => card in cards)
    {
      card.x = 100 + (50 * index) + card.data.offsetX;
      card.y = 100 + card.data.offsetY;
      card.calls.onIdle();
    }

    add(cards);

    camFollow = new FlxObject(0, 0, 1, 1);
    camFollowPos = new FlxObject(0, 0, 1, 1);
    add(camFollow);
    add(camFollowPos);

    if (cards.members.length < 1)
    {
      cards.visible = false;
      noModsTxt = new FlxText(0, 0, FlxG.width - 20, "NO CARDS FOUND\nPRESS BACK TO EXIT", 48);
      if (FlxG.random.bool(0.1)) noModsTxt.text += '\nBITCH.'; // meanie
      noModsTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
      noModsTxt.borderSize = 2;
      add(noModsTxt);
      noModsTxt.screenCenter(Y);

      var txt = new FlxText(15, 15, -30, "No Cards found.", 16);
      txt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE);
      add(txt);

      changeCard();
      return super.create();
    }

    super.create();
    changeCard();
    FlxG.camera.follow(camFollowPos, null, 0.15);
  }

  var selectedCard:Bool = false;
  var timeNotMoving:Float = 0;

  override public function update(elapsed:Float):Void
  {
    var lerpVal:Float = scfunkin.utils.MathUtil.clamp(elapsed * 7.5, 0, 1);
    camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

    if (!selectedCard)
    {
      if (controls.BACK)
      {
        selectedCard = true;
        MusicBeatState.switchState(new MainMenuState());
      }
    }

    if (cards.members.length > 0)
    {
      if (!selectedCard)
      {
        // if (controls.ACCEPT || (FlxG.mouse.justPressed && allowMouse) #if android || FlxG.android.justPressed.BACK #end)
        // {
        //   selectedCard = true;
        //   FlxG.sound.play(Paths.sound('confirmMenu'));

        //   openSubState(new FreeplayWeekSongSelector());
        // }

        if (controls.UI_LEFT_P)
        {
          changeCard(-1);
        }
        if (controls.UI_RIGHT_P)
        {
          changeCard(1);
        }

        if (FlxG.mouse.wheel != 0)
        {
          FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
          changeCard(-FlxG.mouse.wheel);
        }

        var allowMouse:Bool = allowMouse;
        if (allowMouse && ((FlxG.mouse.deltaViewX != 0 && FlxG.mouse.deltaViewY != 0) || FlxG.mouse.justPressed))
        {
          allowMouse = false;
          FlxG.mouse.visible = true;
          timeNotMoving = 0;

          var selectedItem:CardSprite = cards.members[curCardSelected];
          var dist:Float = -1;
          var distItem:Int = -1;
          for (i in 0...cards.members.length - 1)
          {
            var memb:FlxSprite = cards.members[i];
            if (FlxG.mouse.overlaps(memb))
            {
              var distance:Float = Math.sqrt(Math.pow(memb.getGraphicMidpoint().x - FlxG.mouse.viewX, 2)
                + Math.pow(memb.getGraphicMidpoint().y - FlxG.mouse.viewY, 2));
              if (dist < 0 || distance < dist)
              {
                dist = distance;
                distItem = i;
                allowMouse = true;
              }
            }
          }

          if (distItem != -1 && selectedItem != cards.members[distItem])
          {
            curCardSelected = distItem;
            changeCard();
          }
        }
        else
        {
          timeNotMoving += elapsed;
          if (timeNotMoving > 2) FlxG.mouse.visible = false;
        }
      }
    }
    else
    {
      noModsSine += 180 * elapsed;
      noModsTxt.alpha = 1 - Math.sin((Math.PI * noModsSine) / 180);
    }
    super.update(elapsed);
  }

  function changeCard(change:Int = 0)
  {
    curCardSelected += change;
    if (curCardSelected < 0) curCardSelected = cards.length - 1;
    if (curCardSelected >= cards.length) curCardSelected = 0;
    FlxG.sound.play(Paths.sound('scrollMenu'));

    for (card in cards)
    {
      card.calls.onIdle();
      card.centerOffsets();
    }

    var selectedItem:CardSprite = cards.members[curCardSelected];
    selectedItem.calls.onSelect();
    selectedItem.centerOffsets();
    camFollow.x = selectedItem.getGraphicMidpoint().x;
    camFollow.y = selectedItem.getGraphicMidpoint().y;
  }

  function grabJsonData(directory:String):CardData
  {
    final parsedData:CardData = getData(directory + '/cards/menuCard.json');
    if (parsedData == null) return null;
    return {
      idle_anim: parsedData.idle_anim,
      select_anim: parsedData.select_anim,
      hover_anim: parsedData.hover_anim,
      offsetX: parsedData.offsetX,
      offsetY: parsedData.offsetY,
      metaData: parsedData.metaData
    };
  }

  function getData(path:String):CardData
  {
    var rawJson:String = null;
    #if MODS_ALLOWED
    if (FileSystem.exists(path)) rawJson = File.getContent(path);
    #else
    if (OpenFlAssets.exists(path)) rawJson = Assets.getText(path);
    #end

    if (rawJson != null && rawJson.length > 0) return cast tjson.TJSON.parse(rawJson);
    return null;
  }
}

class FreeplaySongWeekSelector extends MusicBeatSubState {}
