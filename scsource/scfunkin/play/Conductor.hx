package scfunkin.play;

import scfunkin.play.song.data.SongData;
import flixel.util.FlxSignal;

typedef BPMChangeEvent =
{
  var stepTime:Float;
  var songTime:Float;
  var bpm:Float;
  var ?stepCrochet:Float;
}

class ConductorUpdater
{
  /**
   * Current Step position.
   */
  public var curStep:Int = 0;

  public var stepsToDo:Int = 0;

  /**
   * Current Beat position.
   */
  public var curBeat:Int = 0;

  /**
   * Current Measure / Section Position.
   */
  public var curSection:Int = 0;

  public var curDecStep:Float = 0;
  public var curDecBeat:Float = 0;

  public function new() {}

  public function update(elapsed:Float)
  {
    var oldStep:Int = curStep;

    updateCurStep();
    updateBeat();

    if (oldStep != curStep)
    {
      if (curStep >= 0)
      {
        Conductor.stepHit.dispatch();
        if (curStep % 4 == 0) Conductor.beatHit.dispatch();
      }

      if (PlayState.SONG != null)
      {
        if (oldStep < curStep) updateSection();
        else
          rollbackSection();
      }
    }
  }

  var trackedBPMChanges:Int = 0;

  /**
   * A handy function to calculate how many seconds it takes for the given steps to all be hit.
   *
   * This function takes the future BPM into account.
   * If you feel this is not necessary, use `stepsToSecs_simple` instead.
   * @param targetStep The step value to calculate with.
   * @param isFixedStep If true, calculation will assume `targetStep` is not being calculated as in "after `targetStep` steps", but rather as in "time until `targetStep` is hit".
   * @return The amount of seconds as a float.
   */
  inline public function stepsToSecs(targetStep:Int, isFixedStep:Bool = false):Float
  {
    final playbackRate:Single = PlayState.instance != null ? PlayState.instance.playbackRate : 1;
    function calc(stepVal:Single, crochetBPM:Int = -1)
    {
      return ((crochetBPM == -1 ? Conductor.calculateCrochet(Conductor.bpm) / 4 : Conductor.calculateCrochet(crochetBPM) / 4) * (stepVal - curStep)) / 1000;
    }

    final realStep:Single = isFixedStep ? targetStep : targetStep + curStep;
    var secRet:Float = calc(realStep);

    for (i in 0...Conductor.bpmChangeMap.length - trackedBPMChanges)
    {
      var nextChange = Conductor.bpmChangeMap[trackedBPMChanges + i];
      if (realStep < nextChange.stepTime) break;

      final diff = realStep - nextChange.stepTime;
      if (i == 0) secRet -= calc(diff);
      else
        secRet -= calc(diff, Std.int(Conductor.bpmChangeMap[(trackedBPMChanges + i) - 1].bpm)); // calc away bpm from before, not beginning bpm

      secRet += calc(diff, Std.int(nextChange.bpm));
    }
    // trace(secRet);
    return secRet / playbackRate;
  }

  inline public function beatsToSecs(targetBeat:Int, isFixedBeat:Bool = false):Float
    return stepsToSecs(targetBeat * 4, isFixedBeat);

  /**
   * A handy function to calculate how many seconds it takes for the given steps to all be hit.
   *
   * This function does not take the future BPM into account.
   * If you need to account for BPM, use `stepsToSecs` instead.
   * @param targetStep The step value to calculate with.
   * @param isFixedStep If true, calculation will assume `targetStep` is not being calculated as in "after `targetStep` steps", but rather as in "time until `targetStep` is hit".
   * @return The amount of seconds as a float.
   */
  inline public function stepsToSecs_simple(targetStep:Int, isFixedStep:Bool = false):Float
  {
    final playbackRate:Single = PlayState.instance != null ? PlayState.instance.playbackRate : 1;

    return ((Conductor.stepCrochet * (isFixedStep ? targetStep : curStep + targetStep)) / 1000) / playbackRate;
  }

  public function updateSection():Void
  {
    if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
    while (curStep >= stepsToDo)
    {
      curSection++;
      var beats:Float = getBeatsOnSection();
      stepsToDo += Math.round(beats * 4);
      Conductor.sectionHit.dispatch();
    }
  }

  public function rollbackSection():Void
  {
    if (curStep < 0) return;

    var lastSection:Int = curSection;
    curSection = 0;
    stepsToDo = 0;
    for (i in 0...PlayState.SONG.getSongData('notes').length)
    {
      if (PlayState.SONG.getSongData('notes')[i] != null)
      {
        stepsToDo += Math.round(getBeatsOnSection() * 4);
        if (stepsToDo > curStep) break;

        curSection++;
      }
    }

    if (curSection > lastSection) Conductor.sectionHit.dispatch();
  }

  public function updateBeat():Void
  {
    curBeat = Math.floor(curStep / 4);
    curDecBeat = curDecStep / 4;
  }

  public function updateCurStep():Void
  {
    var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

    var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
    curDecStep = lastChange.stepTime + shit;
    curStep = Math.floor(lastChange.stepTime) + Math.floor(shit);
  }

  public function getBeatsOnSection()
  {
    var val:Null<Float> = 4;
    if (PlayState.SONG != null
      && PlayState.SONG.getSongData('notes')[curSection] != null) val = PlayState.SONG.getSongData('notes')[curSection].sectionBeats;
    return val == null ? 4 : val;
  }
}

