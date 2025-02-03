package scfunkin.backend.data.note;

import scfunkin.objects.note.Note;

typedef NoteData =
{
  property:String,
  value:Dynamic
}

typedef NoteTypeData =
{
  noteData:Array<NoteData>,
  extraNoteData:Array<NoteData>
}

class NoteTypeConfigJson
{
  public static var noteTypeData:Map<String, NoteTypeData> = new Map<String, NoteTypeData>();

  public static function clearNoteTypeData()
    noteTypeData.clear();

  public static function loadNoteTypeJson(name:String):NoteTypeData
  {
    final noteTypeFile = tjson.TJSON.parse(Paths.getTextFromFile('custom_notetypes/$name.json'));
    if (noteTypeData.exists(name)) return noteTypeData.get(name);
    if (noteTypeFile == null) return null;
    var data:NoteTypeData =
      {
        noteData: noteTypeFile.noteData,
        extraNoteData: noteTypeFile.extraNoteData
      }
    return data;
  }

  public static function applyNoteTypeJson(note:Note, name:String)
  {
    var data:NoteTypeData = loadNoteTypeJson(name);
    if (data == null) return;

    if (data.noteData != null)
    {
      for (noteData in data.noteData)
        setProperty(note, noteData.property, noteData.value);
    }

    if (data.extraNoteData != null)
    {
      for (extraNoteData in data.extraNoteData)
      {
        if (note.extraData == null) continue;

        if (!note.extraData.exists(extraNoteData.property)) note.extraData.set(extraNoteData.property, extraNoteData.value);
        else
          note.extraData[extraNoteData.property] = extraNoteData.value;
      }
    }
  }

  public static function getProperty(obj:Note, variable:String)
    return Reflect.getProperty(obj, variable);

  public static function setProperty(obj:Note, variable:String, value:Dynamic)
    return Reflect.setProperty(obj, variable, value);
}
