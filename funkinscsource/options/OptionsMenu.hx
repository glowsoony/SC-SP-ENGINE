package options;

import flixel.FlxSubState;
import states.editors.content.Prompt;
import states.editors.content.*;

// Work in progress

enum OptionTypes
{
  INT;
  FLOAT;
  KEYBIND;
  STRING;
  LINK;
  ARRAY;
}

class OptionsMenu extends MusicBeatSubState implements PsychUIEventHandler.PsychUIEvent
{
  public static var isInPause:Bool = false;

  public var window:PsychUIWindow = null;
  public var box:PsychUIBox = null;
  public var noteKeyBox:PsychUIBox = null;

  public var fileDialog:FileDialogHandler = new FileDialogHandler();

  public function new()
  {
    super();
    add(window = new PsychUIWindow(0, 0));
    window.add(box = new PsychUIBox(50, 40, 720, 640, ['Gameplay', 'Visuals', 'Graphics', 'Controls', 'Misc']));
    box.canMove = false;
    window.add(noteKeyBox = new PsychUIBox(650, 60, 330, 300, ['Key Binds', 'Note Options']));
    noteKeyBox.minimizeOnFocusLost = true;
    noteKeyBox.canMove = false;
    noteKeyBox.isMinimized = true;
    noteKeyBox.bg.visible = false;

    ClientPrefs.saveSettings();

    buildGameplaySettings();
    buildNoteColorSettings();
  }

  override public function create()
  {
    super.create();
    FlxG.mouse.visible = true;
  }

  function updatenoteKeyBoxBg()
  {
    if (noteKeyBox.selectedTab != null)
    {
      var menu = noteKeyBox.selectedTab.menu;
      noteKeyBox.bg.x = noteKeyBox.x + noteKeyBox.selectedIndex * (noteKeyBox.width / noteKeyBox.tabs.length);
      noteKeyBox.bg.setGraphicSize(menu.width, menu.height + 21);
      noteKeyBox.bg.updateHitbox();
    }
  }

  public var lastFocus:PsychUIInputText;

  override public function update(elapsed:Float)
  {
    if (!fileDialog.completed)
    {
      lastFocus = PsychUIInputText.focusOn;
      return;
    }
    if (!FlxG.mouse.visible) FlxG.mouse.visible = true;
    super.update(elapsed);

    if (controls.BACK)
    {
      ClientPrefs.saveSettings();
      MusicBeatState.switchState(new states.MainMenuState());
    }
  }

  override function destroy()
  {
    ClientPrefs.loadPrefs();
    ClientPrefs.keybindSaveLoad();
    super.destroy();
  }

  var downScroll:PsychUICheckBox;
  var middleScroll:PsychUICheckBox;
  var ghostTapping:PsychUICheckBox;
  var disableResetButton:PsychUICheckBox;

  public function buildGameplaySettings()
  {
    final settings = box.getTab('Gameplay').menu;
    var objX = 10;
    var objY = 25;

    downScroll = window.createCheckBox(objX, objY, "Down Scroll", 100, null, ClientPrefs.data.downScroll);
    downScroll.onClick = function() {
      ClientPrefs.data.downScroll = downScroll.checked;
    };
    settings.add(downScroll);
    settings.add(window.createText(downScroll.x, downScroll.y + 20, 100, 'If checked, notes go Down instead of Up, simple enough.', 10, "left"));

    middleScroll = window.createCheckBox(objX, objY + 100, "Middle Scroll", 100, null, ClientPrefs.data.middleScroll);
    middleScroll.onClick = function() {
      ClientPrefs.data.middleScroll = middleScroll.checked;
    };
    middleScroll.checked = ClientPrefs.data.middleScroll;
    settings.add(middleScroll);
    settings.add(window.createText(middleScroll.x, middleScroll.y + 20, 100, 'If checked, your notes get centered', 10, 'left'));

    ghostTapping = window.createCheckBox(objX, middleScroll.y + 80, "Ghost Tapping", 100, null, ClientPrefs.data.downScroll);
    ghostTapping.onClick = function() {
      ClientPrefs.data.ghostTapping = ghostTapping.checked;
    };
    settings.add(ghostTapping);
    settings.add(window.createText(ghostTapping.x, ghostTapping.y + 20, 100,
      "If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.", 10, "left"));

    disableResetButton = window.createCheckBox(ghostTapping.x, ghostTapping.y + 120, 'Disable Reset Button', 100, null, ClientPrefs.data.noReset);
    disableResetButton.onClick = function() {
      ClientPrefs.data.noReset = disableResetButton.checked;
    }
    settings.add(disableResetButton);
    settings.add(window.createText(disableResetButton.x, disableResetButton.y + 20, 100, "If checked, pressing Reset won't do anything.", 10, "left"));
  }

  var noteColors:PsychUINoteColors = null;

  public function buildNoteColorSettings()
  {
    final tab = noteKeyBox.getTab('Note Options');
    final tab_group = tab.menu;
    var btnX = tab.x - box.x;
    var btnY = 1;
    var btnWid = Std.int(tab.width);

    var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '   Note Colors...', function() {
      openSubState(new options.NotesColorSubState());

      noteKeyBox.isMinimized = true;
      noteKeyBox.bg.visible = false;

      // openSubState(new BasePrompt(500, 160, 'Note Color Option', function(state:BasePrompt) {
      //   var btn:PsychUIButton = new PsychUIButton(state.bg.x + state.bg.width - 40, state.bg.y, 'X', state.close, 40);
      //   btn.cameras = state.cameras;
      //   btn.disabled = !noteColors.disabled;
      //   state.add(btn);

      //   var btnY = 390;
      //   var btn:PsychUIButton = new PsychUIButton(0, btnY, 'Note Colors', function() {
      //     noteColors = new PsychUINoteColors(40, 50);
      //     noteColors.cameras = state.cameras;
      //     noteColors.screenCenter(XY);
      //     state.add(noteColors);
      //   });
      //   btn.screenCenter(X);
      //   btn.x -= 180;
      //   btn.cameras = state.cameras;
      //   state.add(btn);

      //   // var btn:PsychUIButton = new PsychUIButton(0, btnY, 'Note Colors', function() {
      //   //   noteColors = new PsychUINoteColors(40, 50);
      //   //   noteColors.cameras = states.cameras;
      //   //   noteColors.screenCenter(XY);
      //   //   state.add(noteColors);
      //   // });
      //   // btn.screenCenter(X);
      //   // btn.x += 180;
      //   // btn.cameras = state.cameras;
      //   // state.add(btn);
      // }));
    }, btnWid);
    btn.text.alignment = LEFT;
    tab_group.add(btn);
    // noteColors = new PsychUINoteColors(50, 40);
    // noteColors.forEachAlive(function(sprite:FlxSprite) {
    //   if (sprite != null && sprite.exists)
    //   {
    //     sprite.setGraphicSize(40, 40);
    //   }
    // });
    // colorSettings.add(noteColors);
  }

  public function UIEvent(id:String, sender:Dynamic)
  {
    switch (id)
    {
      case PsychUIBox.CLICK_EVENT:
        if (sender == noteKeyBox) updatenoteKeyBoxBg();

      case PsychUIBox.MINIMIZE_EVENT:
        if (sender == noteKeyBox)
        {
          noteKeyBox.bg.visible = !noteKeyBox.isMinimized;
          updatenoteKeyBoxBg();
        }
    }
  }
}