class Conductor
{
  public static var ROWS_PER_BEAT:Int = 48;
  // its 48 in ITG but idk because FNF doesnt work w/ note rows
  public static var ROWS_PER_MEASURE:Int = ROWS_PER_BEAT * 4;

  public static var bpm(default, set):Float = 100;
  public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
  public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
  public static var songPosition:Float = 0;
  public static var offset:Float = 0;

  public static var beatHit:FlxSignal = new FlxSignal();
  public static var stepHit:FlxSignal = new FlxSignal();
  public static var sectionHit:FlxSignal = new FlxSignal();

  // public static var safeFrames:Int = 10;
  public static var safeZoneOffset:Float = 0; // is calculated in create(), is safeFrames in milliseconds

  public static var bpmChangeMap:Array<BPMChangeEvent> = [];

  inline public static function beatToNoteRow(beat:Float):Int
  {
    return Math.round(beat * Conductor.ROWS_PER_BEAT);
  }

  inline public static function noteRowToBeat(row:Float):Float
  {
    return row / Conductor.ROWS_PER_BEAT;
  }

  public static function timeSinceLastBPMChange(time:Float):Float
  {
    var lastChange = getBPMFromSeconds(time);
    return time - lastChange.songTime;
  }

  public static function getBeatSinceChange(time:Float):Float
  {
    var lastBPMChange = getBPMFromSeconds(time);
    return (time - lastBPMChange.songTime) / (lastBPMChange.stepCrochet * 4);
  }

  public static function getCrotchetAtTime(time:Float)
  {
    var lastChange = getBPMFromSeconds(time);
    return lastChange.stepCrochet * 4;
  }

  public static function getBPMFromSeconds(time:Float)
  {
    var lastChange:BPMChangeEvent =
      {
        stepTime: 0,
        songTime: 0,
        bpm: bpm,
        stepCrochet: stepCrochet
      }
    for (i in 0...Conductor.bpmChangeMap.length)
    {
      if (time >= Conductor.bpmChangeMap[i].songTime) lastChange = Conductor.bpmChangeMap[i];
      else
        break;
    }
    return lastChange;
  }

  public static function getBPMFromStep(step:Float):BPMChangeEvent
  {
    var lastChange:BPMChangeEvent =
      {
        stepTime: 0,
        songTime: 0,
        bpm: bpm,
        stepCrochet: stepCrochet
      }
    for (i in 0...Conductor.bpmChangeMap.length)
    {
      if (step >= Conductor.bpmChangeMap[i].stepTime) lastChange = Conductor.bpmChangeMap[i];
      else
        break;
    }

    return lastChange;
  }

  public static function beatToSeconds(beat:Float):Float
  {
    var step = beat * 4;
    var lastChange = getBPMFromStep(step);
    return lastChange.songTime + ((step - lastChange.stepTime) / (lastChange.bpm / 60) / 4) * 1000; // TODO: make less shit and take BPM into account PROPERLY
  }

  public static function getStep(time:Float)
  {
    var lastChange = getBPMFromSeconds(time);
    return lastChange.stepTime + (time - lastChange.songTime) / lastChange.stepCrochet;
  }

  public static function getStepRounded(time:Float)
  {
    var lastChange = getBPMFromSeconds(time);
    return lastChange.stepTime + Math.floor(time - lastChange.songTime) / lastChange.stepCrochet;
  }

  public static function getBeat(time:Float)
  {
    return getStep(time) / 4;
  }

  public static function getBeatRounded(time:Float):Int
  {
    return Math.floor(getStepRounded(time) / 4);
  }

  // Troll Engine styled mapBPMChanges
  public static function mapBPMChanges(song:Song)
  {
    bpmChangeMap = [];

    var curBPM:Float = song.getSongData('bpm');
    var totalSteps:Int = 0;
    var totalPos:Float = 0;

    inline function pushChange(newBPM:Float)
    {
      var event:BPMChangeEvent =
        {
          stepTime: totalSteps,
          songTime: totalPos,
          bpm: newBPM,
          stepCrochet: calculateCrochet(newBPM) / 4
        };
      bpmChangeMap.push(event);
      curBPM = newBPM;
    }

    var notes:Array<SwagSection> = song.getSongData('notes');
    var firstSec = notes[0];
    if (firstSec == null || !firstSec.changeBPM) pushChange(song.getSongData('bpm'));

    for (section in notes)
    {
      if (section.changeBPM) pushChange(section.bpm);

      var deltaSteps:Int = Math.round(sectionBeats(section) * 4);
      totalSteps += deltaSteps;
      totalPos += (15000 * deltaSteps) / curBPM;
    }
  }

  static function sectionBeats(section:SwagSection):Float
  {
    var beats:Null<Float> = (section == null) ? null : section.sectionBeats;
    return (beats == null) ? 4 : section.sectionBeats;
  }

  static function getSectionBeats(song:SwagSong, section:Int)
  {
    sectionBeats(song.notes[section]);
  }

  inline public static function calculateCrochet(bpm:Float)
  {
    return 60000 / bpm; // (60 / bpm) * 1000;
  }

  public static function set_bpm(newBPM:Float):Float
  {
    if (bpm == newBPM) return bpm;

    crochet = calculateCrochet(newBPM);
    stepCrochet = crochet / 4;
    return bpm = newBPM;
  }
}
