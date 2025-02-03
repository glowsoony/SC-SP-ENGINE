package scfunkin.backend.data.judgement;

import scfunkin.backend.data.judgement.Rating;
import scfunkin.play.song.data.Highscore;

class ComboStats
{
  // Rating Things
  public static var averageShits:Int = 0;
  public static var averageBads:Int = 0;
  public static var averageGoods:Int = 0;
  public static var averageSicks:Int = 0;
  public static var averageSwags:Int = 0;

  public static var averageWeekAccuracy:Float = 0;
  public static var averageWeekScore:Int = 0;
  public static var averageWeekMisses:Int = 0;
  public static var averageWeekShits:Int = 0;
  public static var averageWeekBads:Int = 0;
  public static var averageWeekGoods:Int = 0;
  public static var averageWeekSicks:Int = 0;
  public static var averageWeekSwags:Int = 0;

  public var shitHits:Int = 0;
  public var badHits:Int = 0;
  public var goodHits:Int = 0;
  public var sickHits:Int = 0;
  public var swagHits:Int = 0;

  public var weekAccuracy:Float = 0;
  public var weekScore:Int = 0;
  public var weekMisses:Int = 0;
  public var weekShits:Int = 0;
  public var weekBads:Int = 0;
  public var weekGoods:Int = 0;
  public var weekSicks:Int = 0;
  public var weekSwags:Int = 0;

  public var playerNotesCount:Int = 0;
  public var opponentNotesCount:Int = 0;
  public var songNotesCount:Int = 0;

  public var highestCombo:Int = 0;
  public var maxCombo:Int = 0;
  public var combo:Int = 0;
  public var comboOp:Int = 0;

  public var ratingName:String = '?';
  public var ratingPercent:Float;
  public var ratingFC:String = '?';

  public var songScore:Int = 0;
  public var songHits:Int = 0;
  public var songMisses:Int = 0;
  public var onRecalculateRating:Bool->Void = null;
  public var onMiss:Void->Void = null;
  public var onLastCombo:Int->Void = null;
  public var onChangeRating:(String, Int, RatingWindow) -> Void = null;
  public var onHit:Void->Void = null;

