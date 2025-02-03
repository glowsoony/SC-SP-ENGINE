package scfunkin.backend.events;

class Event extends BaseEvent
{
  public function new(pos:Float = 0, ?duration:Float = 0, ?repeat:Bool = false, ?eased:Bool = false, ?target:Float = 0, ?startVal:Null<Float> = null,
      ?easeFunc:Float->Float)
  {
    super(pos, duration, repeat, eased, target, startVal, easeFunc);
    length = pos + duration;
  }

  override public function runEvent(curPos:Float)
  {
    this.curPos = curPos;
    if (onRunEvent != null) onRunEvent(this);
    if (repeat)
    {
      if (eased)
      {
        if (curPos < length)
        {
          var passed = curPos - pos;
          var change = endValue - startValue;
          value = scfunkin.utils.MathUtil.ease(easeFunction, passed, startValue, change, length);
          if (onProgress != null) onProgress(this, value, curPos);
          if (onCallback != null) onCallback(this, curPos);
        }
        else if (curPos >= length)
        {
          value = easeFunction(1) * endValue;
          if (onProgress != null) onProgress(this, value, curPos);
          if (onFinished != null) onFinished(this);
          completed = true;
        }
      }
      else
      {
        if (curPos <= length)
        {
          value = easeFunction((curPos - pos) / length);
          if (onProgress != null) onProgress(this, value, curPos);
          if (onCallback != null) onCallback(this, curPos);
        }
        else
        {
          progress = 1;
          if (onProgress != null) onProgress(this, value, curPos);
          if (onFinished != null) onFinished(this);
          completed = true;
        }
      }
    }
    else
    {
      if (onCallback != null) onCallback(this, curPos);
      if (onFinished != null) onFinished(this);
      if (onProgress != null) onProgress(this, value, curPos);
      completed = true;
    }
  }
}
