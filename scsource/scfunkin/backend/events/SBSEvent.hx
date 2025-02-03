package scfunkin.backend.events;

enum abstract SBS(String) to String from String
{
  var SECTION = "SECTION";
  var BEAT = "BEAT";
  var STEP = "STEP";
}

class SBSEvent
{
  public var callBack:Void->Void;
  public var sbsType:SBS = "STEP";
  public var position:Int = 0;

  public function new(position:Int, callBack:Void->Void, type:SBS = "STEP")
  {
    this.position = position;
    this.sbsType = checkEventType(type);
    this.callBack = callBack;
  }

  public static function checkEventType(type:SBS):SBS
  {
    final typeFound:String = type;
    switch (typeFound.toLowerCase())
    {
      case "section", "sec", "sect":
        return SECTION;
      case "step":
        return STEP;
      case "beat":
        return BEAT;
    }
    return null;
  }
}
