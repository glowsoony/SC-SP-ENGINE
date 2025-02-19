package scfunkin.play.song;

import flixel.util.FlxSort;
import scfunkin.objects.note.Note.EventNote;

class SongEvents
{
  public static var events:Array<EventNote> = [];

  public var tempEvents:Array<EventNote> = [];
  public var tempEventsPushed:Array<String> = [];

  public var onEventPushed:EventNote->Void = null;
  public var onEventPushedUnique:EventNote->Void = null;
  public var onEventPushedUniquePost:EventNote->Void = null;
  public var onEventEarlyTrigger:EventNote->Float = null;
  public var onMakeEvent:EventNote->Void = null;

  public var onTempEventUsed:EventNote->Void = null;

  public function new() {}

  public function forEachEventPushed(func:String->Void)
  {
    for (eventName in tempEventsPushed)
      func(eventName);
  }

  public function makeEvent(event:Array<Dynamic>, i:Int)
  {
    final subEvent:EventNote =
      {
        time: event[0] + ClientPrefs.data.noteOffset,
        name: event[1][i][0],
        params: event[1][i][1],
      };
    if (onMakeEvent != null) onMakeEvent(subEvent);
    tempEvents.push(subEvent);
    eventPushed(subEvent);
    if (onEventPushed != null) onEventPushed(subEvent);
  }

  // called only once per different event (Used for precaching)
  public function eventPushed(event:EventNote)
  {
    if (onEventPushedUnique != null) onEventPushedUnique(event);
    if (tempEventsPushed.contains(event.name)) return;
    // called by every event with the same name
    if (onEventPushedUniquePost != null) onEventPushedUniquePost(event);
    tempEventsPushed.push(event.name);
  }

  public function eventEarlyTrigger(event:EventNote):Float
  {
    final returnedValue:Null<Float> = onEventEarlyTrigger != null ? onEventEarlyTrigger(event) : null;
    if (returnedValue != null && returnedValue != 0) return returnedValue;

    switch (event.name)
    {
      case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
        return 280; // Plays 280ms before the actual position
    }
    return 0;
  }

  public function applyEarlyTimeTrigger()
  {
    if (tempEvents.length > 1)
    {
      for (event in tempEvents)
        event.time -= eventEarlyTrigger(event);
      tempEvents.sort(function(a:EventNote, b:EventNote) return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time));
    }
  }

  public function lessThanCheck()
    if (tempEvents.length < 1) checkTempEvents();

  public function checkTempEvents()
  {
    while (tempEvents.length > 0)
    {
      var leEventTime:Float = tempEvents[0].time;
      if (Conductor.songPosition < leEventTime) return;
      triggerEvent(tempEvents[0].name, tempEvents[0].params, leEventTime);
      tempEvents.shift();
    }
  }

  public var onTriggerEvent:(String, Array<String>, Float) -> Void = null;

  public function triggerEvent(name:String, params:Array<String>, time:Float)
  {
    if (onTriggerEvent != null) onTriggerEvent(name, params, time);
  }
}
