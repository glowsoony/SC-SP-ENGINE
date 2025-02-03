package scfunkin.backend.events;

class EventTimeline
{
  public var events:Array<BaseEvent> = [];
  public var parentPos:Float = 0;

  public function new() {}

  public function removeEvents(event:Array<BaseEvent>)
  {
    for (event in events)
      removeEvent(event);
  }

  public function removeEvent(event:BaseEvent)
  {
    if (events.contains(event))
    {
      events.remove(event);
      event.completed = true;
      event.ignore = true;
    }
  }

  public function addEvents(newEvents:Array<BaseEvent>)
  {
    for (event in newEvents)
      addEvent(event);
  }

  public function addEvent(event:BaseEvent)
  {
    if (event == null) return;
    event.parentTimeline = this;
    if (!events.contains(event))
    {
      events.push(event);
      events.sort((a, b) -> Std.int(a.pos - b.pos));
    }
  }

  public function updateEvents(parentPos:Float)
  {
    this.parentPos = parentPos;
    var toRemove:Array<BaseEvent> = [];
    for (event in events)
    {
      if (event.completed) toRemove.push(event);

      if (event.ignore || event.completed) continue;

      if (parentPos >= event.pos) event.runEvent(parentPos);
      else
        break;
    }

    for (pendingEvent in toRemove)
      removeEvent(pendingEvent);
  }
}
