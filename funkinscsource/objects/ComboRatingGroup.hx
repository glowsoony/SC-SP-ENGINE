package objects;

class ComboRatingGroup extends FlxSpriteGroup
{
  public var showCombo:Bool = ClientPrefs.data.showCombo;
  public var showComboNum:Bool = ClientPrefs.data.showComboNum;
  public var showRating:Bool = ClientPrefs.data.showRating;

  public var speed:Float = 1;
  public var ratingsAlpha:Float = 1;
  public var placement:Float = 0;
  public var opponent:Bool = false;

  public function popCombo(image:String, combo:Int, game:Dynamic)
  {
    if (game == null) return;

    final stage:Stage = game.stage;
    final playbackRate:Float = game.playbackRate;

    if (!ClientPrefs.data.comboStacking && members.length > 0)
    {
      for (spr in members)
      {
        if (spr == null) continue;

        remove(spr);
        spr.destroy();
      }
    }

    var uiPrefix:String = "";
    var uiSuffix:String = '';
    var antialias:Bool = ClientPrefs.data.antialiasing;
    var stageUIPrefixNotNull:Bool = false;
    var stageUISuffixNotNull:Bool = false;
    if (stage.stageUIPrefixShit != null)
    {
      uiPrefix = stage.stageUIPrefixShit;
      stageUIPrefixNotNull = true;
    }
    if (stage.stageUISuffixShit != null)
    {
      uiSuffix = stage.stageUISuffixShit;
      stageUISuffixNotNull = true;
    }
    var offsetX:Float = 0;
    var offsetY:Float = 0;
    if (!stageUIPrefixNotNull && !stageUISuffixNotNull)
    {
      if (PlayState.stageUI != "normal")
      {
        uiPrefix = '${PlayState.stageUI}UI/';
        if (PlayState.isPixelStage) uiSuffix = '-pixel';
        antialias = !PlayState.isPixelStage;
      }
    }
    else
    {
      switch (stage.curStage)
      {
        default:
          if (ClientPrefs.data.gameCombo)
          {
            if (opponent)
            {
              offsetX = stage.stageRatingOffsetXOpponent != 0 ? stage.gfXOffset + stage.stageRatingOffsetXOpponent : stage.gfXOffset;
              offsetY = stage.stageRatingOffsetYOpponent != 0 ? stage.gfYOffset + stage.stageRatingOffsetYOpponent : stage.gfYOffset;
            }
            else
            {
              offsetX = stage.stageRatingOffsetXPlayer != 0 ? stage.gfXOffset + stage.stageRatingOffsetXPlayer : stage.gfXOffset;
              offsetY = stage.stageRatingOffsetYPlayer != 0 ? stage.gfYOffset + stage.stageRatingOffsetYPlayer : stage.gfYOffset;
            }
          }
          uiPrefix = stage.stageUIPrefixShit;
          uiSuffix = stage.stageUISuffixShit;
          antialias = !(uiPrefix.contains('pixel') || uiSuffix.contains('pixel'));
      }
    }

    if (!showRating && !showComboNum && !showComboNum) return;

    var rating:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + image + uiSuffix));
    if (rating.graphic == null) rating.loadGraphic(Paths.image('missingRating'));
    rating.screenCenter();
    rating.x = placement - 40 + offsetX;
    rating.y -= 60 + offsetY;
    rating.acceleration.y = 550 * playbackRate * playbackRate;
    rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
    rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
    rating.visible = (!ClientPrefs.data.hideHud && showRating);
    rating.x += ClientPrefs.data.comboOffset[0];
    rating.y -= ClientPrefs.data.comboOffset[1];
    rating.antialiasing = antialias;
    rating.alpha = ratingsAlpha;
    var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'combo' + uiSuffix));
    if (comboSpr.graphic == null) comboSpr.loadGraphic(Paths.image('missingRating'));
    comboSpr.screenCenter();
    comboSpr.x = placement + offsetX;
    comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
    comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
    comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
    comboSpr.x += ClientPrefs.data.comboOffset[0];
    comboSpr.y -= ClientPrefs.data.comboOffset[1];
    comboSpr.antialiasing = antialias;
    comboSpr.y += 60 + offsetY;
    comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
    comboSpr.alpha = ratingsAlpha;
    if (showRating) add(rating);
    if (!uiPrefix.contains('pixel') || !uiSuffix.contains('pixel'))
    {
      rating.setGraphicSize(Std.int(rating.width * (stage.stageRatingScales != null ? stage.stageRatingScales[0] : 0.7)));
      comboSpr.setGraphicSize(Std.int(comboSpr.width * (stage.stageRatingScales != null ? stage.stageRatingScales[1] : 0.7)));
    }
    else
    {
      rating.setGraphicSize(Std.int(rating.width * (stage.stageRatingScales != null ? stage.stageRatingScales[2] : 5.1)));
      comboSpr.setGraphicSize(Std.int(comboSpr.width * (stage.stageRatingScales != null ? stage.stageRatingScales[3] : 5.1)));
    }
    comboSpr.updateHitbox();
    rating.updateHitbox();
    var daLoop:Int = 0;
    var xThing:Float = 0;
    if (showCombo && (ClientPrefs.data.hudStyle != 'GLOW_KADE' || (ClientPrefs.data.hudStyle == 'GLOW_KADE' && combo > 5))) add(comboSpr);
    var separatedScore:String = Std.string(combo).lpad('0', 3);
    for (i in 0...separatedScore.length)
    {
      var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'num' + Std.parseInt(separatedScore.charAt(i)) + uiSuffix));
      if (numScore.graphic == null) numScore.loadGraphic(Paths.image('missingRating'));
      numScore.screenCenter();
      numScore.x = placement + (43 * daLoop) - 90 + offsetX + ClientPrefs.data.comboOffset[2];
      numScore.y += 80 - offsetY - ClientPrefs.data.comboOffset[3];
      if (!uiPrefix.contains('pixel') || !uiSuffix.contains('pixel'))
        numScore.setGraphicSize(Std.int(numScore.width * (stage.stageRatingScales != null ? stage.stageRatingScales[4] : 0.5)));
      else
        numScore.setGraphicSize(Std.int(numScore.width * (stage.stageRatingScales != null ? stage.stageRatingScales[5] : PlayState.daPixelZoom)));
      numScore.updateHitbox();
      numScore.acceleration.y = FlxG.random.int(200, 300);
      numScore.velocity.y -= FlxG.random.int(140, 160);
      numScore.velocity.x = FlxG.random.float(-5, 5);
      numScore.visible = !ClientPrefs.data.hideHud;
      numScore.antialiasing = antialias;
      numScore.alpha = ratingsAlpha;
      if (showComboNum
        && (ClientPrefs.data.hudStyle != 'GLOW_KADE'
          || (ClientPrefs.data.hudStyle == 'GLOW_KADE' && (combo >= 10 || combo == 0)))) add(numScore);
      FlxTween.tween(numScore, {alpha: 0}, 0.2,
        {
          onComplete: function(tween:FlxTween) {
            numScore.destroy();
            remove(numScore);
          },
          startDelay: Conductor.crochet * 0.002
        });
      daLoop++;
      if (numScore.x > xThing) xThing = numScore.x;
    }
    comboSpr.x = xThing + 50 + offsetX;
    FlxTween.tween(rating, {alpha: 0}, 0.2,
      {
        startDelay: Conductor.crochet * 0.001
      });
    FlxTween.tween(comboSpr, {alpha: 0}, 0.2,
      {
        onComplete: function(tween:FlxTween) {
          comboSpr.destroy();
          rating.destroy();
          remove(comboSpr);
          remove(rating);
        },
        startDelay: Conductor.crochet * 0.002
      });
  }
}
