package backend.ui;

class PsychUIWindow extends FlxSpriteGroup
{
  public var disableBoxes(default, set):Bool = false;

  function set_disableBoxes(value:Bool):Bool
  {
    disableBoxes = value;
    for (box in getBoxes())
      box.disabled = disableBoxes;
    itemsToEOD[0].item = disableBoxes;
    return disableBoxes;
  }

  public var disableButtons(default, set):Bool = false;

  function set_disableButtons(value:Bool):Bool
  {
    disableButtons = value;
    for (button in getButtons())
      button.disabled = disableButtons;
    itemsToEOD[1].item = disableButtons;
    return disableButtons;
  }

  public var disableInputs(default, set):Bool = false;

  function set_disableInputs(value:Bool):Bool
  {
    disableInputs = value;
    for (input in getInputs())
      input.disabled = disableInputs;
    itemsToEOD[2].item = disableInputs;
    return disableInputs;
  }

  public var disableCheckBoxes(default, set):Bool = false;

  function set_disableCheckBoxes(value:Bool):Bool
  {
    disableCheckBoxes = value;
    for (box in getCheckBoxes())
      box.disabled = disableCheckBoxes;
    itemsToEOD[3].item = disableCheckBoxes;
    return disableCheckBoxes;
  }

  public var disableNumSteppers(default, set):Bool = false;

  function set_disableNumSteppers(value:Bool):Bool
  {
    disableNumSteppers = value;
    for (stepper in getNumSteppers())
      stepper.disabled = disableNumSteppers;
    itemsToEOD[4].item = disableNumSteppers;
    return disableNumSteppers;
  }

  public var disableDropDowns(default, set):Bool = false;

  function set_disableDropDowns(value:Bool):Bool
  {
    disableDropDowns = value;
    for (dropDown in getDropDowns())
      dropDown.disabled = disableDropDowns;
    itemsToEOD[5].item = disableDropDowns;
    return disableDropDowns;
  }

  public var disableRadioGroups(default, set):Bool = false;

  function set_disableRadioGroups(value:Bool):Bool
  {
    disableRadioGroups = value;
    for (radio in getRadioGroups())
      radio.disabled = disableRadioGroups;
    itemsToEOD[6].item = disableRadioGroups;
    return disableRadioGroups;
  }

  public var disableSliders(default, set):Bool = false;

  function set_disableSliders(value:Bool):Bool
  {
    disableSliders = value;
    for (slider in getSliders())
      slider.disabled = disableSliders;
    itemsToEOD[7].item = disableSliders;
    return disableSliders;
  }

  public var disableTabs(default, set):Bool = false;

  function set_disableTabs(value:Bool):Bool
  {
    disableTabs = value;
    for (tab in getTabs())
      tab.disabled = disableTabs;
    itemsToEOD[8].item = disableTabs;
    return disableTabs;
  }

  public var itemsToEOD:Array<{item:Bool, name:String}> = [
    {
      item: false,
      name: 'disableBoxes'
    },
    {
      item: false,
      name: 'disableButtons'
    },
    {
      item: false,
      name: 'disableInputs'
    },
    {
      item: false,
      name: 'disableCheckBoxes'
    },
    {
      item: false,
      name: 'disableNumSteppers'
    },
    {
      item: false,
      name: 'disableDropDowns'
    },
    {
      item: false,
      name: 'disableRadioGroups'
    },
    {
      item: false,
      name: 'disableSliders'
    },
    {
      item: false,
      name: 'disableTabs'
    }
  ];

  public function new(x:Float, y:Float)
  {
    super(x, y);
    itemsToEOD[0].item = disableBoxes;
    itemsToEOD[1].item = disableButtons;
    itemsToEOD[2].item = disableInputs;
    itemsToEOD[3].item = disableCheckBoxes;
    itemsToEOD[4].item = disableNumSteppers;
    itemsToEOD[5].item = disableDropDowns;
    itemsToEOD[6].item = disableRadioGroups;
    itemsToEOD[7].item = disableSliders;
    itemsToEOD[8].item = disableTabs;
  }

  public function close()
  {
    for (disableItem in itemsToEOD)
      Reflect.setProperty(this, disableItem.name, true);
  }

  public function open()
  {
    for (enableItem in itemsToEOD)
      Reflect.setProperty(this, enableItem.name, false);
  }

  public function getBoxes():Array<PsychUIBox>
  {
    final boxList:Array<PsychUIBox> = [];
    for (box in members)
      if (Std.isOfType(box, PsychUIBox))
      {
        final boxObject:PsychUIBox = cast box;
        boxList.push(boxObject);
      }
    return boxList;
  }

  public function getButtons():Array<PsychUIButton>
  {
    final buttonList:Array<PsychUIButton> = [];
    for (button in members)
      if (Std.isOfType(button, PsychUIButton))
      {
        final buttonObject:PsychUIButton = cast button;
        buttonList.push(buttonObject);
      }
    return buttonList;
  }

  public function getCheckBoxes():Array<PsychUICheckBox>
  {
    final checkBoxList:Array<PsychUICheckBox> = [];
    for (checkBox in members)
      if (Std.isOfType(checkBox, PsychUICheckBox))
      {
        final checkBoxObject:PsychUICheckBox = cast checkBox;
        checkBoxList.push(checkBoxObject);
      }
    return checkBoxList;
  }

