package scfunkin.utils;

import Type;

class ReflectUtil
{
  public static function getClassFields(cls:Class<Dynamic>):Array<String>
    return Type.getClassFields(cls);

  public static function getClassFieldsOf(obj:Dynamic):Array<String>
    return Type.getClassFields(Type.getClass(obj));

  public static function getInstanceFields(cls:Class<Dynamic>):Array<String>
    return Type.getInstanceFields(cls);

  public static function getInstanceFieldsOf(obj:Dynamic):Array<String>
    return Type.getInstanceFields(Type.getClass(obj));

  public static function getClassName(cls:Class<Dynamic>):String
    return Type.getClassName(cls);

  public static function getClassNameOf(obj:Dynamic):String
    return Type.getClassName(Type.getClass(obj));

  public static function getAnonymousFieldsOf(obj:Dynamic):Array<String>
    return Reflect.fields(obj);

  public static function getAnonymousField(obj:Dynamic, name:String):Dynamic
    return Reflect.field(obj, name);

  public static function setAnonymousField(obj:Dynamic, name:String, value:Dynamic)
    Reflect.setField(obj, name, value);

  public static function hasAnonymousField(obj:Dynamic, name:String):Bool
    return Reflect.hasField(obj, name);

  public static function copyAnonymousFieldsOf(obj:Dynamic):Dynamic
    return Reflect.copy(obj);

  public static function deleteAnonymousField(obj:Dynamic, name:String):Bool
    return Reflect.deleteField(obj, name);

  public static function compareValues(valueA:Dynamic, valueB:Dynamic):Int
    return Reflect.compare(valueA, valueB);

  public static function isObject(value:Dynamic):Bool
    return Reflect.isObject(value);

  public static function isFunction(value:Dynamic):Bool
    return Reflect.isFunction(value);

  public static function isEnumValue(value:Dynamic):Bool
    return Reflect.isEnumValue(value);

  public static function getProperty(obj:Dynamic, name:String):Dynamic
    return Reflect.getProperty(obj, name);

  public static function setProperty(obj:Dynamic, name:String, value:Dynamic):Void
    return Reflect.setProperty(obj, name, value);

  public static function compareMethods(functionA:Dynamic, functionB:Dynamic):Bool
    return Reflect.compareMethods(functionA, functionB);

  public static function hasFieldNamed(object:Dynamic, fieldName:String):Bool
  {
    var c:Class<Dynamic> = Type.getClass(object);
    while (c != null)
    {
      if (Type.getInstanceFields(c).indexOf(fieldName) >= 0 || Type.getClassFields(c).indexOf(fieldName) >= 0)
      {
        return true;
      }

      c = Type.getSuperClass(c);
    }

    return false;
  }

  /**
   * [I love troll-engine <3 (function form Troll-Engine)](https://github.com/riconuts/FNF-Troll-Engine/blob/content-v3-new/source/funkin/CoolUtil.hx#L61)
   *
   * A way to transform a Dynamic structure content into a Map.
   * @param st
   * @return Map<String, Dynamic>
   */
  public static function structureToMap(st:Dynamic):Map<String, Dynamic>
  {
    return [
      for (k in Reflect.fields(st))
      {
        k => Reflect.field(st, k);
      }
    ];
  }

  /**
   * Exclusive function for dynamic material.
   * Handles a bit of custom data for old to new if needed.
   *
   * @param object the dynamic meterial is searches in.
   * @param searchField the field you want to use from the dynamic matieral.
   * @param certainFields used in case you have in original fields to replace. without original [options] | with original [options] + [orignaloptions] (together)
   * @param defaultFields a map that determins the default field set.
   * @param hasOriginalFields
   */
  public static function searchField(object:Dynamic, searchField:String, certainFields:CertainFields, defaultFields:Map<String, Dynamic>)
  {
    if (object == null || certainFields == null || certainFields.fields == null || defaultFields == null) return;

    if (certainFields.originalFields == null)
    {
      final fields:Array<String> = certainFields.fields;
      for (field in fields)
      {
        if (Reflect.hasField(object, field))
        {
          if (!Reflect.hasField(Reflect.field(object, searchField),
            field)) Reflect.setProperty(Reflect.field(object, searchField), field, Reflect.getProperty(object, field));
          Reflect.deleteField(object, field);
        }
        else
        {
          if (!Reflect.hasField(Reflect.field(object, searchField),
            field)) Reflect.setProperty(Reflect.field(object, searchField), field, defaultFields.get(field));
        }
      }
    }
    else
    {
      final fields:Array<String> = certainFields.fields;
      final originalFields:Array<String> = certainFields.originalFields;
      for (field in 0...fields.length)
      {
        if (Reflect.hasField(object, originalFields[field]))
        {
          if (!Reflect.hasField(Reflect.field(object, searchField),
            fields[field])) Reflect.setProperty(Reflect.field(object, searchField), fields[field], Reflect.getProperty(object, originalFields[field]));
          Reflect.deleteField(object, originalFields[field]);
        }
        else
        {
          if (!Reflect.hasField(Reflect.field(object, searchField),
            fields[field])) Reflect.setProperty(Reflect.field(object, searchField), fields[field], defaultFields.get(fields[field]));
        }
      }
    }
  }
}

typedef CertainFields =
{
  fields:Array<String>,
  originalFields:Array<String>
}
