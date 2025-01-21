package objects;

import flixel.ui.FlxBar;
import objects.Bar;
import objects.BarHit;
import backend.Countdown;
import backend.Rating;

class Hud extends FlxGroup
{
  // Score
  public var scoreTxtSprite:FlxSprite;

  // Judgement
  public var judgementCounter:FlxText;

  // Health
  public var healthSet:Bool = false;
  public var health:Float = 1;
  public var maxHealth:Float = 2;

  // Score
  public var scoreTxtTween:FlxTween;
  public var scoreTxt:FlxText;

  // Judgement Items
  public var comboStats:ComboStats = new ComboStats();

  // HealthBar
  public var healthBarOverlay:AttachedSprite;
  public var healthBarHitBG:AttachedSprite;
  public var healthBarBG:AttachedSprite;

  public var healthBar:FlxBar;
  public var healthBarHit:FlxBar;
  public var healthBarNew:Bar;
  public var healthBarHitNew:BarHit;

  // TimeBar
  public var timeBarBG:AttachedSprite;
  public var timeBar:FlxBar;
  public var timeBarNew:Bar;
  public var timeTxt:FlxText;

  // Botplay
  public var botplaySine:Float = 0;
  public var botplayTxt:FlxText;

  // Icon
  public var iconP1:HealthIcon;
  public var iconP2:HealthIcon;

  // glow's kade stuff
  public var kadeEngineWatermark:FlxText;
  public var whichHud:String = ClientPrefs.data.hudStyle;
  public var allowTxtColorChanges:Bool = false;
  public var has3rdIntroAsset:Bool = false;

  public var game:Dynamic = null;

  public var boyfriend(get, never):Character;

  function get_boyfriend():Character
    return game.boyfriend;

  public var dad(get, never):Character;

  function get_dad():Character
    return game.dad;

  public var songPercent:Float = 0;
  public var updateTime:Bool = true;
  public var popupScoreForOp:Bool = ClientPrefs.data.popupScoreForOp;

  public var endSong:Void->Void = null;
  public var countdownTick:(Countdown, Int) -> Void;

  public function new(?game:Dynamic = null)
  {
    if (game != null) this.game = game;
    else
      this.game = cast FlxG.state;
    allowTxtColorChanges = ClientPrefs.data.coloredText;
    super();
  }

  public dynamic function cache()
  {
    cacheCountdown();
    cachePopUpScore();
  }

  public dynamic function createHUD()
  {
    // INITIALIZE UI GROUPS
    comboGroup = new ComboRatingGroup();
    comboGroupOP = new ComboRatingGroup();
    comboGroup.placement = ClientPrefs.data.gameCombo ? FlxG.width * 0.55 : FlxG.width * 0.48;
    comboGroupOP.placement = FlxG.width * 0.38;
    comboGroupOP.opponent = true;
    addTimeUI();
    addComboGroupUI();
    addHealthUI();
    setHudCameras();

    endSong = function() {
      updateTime = false;
      timeBarNew.visible = false;
      timeBar.visible = false;
      timeTxt.visible = false;
    }
    onDisplayPopedCombo = function(strumLine:StrumLine, note:Note, opponent:Bool) {
    }
    onReloadColors = function() {
    }
  }

  public var onDisplayPopedCombo:(StrumLine, Note, Bool) -> Void = null;
  public var onReloadColors:Void->Void = null;

  public function addTimeUI()
  {
    var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
    timeTxt = new FlxText(StrumLine.STRUM_X + (FlxG.width / 2) - 248, ClientPrefs.data.downScroll ? FlxG.height - 44 : 20, 400, "", 32);
    timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    timeTxt.scrollFactor.set();
    timeTxt.alpha = 0;
    timeTxt.borderSize = 2;
    timeTxt.visible = !game.showCaseMode ? updateTime = showTime : false;
    if (ClientPrefs.data.timeBarType == 'Song Name')
    {
      timeTxt.text = game.songName;
      timeTxt.size = 24;
      timeTxt.y += 3;
    }

    timeBarBG = new AttachedSprite('timeBarOld');
    timeBarBG.x = timeTxt.x;
    timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
    timeBarBG.scrollFactor.set();
    timeBarBG.alpha = 0;
    timeBarBG.color = FlxColor.BLACK;
    timeBarBG.xAdd = -4;
    timeBarBG.yAdd = -4;
    timeBarBG.visible = !game.showCaseMode ? showTime : false;

    timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, ClientPrefs.data.timeBarType != 'Time Left' ? LEFT_TO_RIGHT : RIGHT_TO_LEFT,
      Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this, 'songPercent', 0, 1);
    timeBar.scrollFactor.set();
    if (showTime)
    {
      if (ClientPrefs.data.colorBarType == 'No Colors') timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
      else if (ClientPrefs.data.colorBarType == 'Main Colors') timeBar.createGradientBar([FlxColor.BLACK], [
        FlxColor.fromString(game.boyfriend.iconColorFormatted),
        FlxColor.fromString(game.dad.iconColorFormatted)
      ]);
      else if (ClientPrefs.data.colorBarType == 'Reversed Colors') timeBar.createGradientBar([FlxColor.BLACK], [
        FlxColor.fromString(game.dad.iconColorFormatted),
        FlxColor.fromString(game.boyfriend.iconColorFormatted)
      ]);
    }
    timeBar.numDivisions = 800; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
    timeBar.alpha = 0;
    timeBar.visible = !game.showCaseMode ? showTime : false;
    timeBarBG.sprTracker = timeBar;