  public function getDropDowns():Array<PsychUIDropDownMenu>
  {
    final dropDownList:Array<PsychUIDropDownMenu> = [];
    for (dropDown in members)
      if (Std.isOfType(dropDown, PsychUIDropDownMenu))
      {
        final dropDownObject:PsychUIDropDownMenu = cast dropDown;
        dropDownList.push(dropDownObject);
      }
    return dropDownList;
  }

  public function getInputs():Array<PsychUIInputText>
  {
    final inputsList:Array<PsychUIInputText> = [];
    for (input in members)
      if (Std.isOfType(input, PsychUIInputText))
      {
        final inputObject:PsychUIInputText = cast input;
        inputsList.push(inputObject);
      }
    return inputsList;
  }

  public function getNumSteppers():Array<PsychUINumericStepper>
  {
    final steppersList:Array<PsychUINumericStepper> = [];
    for (stepper in members)
      if (Std.isOfType(stepper, PsychUINumericStepper))
      {
        final stepperObject:PsychUINumericStepper = cast stepper;
        steppersList.push(stepperObject);
      }
    return steppersList;
  }

  public function getRadioGroups():Array<PsychUIRadioGroup>
  {
    final radiosList:Array<PsychUIRadioGroup> = [];
    for (radio in members)
      if (Std.isOfType(radio, PsychUIRadioGroup))
      {
        final radioObject:PsychUIRadioGroup = cast radio;
        radiosList.push(radioObject);
      }
    return radiosList;
  }

  public function getSliders():Array<PsychUISlider>
  {
    final slidersList:Array<PsychUISlider> = [];
    for (slider in members)
      if (Std.isOfType(slider, PsychUISlider))
      {
        final sliderObject:PsychUISlider = cast slider;
        slidersList.push(sliderObject);
      }
    return slidersList;
  }

  public function getTabs():Array<PsychUITab>
  {
    final tabsList:Array<PsychUITab> = [];
    for (tab in members)
      if (Std.isOfType(tab, PsychUITab))
      {
        final tabObject:PsychUITab = cast tab;
        tabsList.push(tabObject);
      }
    return tabsList;
  }

  public function createText(x:Float, y:Float, width:Float, text:String, size:Int, alignment:String):FlxText
  {
    final newText:FlxText = new FlxText(x, y, width, text, size);
    newText.alignment = alignment;
    return newText;
  }

  public function createBox(x:Float, y:Float, width:Int, height:Int, tabs:Array<String> = null):PsychUIBox
  {
    final newBox:PsychUIBox = new PsychUIBox(x, y, width, height, tabs);
    return newBox;
  }

  public function createButton(x:Float, y:Float, label:String, onClick:Void->Void, wid:Int, hei:Int):PsychUIButton
  {
    final newBox:PsychUIButton = new PsychUIButton(x, y, label, onClick, wid, hei);
    return newBox;
  }

  public function createCheckBox(x:Float, y:Float, label:String, textWid:Int = 100, ?onClick:Void->Void, ?checked:Bool = false):PsychUICheckBox
  {
    final newCheckBox:PsychUICheckBox = new PsychUICheckBox(x, y, label, textWid, onClick);
    newCheckBox.checked = checked;
    return newCheckBox;
  }

  public function createDropDownMenu(x:Float, y:Float, list:Array<String>, callback:Int->String->Void, width:Float):PsychUIDropDownMenu
  {
    final newDropDownMenu:PsychUIDropDownMenu = new PsychUIDropDownMenu(x, y, list, callback, width);
    return newDropDownMenu;
  }

  public function createInputText(x:Float, y:Float, wid:Int, text:String, size:Int):PsychUIInputText
  {
    final newInputText:PsychUIInputText = new PsychUIInputText(x, y, wid, text, size);
    return newInputText;
  }

  public function createNumericStepper(x:Float, y:Float, step:Float, defValue:Float, min:Float, max:Float, decimals:Int, wid:Int,
      isPercent:Bool):PsychUINumericStepper
  {
    final newNumStep:PsychUINumericStepper = new PsychUINumericStepper(x, y, step, defValue, min, max, decimals, wid, isPercent);
    return newNumStep;
  }

  public function createRadioGroup(x:Float, y:Float, labels:Array<String>, space:Float, maxItems:Int, isHorizontal:Bool = false,
      textWidth:Int):PsychUIRadioGroup
  {
    final newRadioGroup:PsychUIRadioGroup = new PsychUIRadioGroup(x, y, labels, space, maxItems, isHorizontal, textWidth);
    return newRadioGroup;
  }

  public function createSlider(x:Float, y:Float, callback:Float->Void, def:Float, min:Float, max:Float, wid:Float, mainColor:FlxColor,
      handleColor:FlxColor):PsychUISlider
  {
    final newSlider:PsychUISlider = new PsychUISlider(x, y, callback, def, min, max, wid, mainColor, handleColor);
    return newSlider;
  }

  public function createTab(name:String):PsychUITab
  {
    final newTab:PsychUITab = new PsychUITab(name);
    return newTab;
  }
}
