package scfunkin.debug;

import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.Lib;
import openfl.system.System;
import haxe.Int64;
#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end
import scfunkin.backend.data.save.ClientPrefs;
import scfunkin.utils.*;

class FPSCounter extends TextField
{
  /**
    The current frame rate, expressed using frames-per-second
  **/
  public var currentFPS(default, null):Int;

  /**
    The current memory usage.
  **/
  public var memoryMegas:Dynamic = 0;

  public var taskMemoryMegas:Dynamic = 0;

  public var memoryUsage:String = '';

  @:noCompletion private var cacheCount:Int;
  @:noCompletion private var currentTime:Float;
  @:noCompletion private var times:Array<Float>;

  public static var stringTimeToReturn:String = '';

  var deltaTimeout:Float = 0.0;

  public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
  {
    super();

    this.x = x;
    this.y = y;

    currentFPS = 0;
    selectable = false;
    mouseEnabled = false;
    defaultTextFormat = new TextFormat("_sans", 14, color);
    autoSize = LEFT;
    multiline = true;
    text = "FPS: ";

    currentFPS = 0;

    times = [];

    width = 680;

    height = 180;
  }

  // Event Handlers

  @:noCompletion
  private override function __enterFrame(deltaTime:Float):Void
  {
    final now:Float = haxe.Timer.stamp() * 1000;
    times.push(now);
    while (times[0] < now - 1000)
      times.shift();

    // prevents the overlay from updating every frame, why would you need to anyways @crowplexus
    if (deltaTimeout < 50)
    {
      deltaTimeout += deltaTime;
      return;
    }

    currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate; // Fix The FRAMES STAYING STATIC

    updateText();
    deltaTimeout = 0.0;
  }

  public dynamic function updateText():Void
  {
    // setup the date
    if (ClientPrefs.data.dateDisplay) DateSetup.initDate();

    text = "FPS: ";

    /*memoryMegas = Int64.make(0, System.totalMemory);
      taskMemoryMegas = Int64.make(0, MemoryUtil.getMemoryfromProcess()); */

    memoryMegas = MemoryUtil.currentMemUsage();
    if (taskMemoryMegas < memoryMegas) taskMemoryMegas = memoryMegas;

    var stateText:String = '\nState: ${Type.getClassName(Type.getClass(FlxG.state))}';
    var substateText:String = '\nSubState: ${Type.getClassName(Type.getClass(FlxG.state.subState))}';

    textColor = 0xFFFFFFFF;
    if (currentFPS < FlxG.updateFramerate * 0.5) textColor = 0xFFFF0000;

    text = 'FPS: $currentFPS'
      + (ClientPrefs.data.memoryDisplay ? '\nMemory: ${CoolUtil.getSizeString(memoryMegas)} / ${CoolUtil.getSizeString(taskMemoryMegas)}' : '')
      + (ClientPrefs.data.dateDisplay ? '\nDate: $stringTimeToReturn' : '')
      + '\nVersion: ${scfunkin.states.MainMenuState.psychEngineVersion}' #if debug + '$stateText$substateText'; #else; #end
  }
}

// Gotten from Bolo Vevo's Kade Engine (erm, I forgot if it's from his engine or not)
#if windows
@:cppFileCode('#include <windows.h>\n#include <psapi.h>')
#end
class MemoryUtil
{
  // https://stackoverflow.com/questions/63166/how-to-determine-cpu-and-memory-consumption-from-inside-a-process
  // TODO: Adapt code for the other platforms. Wrote it for windows and html5 because they're the only ones I can test kek.
  #if windows
  @:functionCode('
		PROCESS_MEMORY_COUNTERS_EX pmc;
		if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc))){
			int convertData = static_cast<int>(pmc.WorkingSetSize);
			return convertData;
		}
		else
			return 0;
	')
  static function getWindowsMemory():Int
  {
    return 0;
  }

  @:functionCode("
		// simple but effective code
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);
		return (allocatedRAM / 1024);
	")
  static function getTotalWindowsRam():Float
  {
    return 0;
  }
  #end

  #if html5
  static function getJSMemory():Float
  {
    return js.Syntax.code("window.performance.memory.usedJSHeapSize");
  }
  #end

  public static function getMemoryfromProcess():Int
  {
    #if windows
    return getWindowsMemory();
    #elseif html5
    return getJSMemory();
    #else
    return System.totalMemory;
    #end
  }

  public static function getTotalMem():Float
  {
    #if windows
    return getTotalWindowsRam();
    #else
    return 0;
    #end
  }

  public static inline function currentMemUsage()
  {
    #if cpp
    return Gc.memInfo64(Gc.MEM_INFO_USAGE);
    #elseif hl
    return Gc.stats().currentMemory;
    #elseif sys
    return cast(cast(System.totalMemory, UInt), Float);
    #else
    return 0;
    #end
  }
}

class DateSetup // Made by me -glow
{
  public static function initDate():String
  {
    final date = Date.now();
    final realYear:String = Std.string(date.getFullYear());
    var realMonth:String = '';
    var realDay:String = '';
    var hourCheck:String = '';
    final minCheck:String = Std.string(date.getMinutes());
    final secCheck:String = Std.string(date.getSeconds());
    final suffix:String = (ClientPrefs.data.militaryTime ? '' : (date.getHours() > 11 ? 'PM' : 'AM'));

    final hourCheckArray:Array<Array<String>> = [
      [
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'
      ],
      [
        '12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'
      ]
    ];
    hourCheck = hourCheckArray[ClientPrefs.data.militaryTime ? 0 : 1][date.getHours()] + ' $suffix';

    final dayArray:Array<Array<String>> = [
      ['7', '1', '2', '3', '4', '5', '6'],
      ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    ];
    realDay = dayArray[ClientPrefs.data.dayAsInt ? 0 : 1][date.getDay()];

    final monthArray:Array<Array<String>> = [
      ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'],
      [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ]
    ];
    realMonth = monthArray[ClientPrefs.data.monthAsInt ? 0 : 1][date.getMonth()];

    final finalTime = '(Year: $realYear | Month: $realMonth | Day: $realDay | Hour: $hourCheck | Min: $minCheck | Sec: $secCheck)';
    return FPSCounter.stringTimeToReturn = finalTime;
  }
}