    timeBarNew = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1, "");
    timeBarNew.scrollFactor.set();
    timeBarNew.screenCenter(X);
    timeBarNew.leftToRight = ClientPrefs.data.timeBarType != 'Time Left';
    timeBarNew.alpha = 0;
    timeBarNew.visible = !game.showCaseMode ? showTime : false;

    if (PlayState.SONG.options.oldBarSystem)
    {
      add(timeBarBG);
      add(timeBar);
    }
    else
      add(timeBarNew);
    add(timeTxt);
  }

  public function addComboGroupUI()
  {
    add(comboGroup);
    add(comboGroupOP);
  }

  public function addHealthUI()
  {
    healthBarBG = new AttachedSprite('healthBarOld');
    healthBarBG.y = ClientPrefs.data.downScroll ? FlxG.height * 0.11 : FlxG.height * 0.89;
    healthBarBG.screenCenter(X);
    healthBarBG.scrollFactor.set();
    healthBarBG.visible = !ClientPrefs.data.hideHud;
    healthBarBG.xAdd = -4;
    healthBarBG.yAdd = -4;

    healthBarHitBG = new AttachedSprite('healthBarHit');
    healthBarHitBG.y = ClientPrefs.data.downScroll ? 0 : FlxG.height * 0.9;
    healthBarHitBG.screenCenter(X);
    healthBarHitBG.visible = !ClientPrefs.data.hideHud;
    healthBarHitBG.alpha = ClientPrefs.data.healthBarAlpha;
    healthBarHitBG.flipY = !ClientPrefs.data.downScroll;

    // healthBar
    healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
      'health', 0, maxHealth);
    healthBar.scrollFactor.set();

    healthBar.visible = !ClientPrefs.data.hideHud;
    healthBar.alpha = ClientPrefs.data.healthBarAlpha;
    healthBarBG.sprTracker = healthBar;

    healthBarOverlay = new AttachedSprite('healthBarOverlay');
    healthBarOverlay.y = healthBarBG.y;
    healthBarOverlay.screenCenter(X);
    healthBarOverlay.scrollFactor.set();
    healthBarOverlay.visible = !ClientPrefs.data.hideHud;
    healthBarOverlay.blend = MULTIPLY;
    healthBarOverlay.color = FlxColor.BLACK;
    healthBarOverlay.xAdd = -4;
    healthBarOverlay.yAdd = -4;

    // healthBarHit
    healthBarHit = new FlxBar(350, healthBarHitBG.y + 15, RIGHT_TO_LEFT, Std.int(healthBarHitBG.width - 120), Std.int(healthBarHitBG.height - 30), this,
      'health', 0, maxHealth);
    healthBarHit.visible = !ClientPrefs.data.hideHud;
    healthBarHit.alpha = ClientPrefs.data.healthBarAlpha;

    healthBarNew = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, maxHealth,
      "healthBarOverlay");
    healthBarNew.screenCenter(X);
    healthBarNew.scrollFactor.set();
    healthBarNew.visible = !ClientPrefs.data.hideHud;
    healthBarNew.alpha = ClientPrefs.data.healthBarAlpha;

    healthBarHitNew = new BarHit(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.87 : 0.09), 'healthBarHit', function() return health, 0, maxHealth);
    healthBarHitNew.screenCenter(X);
    healthBarHitNew.scrollFactor.set();
    healthBarHitNew.visible = !ClientPrefs.data.hideHud;
    healthBarHitNew.alpha = ClientPrefs.data.healthBarAlpha;

    RatingWindow.createRatings();

    // Add Kade Engine watermark
    kadeEngineWatermark = new FlxText(FlxG.width
      - 1276, !ClientPrefs.data.downScroll ? FlxG.height - 35 : FlxG.height - 720, 0,
      game.songName
      + (FlxMath.roundDecimal(game.playbackRate, 3) != 1.00 ? " (" + FlxMath.roundDecimal(game.playbackRate, 3) + "x)" : "")
      + ' - '
      + Difficulty.getString(),
      15);
    kadeEngineWatermark.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    kadeEngineWatermark.scrollFactor.set();
    kadeEngineWatermark.visible = !ClientPrefs.data.hideHud;

    judgementCounter = new FlxText(FlxG.width - 1260, 0, FlxG.width, "", 20);
    judgementCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    judgementCounter.borderSize = 2;
    judgementCounter.borderQuality = 2;
    judgementCounter.scrollFactor.set();
    judgementCounter.screenCenter(Y);
    judgementCounter.visible = !ClientPrefs.data.hideHud;
    if (ClientPrefs.data.judgementCounter) add(judgementCounter);

    scoreTxtSprite = new FlxSprite().makeGraphic(FlxG.width, 20, FlxColor.BLACK);
    scoreTxt = new FlxText(whichHud != 'CLASSIC' ? 0 : healthBar.x - healthBar.width - 190,
      (whichHud == "HITMANS" ? (ClientPrefs.data.downScroll ? healthBar.y + 60 : healthBar.y + 50) : whichHud != 'CLASSIC' ? healthBar.y + 40 : healthBar.y
        + 30),
      FlxG.width, "", 20);
    scoreTxt.setFormat(Paths.font("vcr.ttf"), whichHud != 'CLASSIC' ? 20 : 19, FlxColor.WHITE, whichHud != 'CLASSIC' ? CENTER : RIGHT,
      FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    scoreTxt.scrollFactor.set();
    scoreTxt.borderSize = whichHud == 'GLOW_KADE' ? 1.5 : whichHud != 'CLASSIC' ? 1.05 : 1.25;
    if (whichHud != 'CLASSIC') scoreTxt.y + 3;
    scoreTxt.visible = !ClientPrefs.data.hideHud;
    scoreTxtSprite.alpha = 0.5;
    scoreTxtSprite.x = scoreTxt.x;
    scoreTxtSprite.y = scoreTxt.y + 2.5;

    if (whichHud == 'GLOW_KADE') add(kadeEngineWatermark);

    botplayTxt = new FlxText(400, ClientPrefs.data.downScroll ? healthBar.y + 70 : healthBar.y - 90, FlxG.width - 800,
      Language.getPhrase("Botplay").toUpperCase(), 32);
    botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    botplayTxt.scrollFactor.set();
    botplayTxt.borderSize = 1.25;
    botplayTxt.visible = (game.cpuControlled && !game.showCaseMode);
    add(botplayTxt);

    iconP2 = new HealthIcon(game.dad.healthIcon, false);
    iconP1 = new HealthIcon(game.boyfriend.healthIcon, true);
    for (icon in [iconP1, iconP2])
    {
      icon.y = healthBar.y - 75;
      icon.visible = !ClientPrefs.data.hideHud;
      icon.alpha = ClientPrefs.data.healthBarAlpha;
    }

    reloadColors();

    if (whichHud == 'HITMANS')
    {
      if (PlayState.SONG.options.oldBarSystem)
      {
        add(healthBarHit);
        add(healthBarHitBG);
      }
      else
        add(healthBarHitNew);
    }
    else
    {
      if (PlayState.SONG.options.oldBarSystem)
      {
        add(healthBarBG);
        add(healthBar);
        if (whichHud == 'GLOW_KADE') add(healthBarOverlay);
      }
      else
        add(healthBarNew);
    }
    add(iconP1);
    add(iconP2);

    if (whichHud != 'CLASSIC') add(scoreTxtSprite);
    add(scoreTxt);
  }

  public function setHudCameras()
  {
    for (sprite in [
      timeBar,
      timeBarNew,
      timeTxt,
      healthBar,
      healthBarNew,
      healthBarHit,
      healthBarHitNew,
      kadeEngineWatermark,
      judgementCounter,
      scoreTxtSprite,
      scoreTxt,
      botplayTxt,
      iconP1,
      iconP2,
      timeBarBG,
      healthBarBG,
      healthBarHitBG,
      healthBarOverlay
    ])
      sprite.cameras = [game.camHUD];
    comboGroupOP.cameras = comboGroup.cameras = [ClientPrefs.data.gameCombo ? game.camGame : game.camHUD];
  }

  public dynamic function updateHealthColors(colorsUsed:Bool, gradientSystem:Bool)
  {
    if (PlayState.SONG.options.oldBarSystem)
    {
      if (!gradientSystem)
      {
        if (colorsUsed) healthBar.createFilledBar(FlxColor.fromString(game.dad.iconColorFormatted), FlxColor.fromString(game.boyfriend.iconColorFormatted));
        else
          healthBar.createFilledBar(FlxColor.fromString('#FF0000'), FlxColor.fromString('#66FF33'));
      }
      else
      {
        if (colorsUsed) healthBar.createGradientBar([
          FlxColor.fromString(game.boyfriend.iconColorFormatted),
          FlxColor.fromString(game.dad.iconColorFormatted)
        ], [
          FlxColor.fromString(game.boyfriend.iconColorFormatted),
          FlxColor.fromString(game.dad.iconColorFormatted)
        ]);
        else
          healthBar.createGradientBar([FlxColor.fromString("#66FF33"), FlxColor.fromString("#FF0000")],
            [FlxColor.fromString("#66FF33"), FlxColor.fromString("#FF0000")]);
      }
      healthBar.updateBar();
    }
    else
    {
      if (colorsUsed)
      {
        healthBarHitNew.setColors(FlxColor.fromString(game.dad.iconColorFormatted), FlxColor.fromString(game.boyfriend.iconColorFormatted));
        healthBarNew.setColors(FlxColor.fromString(game.dad.iconColorFormatted), FlxColor.fromString(game.boyfriend.iconColorFormatted));
      }
      else
      {
        healthBarHitNew.setColors(FlxColor.fromString('#FF0000'), FlxColor.fromString('#66FF33'));
        healthBarNew.setColors(FlxColor.fromString('#FF0000'), FlxColor.fromString('#66FF33'));
      }
    }
  }

  public dynamic function reloadColors()
  {
    updateHealthColors(ClientPrefs.data.healthColor, ClientPrefs.data.gradientSystemForOldBars);

    if (PlayState.SONG.options.oldBarSystem)
    {
      if (ClientPrefs.data.colorBarType == 'Main Colors') timeBar.createGradientBar([FlxColor.BLACK], [
        FlxColor.fromString(game.boyfriend.iconColorFormatted),
        FlxColor.fromString(game.dad.iconColorFormatted)
      ]);
      else if (ClientPrefs.data.colorBarType == 'Reversed Colors') timeBar.createGradientBar([FlxColor.BLACK], [
        FlxColor.fromString(game.dad.iconColorFormatted),
        FlxColor.fromString(game.boyfriend.iconColorFormatted)
      ]);
      timeBar.updateBar();
    }

    if (!allowTxtColorChanges) return;
    for (i in [timeTxt, kadeEngineWatermark, scoreTxt, judgementCounter, botplayTxt])
    {
      i.color = FlxColor.fromString(game.dad.iconColorFormatted);
      if (i.color == CoolUtil.colorFromString('0xFF000000')
        || i.color == CoolUtil.colorFromString('#000000')
        || i.color == FlxColor.BLACK) i.borderColor = FlxColor.WHITE;
      else
        i.borderColor = FlxColor.BLACK;
    }
    if (onReloadColors != null) onReloadColors();
  }

  public var healthLerp:Float = 1;
  public var healthLerps:Bool = false;
  public var iconOffset:Float = 26;

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (game.showCaseMode)
    {
      for (i in [
        iconP1,
        iconP2,
        healthBar,
        healthBarNew,
        healthBarBG,
        timeBar,
        timeBarBG,
        timeTxt,
        timeBarNew,
        scoreTxt,
        scoreTxtSprite,
        kadeEngineWatermark,
        healthBarHit,
        healthBarHitBG,
        healthBarHitNew,
        healthBarOverlay,
        judgementCounter
      ])
      {
        if (i.visible) i.visible = false;
        if (i.alpha > 0) i.alpha = 0;
      }
    }
    else
    {
      if (botplayTxt != null && botplayTxt.visible)
      {
        botplaySine += 180 * elapsed;
        botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
      }
    }

    health = PlayState.SONG.options.oldBarSystem ? (healthSet ? 1 : (health > maxHealth ? maxHealth : health)) : (healthSet ? 1 : (healthBarNew.bounds.max != null ? (health > healthBarNew.bounds.max ? healthBarNew.bounds.max : health) : (health > maxHealth ? maxHealth : health)));
    healthLerp = FlxMath.lerp(healthLerp, (health * 50), (elapsed * 10));
    if (healthLerps)
    {
      if (healthBar != null) healthBar.percent = healthLerp;
      if (healthBarNew != null) healthBar.percent = healthLerp;
      if (healthBarHit != null) healthBarHit.percent = healthLerp;
      if (healthBarHitNew != null) healthBarHitNew.percent = healthLerp;
    }

    if (whichHud == 'HITMANS')
    {
      if (!iconP1.overrideIconPlacement) iconP1.x = FlxG.width - 160;
      if (!iconP2.overrideIconPlacement) iconP2.x = 0;
    }
    else
    {
      var healthPercent = PlayState.SONG.options.oldBarSystem ? FlxMath.remapToRange(healthBar.percent, 0, 100, 100,
        0) : FlxMath.remapToRange(healthBarNew.percent, 0, 100, 100, 0);
      var addedIconX = PlayState.SONG.options.oldBarSystem ? healthBar.x + (healthBar.width * (healthPercent * 0.01)) : healthBarNew.x
        + (healthBarNew.width * (healthPercent * 0.01));

      if (!iconP1.overrideIconPlacement) iconP1.x = addedIconX + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
      if (!iconP2.overrideIconPlacement) iconP2.x = addedIconX - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
    }

    if (health <= 0) health = 0;
    else if (health >= 2) health = 2;

    if (!game.startingSong && !game.paused && updateTime)
    {
      var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
      songPercent = (curTime / game.songLength);

      var songCalc:Float = (game.songLength - curTime);
      if (ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime;

      var secondsTotal:Int = Math.floor(songCalc / 1000);
      if (secondsTotal < 0) secondsTotal = 0;

      if (ClientPrefs.data.timeBarType != 'Song Name') timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
    }
  }

  public var opponentIconScale:Float = 1.2;
  public var playerIconScale:Float = 1.2;
  public var iconBopSpeed:Int = 1;

  public function beatHit(curBeat:Int):Void
  {
    for (icon in [iconP1, iconP2])
    {
      if (!icon.overrideBeatBop)
      {
        icon.iconBopSpeed = iconBopSpeed;
        icon.beatHit(curBeat);
      }
    }
  }

  public dynamic function tweenInTimeBar()
  {
    if (PlayState.SONG.options.oldBarSystem)
    {
      FlxTween.tween(timeBarBG, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
      FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
    }
    else
      FlxTween.tween(timeBarNew, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
    FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
  }

  // Stores Ratings and Combo Sprites in a group for OP
  public var comboGroupOP:ComboRatingGroup;
  // Stores Ratings and Combo Sprites in a group
  public var comboGroup:ComboRatingGroup;

  public function cachePopUpScore()
  {
    var uiPrefix:String = '';
    var uiSuffix:String = '';

    var stageUIPrefixNotNull:Bool = false;
    var stageUISuffixNotNull:Bool = false;

    if (game.stage.stageUIPrefixShit != null)
    {
      uiPrefix = game.stage.stageUIPrefixShit;
      stageUIPrefixNotNull = true;
    }
    if (game.stage.stageUISuffixShit != null)
    {
      uiSuffix = game.stage.stageUISuffixShit;
      stageUISuffixNotNull = true;
    }

    if (!stageUIPrefixNotNull && !stageUISuffixNotNull)
    {
      if (PlayState.stageUI != "normal")
      {
        uiPrefix = '${PlayState.stageUI}UI/';
        if (PlayState.isPixelStage) uiSuffix = '-pixel';
      }
    }
    else
    {
      switch (game.stage.curStage)
      {
        default:
          uiPrefix = game.stage.stageUIPrefixShit;
          uiSuffix = game.stage.stageUISuffixShit;
      }
    }

    for (rating in Rating.timingWindows)
      Paths.cacheBitmap(uiPrefix + rating.name.toLowerCase() + uiSuffix);
    for (i in 0...10)
      Paths.cacheBitmap(uiPrefix + 'num' + i + uiSuffix);
  }

  public dynamic function displayPopedCombo(strumLine:StrumLine, note:Note, opponent:Bool = false):Void
  {
    if (opponent)
    {
      note.canSplash = ((!note.noteSplashData.disabled && ClientPrefs.splashOption('Opponent')) && !PlayState.SONG.options.notITG);
      if (note.canSplash)
      {
        strumLine.spawnSplash(
          {
            currentDataIndex: note.noteData,
            targetNote: note,
            isPlayer: strumLine.characterStrumlineType == 'BF'
          });
      }

      comboStats.comboOp++;
      comboGroupOP.popCombo('swag', comboStats.comboOp, game);
    }
    else
    {
      final noteDiff:Float = strumLine.cpuControlled ? 0 : Math.abs(note.strumTime - Conductor.songPosition);
      // tryna do MS based judgment due to popular demand
      var daRating:RatingWindow = Rating.judgeNote(noteDiff > 0 ? (noteDiff / strumLine.playbackSpeed) : noteDiff, strumLine.cpuControlled);
      var score:Float = 0;

      note.rating = daRating;

      if (ClientPrefs.data.behaviourType == 'KADE')
      {
        substates.ResultsScreenKadeSubstate.instance.registerHit(note, false, strumLine.cpuControlled, Rating.timingWindows[0].timingWindow);
      }

      score = daRating.scoreBonus;
      daRating.count++;

      note.canSplash = ((!note.noteSplashData.disabled && ClientPrefs.splashOption('Player') && daRating.doNoteSplash)
        && !PlayState.SONG.options.notITG);
      if (note.canSplash)
      {
        strumLine.spawnSplash(
          {
            currentDataIndex: note.noteData,
            targetNote: note,
            isPlayer: strumLine.characterStrumlineType == 'BF'
          });
      }
      note.ratingToString = daRating.name.toLowerCase();

      if (strumLine.playbackSpeed >= 1.05) score = comboStats.getRatesScore(strumLine.playbackSpeed, score);
      comboStats.hit(note.ratingToString, Math.round(score), daRating);
      comboGroup.popCombo(note.ratingToString, comboStats.combo, game);
    }
    if (onDisplayPopedCombo != null) onDisplayPopedCombo(strumLine, note, opponent);
  }

  public dynamic function updateScoreText()
  {
    comboStats.updateAcc = CoolUtil.floorDecimal(comboStats.ratingPercent * 100, 2);

    var str:String = Language.getPhrase('rating_${comboStats.ratingName}', comboStats.ratingName);
    if (comboStats.totalPlayed != 0)
    {
      str += ' (${comboStats.updateAcc}%) - ' + Language.getPhrase(comboStats.ratingFC);

      // Song Rating!
      comboStats.comboLetterRank = Rating.generateComboLetter(comboStats.updateAcc);
    }

    final songScoreStr:String = flixel.util.FlxStringUtil.formatMoney(comboStats.songScore, false);
    final suffix:String = game.instakillOnMiss ? '_instakill' : '';
    var tempScore:String;
    var stuffArray:Array<Dynamic> = [songScoreStr, comboStats.songMisses, str];
    var typePharse:String = 'score_text${suffix}';
    var lineScore:String = 'Score: {1} | Misses: {2} | Rating: {3} | Rank: {4}';
    switch (whichHud)
    {
      case 'CLASSIC':
        typePharse = 'score_text_classic';
        stuffArray.pop();
        stuffArray.pop();
        lineScore = lineScore.replace(' | Misses: {2} | Rating: {3} | Rank: {4}', '');
      case 'GLOW_KADE':
        typePharse = 'score_text${suffix}_glowkade';
        lineScore = lineScore.replace('|', '•').replace('Misses', 'Combo Breaks');
        if (suffix.length < 1) stuffArray.push(comboStats.comboLetterRank);
        else
          lineScore = lineScore.replace(' • Combo Breaks: {2}', '').replace('3', '2').replace('4', '3');
      case 'HITMANS':
        typePharse = 'score_text${suffix}_hitmans';
        if (suffix.length < 1) stuffArray.push(comboStats.comboLetterRank);
        else
          lineScore = lineScore.replace(' | Misses: {2}', '').replace('3', '2').replace('4', '3');
      default:
        lineScore = lineScore.replace(' | Rank: {4}', '');
        if (suffix.length > 0) lineScore = lineScore.replace(' | Misses: {2}', '').replace('3', '2');
    }

    if (whichHud == 'CLASSIC') tempScore = Language.getPhrase('score_text_classic', 'Score: {1}', [songScoreStr]);
    else
      tempScore = Language.getPhrase(typePharse, lineScore, stuffArray);
    scoreTxt.text = tempScore;

    if (ClientPrefs.data.judgementCounter)
    {
      judgementCounter.text = '';

      var timingWins = Rating.timingWindows.copy();
      timingWins.reverse();

      for (rating in timingWins)
        judgementCounter.text += '${rating.name}s: ${rating.count}\n';

      judgementCounter.text += 'Misses: ${comboStats.songMisses}\n';
      judgementCounter.updateHitbox();
    }
  }

  public function doScoreBop():Void
  {
    if (!ClientPrefs.data.scoreZoom) return;

    if (scoreTxtTween != null) scoreTxtTween.cancel();

    scoreTxt.scale.x = 1.075;
    scoreTxt.scale.y = 1.075;
    scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2,
      {
        onComplete: function(twn:FlxTween) {
          scoreTxtTween = null;
        }
      });
  }

  public var startTimer:FlxTimer;

  // For being able to mess with the sprites on Lua
  public var getReady:FlxSprite;
  public var countdownReady:FlxSprite;
  public var countdownSet:FlxSprite;
  public var countdownGo:FlxSprite;

  // CountDown Stuff
  public var stageIntroSoundsSuffix:String = '';
  public var stageIntroSoundsPrefix:String = '';

  function cacheCountdown()
  {
    stageIntroSoundsSuffix = game.stage.stageIntroSoundsSuffix != null ? game.stage.stageIntroSoundsSuffix : '';
    stageIntroSoundsPrefix = game.stage.stageIntroSoundsPrefix != null ? game.stage.stageIntroSoundsPrefix : '';

    var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
    final introImagesArray:Array<String> = switch (PlayState.stageUI)
    {
      case "pixel": [
          '${PlayState.stageUI}UI/ready-pixel',
          '${PlayState.stageUI}UI/set-pixel',
          '${PlayState.stageUI}UI/date-pixel'
        ];
      case "normal": ["ready", "set", "go"];
      default: [
          '${PlayState.stageUI}UI/ready',
          '${PlayState.stageUI}UI/set',
          '${PlayState.stageUI}UI/go'
        ];
    }
    if (game.stage.stageIntroAssets != null) introAssets.set(game.stage.curStage, game.stage.stageIntroAssets);
    else
      introAssets.set(PlayState.stageUI, introImagesArray);
    var introAlts:Array<String> = introAssets.get(PlayState.stageUI);

    for (value in introAssets.keys())
    {
      if (value == game.stage.curStage)
      {
        introAlts = introAssets.get(value);

        if (stageIntroSoundsSuffix != null && stageIntroSoundsSuffix.length > 0) introSoundsSuffix = stageIntroSoundsSuffix;
        else
          introSoundsSuffix = '';

        if (stageIntroSoundsPrefix != null && stageIntroSoundsPrefix.length > 0) introSoundsPrefix = stageIntroSoundsPrefix;
        else
          introSoundsPrefix = '';
      }
    }

    for (asset in introAlts)
      Paths.image(asset);

    Paths.sound(introSoundsPrefix + 'intro3' + introSoundsSuffix);
    Paths.sound(introSoundsPrefix + 'intro2' + introSoundsSuffix);
    Paths.sound(introSoundsPrefix + 'intro1' + introSoundsSuffix);
    Paths.sound(introSoundsPrefix + 'introGo' + introSoundsSuffix);
  }

  public var introSoundsSuffix:String = '';
  public var introSoundsPrefix:String = '';

  public var tick:Countdown = PREPARE;

  public function startCountdownTimer()
  {
    var swagCounter:Int = 0;
    stageIntroSoundsSuffix = game.stage.stageIntroSoundsSuffix != null ? game.stage.stageIntroSoundsSuffix : '';
    stageIntroSoundsPrefix = game.stage.stageIntroSoundsPrefix != null ? game.stage.stageIntroSoundsPrefix : '';

    startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer) {
      var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
      final introImagesArray:Array<String> = switch (PlayState.stageUI)
      {
        case "pixel": [
            '${PlayState.stageUI}UI/ready-pixel',
            '${PlayState.stageUI}UI/set-pixel',
            '${PlayState.stageUI}UI/date-pixel'
          ];
        case "normal": ["ready", "set", "go"];
        default: [
            '${PlayState.stageUI}UI/ready',
            '${PlayState.stageUI}UI/set',
            '${PlayState.stageUI}UI/go'
          ];
      }
      if (game.stage.stageIntroAssets != null) introAssets.set(game.stage.curStage, game.stage.stageIntroAssets);
      else
        introAssets.set(PlayState.stageUI, introImagesArray);

      var isPixelated:Bool = PlayState.isPixelStage;
      var introAlts:Array<String> = (game.stage.stageIntroAssets != null ? introAssets.get(game.stage.curStage) : introAssets.get(PlayState.stageUI));
      var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelated);

      for (value in introAssets.keys())
      {
        if (value == game.stage.curStage)
        {
          introAlts = introAssets.get(value);

          if (stageIntroSoundsSuffix != '' || stageIntroSoundsSuffix != null || stageIntroSoundsSuffix != "") introSoundsSuffix = stageIntroSoundsSuffix;
          else
            introSoundsSuffix = '';

          if (stageIntroSoundsPrefix != '' || stageIntroSoundsPrefix != null || stageIntroSoundsPrefix != "") introSoundsPrefix = stageIntroSoundsPrefix;
          else
            introSoundsPrefix = '';
        }
      }

      var introArrays0:Array<Float> = null;
      var introArrays1:Array<Float> = null;
      var introArrays2:Array<Float> = null;
      var introArrays3:Array<Float> = null;
      if (game.stage.stageIntroSpriteScales != null)
      {
        introArrays0 = game.stage.stageIntroSpriteScales[0];
        introArrays1 = game.stage.stageIntroSpriteScales[1];
        introArrays2 = game.stage.stageIntroSpriteScales[2];
        introArrays3 = game.stage.stageIntroSpriteScales[3];
      }

      tick = decrementTick(tick);

      switch (tick)
      {
        case THREE:
          var isNotNull = (introAlts.length > 3 ? introAlts[0] : "missingRating");
          getReady = createCountdownSprite(isNotNull, antialias, introSoundsPrefix + 'intro3' + introSoundsSuffix, introArrays0);
        case TWO:
          countdownReady = createCountdownSprite(introAlts[introAlts.length - 3], antialias, introSoundsPrefix + 'intro2' + introSoundsSuffix, introArrays1);
        case ONE:
          countdownSet = createCountdownSprite(introAlts[introAlts.length - 2], antialias, introSoundsPrefix + 'intro1' + introSoundsSuffix, introArrays2);
        case GO:
          countdownGo = createCountdownSprite(introAlts[introAlts.length - 1], antialias, introSoundsPrefix + 'introGo' + introSoundsSuffix, introArrays3);
        case START:
        default:
      }

      if (countdownTick != null) countdownTick(tick, swagCounter);

      swagCounter += 1;
    }, 5);
  }

  inline public function decrementTick(tick:Countdown):Countdown
  {
    switch (tick)
    {
      case PREPARE:
        return THREE;
      case THREE:
        return TWO;
      case TWO:
        return ONE;
      case ONE:
        return GO;
      case GO:
        return START;

      default:
        return START;
    }
  }

  inline public function createCountdownSprite(image:String, antialias:Bool, soundName:String, scale:Array<Float> = null):FlxSprite
  {
    final spr:FlxSprite = new FlxSprite(0, -100).loadGraphic(Paths.image(image));
    spr.cameras = [game.camHUD];
    spr.scrollFactor.set();
    spr.updateHitbox();

    if (image.contains("-pixel") && scale == null) spr.setGraphicSize(Std.int(spr.width * PlayState.daPixelZoom));

    if (scale != null && scale.length > 1) spr.scale.set(scale[0], scale[1]);

    spr.screenCenter();
    spr.antialiasing = antialias;
    add(spr);
    FlxTween.tween(spr, {y: 0, alpha: 0}, Conductor.crochet / 1000,
      {
        ease: FlxEase.cubeInOut,
        onComplete: function(twn:FlxTween) {
          remove(spr);
          spr.destroy();
        }
      });
    if (!game.stage.disabledIntroSounds) FlxG.sound.play(Paths.sound(soundName), 0.6);
    return spr;
  }

  public dynamic function setHealthColors(opponentColor:Null<FlxColor> = null, playerColor:Null<FlxColor> = null)
  {
    if (opponentColor == null && playerColor == null) return;

    if (PlayState.SONG.options.oldBarSystem)
    {
      if (!ClientPrefs.data.gradientSystemForOldBars) healthBar.createFilledBar(opponentColor, playerColor);
      else
        healthBar.createGradientBar([playerColor, opponentColor], [playerColor, opponentColor]);
      healthBar.updateBar();
    }
    else
    {
      healthBarNew.setColors(opponentColor, playerColor);
      healthBarHitNew.setColors(opponentColor, playerColor);
    }
  }
}
