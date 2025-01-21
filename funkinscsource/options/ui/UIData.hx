package options.ui;

class ArrayData
{
  public var name:String;
  public var text:String;
  public var list:Array<String>;
  public var width:Float;
  public var height:Float;
  public var defaultValue:String;
  public var arrowLOffset:Float;
  public var arrowROffset:Float;
  public var enabled:Bool;
  public var onChange:Void->Void;
}

class NumberData
{
  public var name:String;
  public var text:String;
  public var precision:Float;
  public var percentName:String;
  public var width:Float;
  public var height:Float;
  public var defaultValue:Float;
  public var arrowLOffset:Float;
  public var arrowROffset:Float;
  public var min:Float;
  public var max:Float;
  public var enabled:Bool;
  public var onChange:Void->Void;
}

class SliderData
{
  public var name:String;
  public var text:String;
  public var precision:Float;
  public var percentName:String;
  public var width:Float;
  public var height:Float;
  public var defaultValue:Float;
  public var onDrag:Float->Void;
  public var onReleased:Float->Void;
  public var onClick:Float->Void;
  public var enabled:Bool;
  public var onChange:Void->Void;
}

class ButtonData
{
  public var name:String;
  public var text:String;
  public var width:Float;
  public var height:Float;
  public var onClick:Void->Void;
  public var enabled:Bool;
  public var onChange:Void->Void;
}
