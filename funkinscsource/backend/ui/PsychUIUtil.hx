package backend.ui;

class PsychUIUtil
{
  public static function disableMembers(members:Array<FlxSprite> = null, disable:Bool = false)
  {
    if (members == null || members.length < 1) return;

    for (member in members)
    {
      if (!isUI(member))
      {
        if (Reflect.getProperty(member, 'disabled') != null) Reflect.setProperty(member, 'disabled', disable);
      }
      else
        Reflect.setProperty(member, 'disabled', disable);
    }
  }

  public static function isUI(member:Dynamic):Bool
  {
    return (Std.isOfType(member, PsychUIBox)
      || Std.isOfType(member, PsychUIButton)
      || Std.isOfType(member, PsychUICheckBox)
      || Std.isOfType(member, PsychUIDropDownMenu)
      || Std.isOfType(member, PsychUIInputText)
      || Std.isOfType(member, PsychUINumericStepper)
      || Std.isOfType(member, PsychUIRadioGroup)
      || Std.isOfType(member, PsychUISlider)
      || Std.isOfType(member, PsychUITab));
  }
}
