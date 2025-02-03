package scfunkin.backend.data.event;

import haxe.ds.Either;
import flixel.util.typeLimit.OneOfTwo;

abstract OneOfSix<T1, T2, T3, T4, T5, T6>(Dynamic) from T1 from T2 from T3 from T4 from T5 from T6 to T1 to T2 to T3 to T4 to T5 to T6 {}
typedef EventValueType = OneOfSix<Array<String>, Int, Float, Dynamic, String, FlxColor>;

enum abstract PropertyType(String) from String to String
{
  /**
   * Spliting string property.
   */
  var ARRAY = 'array';

  /**
   * Int number property.
   */
  var INT = 'int';

  /**
   * Floating point number property.
   */
  var FLOAT = 'float';

  /**
   * Dynamic property.
   */
  var DYNAMIC = 'dynamic';

  /**
   * Self / String property.
   */
  var STRING = 'string';

  /**
   *  Color Property.
   */
  var COLOR = 'color';
}

// typedef SplitProperty =
// {
//   var property:PtopertyType;
//   var splitIndex:String;
// }

typedef EventValue =
{
  var type:PropertyType;
  var value:String;
  @:optional var description:String;
  @:optional var splitIndex:String;
  @:optional var name:String;
  @:optional var defaultValue:Dynamic;
}

typedef EventJson =
{
  var name:String;
  var values:Array<EventValue>;
  @:optional var time:Float;
}

class EventValueStorage
{
  public var eventType:PropertyType;
  public var trueValue:EventValueType;
  public var value:String;
  public var description:String;
  public var name:String;
  public var defaultValue:EventValueType;

  public function convertToString(type:EventValueType):String
  {
    if (type is Array)
    {
      final array:Array<String> = type;
      final call:String = array[0];
      array.shift();
      var value:String = "";
      for (item in array)
        value += (array.length > 0 ? ", " : "") + item;
      return call + value;
    }
    return Std.string(type);
  }
}

class EventData
{
  public var name:String = "";
  public var time:Float = 0;
  public var data:EventJson = null;
  public var length(get, never):Int;
  public var values:Array<EventValue> = [];
  public var setValues:Array<String> = [];

  public function convertSetValues():Array<Dynamic>
  {
    var finalValues:Array<Dynamic> = [];
    for (index => value in setValues)
      finalValues[index] = getTypeFromValue(index);
    return finalValues;
  }

  function get_length():Int
  {
    if (data == null) return 0;
    return data.values.length;
  }

  public function new(name:String, time:Float)
  {
    this.name = name;
    this.time = time;
    this.data = loadEvent(name);
    values = data?.values ?? [];
  }

  public function loadEvent(name:String):EventJson
  {
    var data:EventJson = null;

    if (Paths.fileExists('custom_events/$name.json', TEXT))
    {
      final rawFile:String = Paths.getTextFromFile('custom_events/$name.json');
      if (rawFile != null && rawFile.length > 0)
      {
        try
        {
          final event:EventJson = tjson.TJSON.parse(rawFile);
          if (event != null)
          {
            data =
              {
                name: event.name,
                values: event.values
              }
          }
        }
      }
    }
    return data;
  }

  public function getTypeFromValue(value:OneOfTwo<Int, String>):Dynamic
  {
    if (values == null || values.length <= 0) return null;

    if (value is String)
    {
      for (i in 0...values.length)
      {
        final eValue:EventValue = values[i];
        if (eValue.name == value) return getTypeValue(eValue.type, eValue.value, eValue.splitIndex != null ? eValue.splitIndex : null);
      }
      return null;
    }
    else if (value is Int)
    {
      final eValue:EventValue = values[value];
      if (eValue == null) return null;
      return getTypeValue(eValue.type, eValue.value, eValue.splitIndex != null ? eValue.splitIndex : null);
    }
    return null;
  }

  public function getTypeValue(property:PropertyType, value:String, ?index:String = null):EventValueType
  {
    if (value == null || property == null) return null;
    if (property == ARRAY && index == null) index = ',';

    switch (property)
    {
      case ARRAY:
        return value.split(index);
      case INT:
        return Std.parseInt(value);
      case FLOAT:
        return Std.parseFloat(value);
      case DYNAMIC:
        final dynamicValue:Dynamic = cast value;
        return dynamicValue;
      case STRING:
        return Std.string(value);
      case COLOR:
        return scfunkin.utils.CoolUtil.colorFromString(value);
    }
  }

  public function toStringValues():Array<String>
  {
    var newValues:Array<String> = [];
    for (value in values)
    {
      newValues.push(value.value);
    }
    return newValues;
  }
}