  public static var ratingStuff:Array<Dynamic> = [
    ['You Suck!', 0.2], // From 0% to 19%
    ['Shit', 0.4], // From 20% to 39%
    ['Bad', 0.5], // From 40% to 49%
    ['Bruh', 0.6], // From 50% to 59%
    ['Meh', 0.69], // From 60% to 68%
    ['Nice', 0.7], // 69%
    ['Good', 0.8], // From 70% to 79%
    ['Great', 0.9], // From 80% to 89%
    ['Sick!', 1], // From 90% to 99%
    ['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
  ];

  public var updateAcc:Float;
  public var comboLetterRank:String;

  public function new()
  {
    swagHits = sickHits = goodHits = badHits = shitHits = songMisses = highestCombo = 0;
    onHit = function() {
    }
    onChangeRating = function(name:String, score:Int, rating:RatingWindow) {
    }
    onMiss = function() {
    }
    onRecalculateRating = function(missed:Bool) {
    }
    onLastCombo = function(lastCombo:Int) {
    }
  }

  public var totalPlayed:Int = 0;
  public var totalNotesHit:Float = 0.0;

  public function add(field:String, value:Dynamic)
    Reflect.setProperty(this, field, Reflect.getProperty(this, field) + value);

  public function set(field:String, value:Dynamic)
    Reflect.setProperty(this, field, value);

  public function reset(field:String, defaultValue:Dynamic)
    Reflect.setProperty(this, field, defaultValue);

  public function miss()
  {
    var lastCombo:Int = combo;
    combo = 0;
    Highscore.songHighScoreData.comboData.combo = 0;

    songScore -= 10;
    add('songMisses', 1);
    Highscore.songHighScoreData.comboData.misses++;
    Highscore.songHighScoreData.comboData.totalPlayed++;
    totalPlayed++;
    if (onLastCombo != null) onLastCombo(lastCombo);
    if (onRecalculateRating != null) onRecalculateRating(true);
    if (onMiss != null) onMiss();
  }

  public function hit(name:String, score:Int, rating:RatingWindow)
  {
    combo++;
    Highscore.songHighScoreData.comboData.combo++;
    if (combo >= 9999) combo = 9999;

    totalNotesHit += rating.accuracyBonus;
    add('totalPlayed', 1);
    Highscore.songHighScoreData.comboData.totalNotesHit += rating.accuracyBonus;
    Highscore.songHighScoreData.comboData.totalPlayed = totalPlayed;

    switch (name)
    {
      case 'shit':
        shitHits++;
        Highscore.songHighScoreData.comboData.shits += 1;
      case 'bad':
        badHits++;
        Highscore.songHighScoreData.comboData.bads += 1;
      case 'good':
        goodHits++;
        Highscore.songHighScoreData.comboData.goods += 1;
      case 'sick':
        sickHits++;
        Highscore.songHighScoreData.comboData.sicks += 1;
      case 'swag':
        swagHits++;
        Highscore.songHighScoreData.comboData.swags += 1;
    }

    if (combo > highestCombo) highestCombo = combo - 1;
    if (combo > maxCombo) maxCombo = combo;

    if (Highscore.songHighScoreData.comboData.combo > Highscore.songHighScoreData.comboData.highestCombo)
      Highscore.songHighScoreData.comboData.highestCombo = Highscore.songHighScoreData.comboData.combo
      - 1;
    if (Highscore.songHighScoreData.comboData.combo > Highscore.songHighScoreData.comboData.maxCombo)
      Highscore.songHighScoreData.comboData.maxCombo = Highscore.songHighScoreData.comboData.combo;

    add('songScore', score);
    songHits++;
    if (onRecalculateRating != null) onRecalculateRating(false);
    if (onChangeRating != null) onChangeRating(name, score, rating);
    if (onHit != null) onHit();
  }

  public function getRatesScore(rate:Float, score:Float):Float
  {
    var rateX:Float = 1;
    var lastScore:Float = score;
    var pr = rate - 0.05;
    if (pr < 1.00) pr = 1;

    while (rateX <= pr)
    {
      if (rateX > pr) break;
      lastScore = score + ((lastScore * rateX) * 0.022);
      rateX += 0.05;
    }

    final actualScore:Float = Math.round(score + (Math.floor((lastScore * pr)) * 0.022));
    return actualScore;
  }

  public function addWeekAverage(accuracy:Float)
  {
    add('weekAccuracy', accuracy);
    add('weekScore', Math.round(songScore));
    add('weekMisses', songMisses);
    add('weekSwags', swagHits);
    add('weekSicks', sickHits);
    add('weekGoods', goodHits);
    add('weekBads', badHits);
    add('weekShits', shitHits);
  }

  public function setWeekAverages()
    set_weekAverage(weekAccuracy, [weekScore, weekMisses, weekSwags, weekSicks, weekGoods, weekBads, weekShits]);

  public function setRatingAverages()
    set_ratingAverage([swagHits, sickHits, goodHits, badHits, shitHits]);

  public function set_weekAverage(acc:Float, weekArgs:Array<Int>)
  {
    var averageWeek:Array<String> = ['Accuracy', 'Score', 'Misses', 'Swags', 'Sicks', 'Goods', 'Bads', 'Shits'];
    var averageWeekFinal:Array<String> = [];
    for (score in averageWeek)
    {
      final newScore:String = 'averageWeek$score';
      averageWeekFinal.push(newScore);
    }
    Debug.logInfo(averageWeekFinal);
    for (i in 0...weekArgs.length + 1)
    {
      if (averageWeekFinal[i] == 'averageWeekAccuracy') Reflect.setProperty(this, averageWeekFinal[i], (Reflect.getProperty(this, averageWeek[i]) + acc));
      else
        Reflect.setProperty(this, averageWeekFinal[i], (Reflect.getProperty(this, averageWeekFinal[i]) + weekArgs[i]));
    }
  }

  public function set_ratingAverage(ratingArgs:Array<Int>)
  {
    averageSwags = ratingArgs[0];
    averageSicks = ratingArgs[1];
    averageBads = ratingArgs[3];
    averageGoods = ratingArgs[2];
    averageShits = ratingArgs[4];
  }
}
