#if !macro
#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end
// Discord API
#if DISCORD_ALLOWED
import scfunkin.backend.misc.Discord;
#end
// Achievements
#if ACHIEVEMENTS_ALLOWED
import scfunkin.backend.misc.Achievements;
#end
// Debug
import scfunkin.debug.Debug;
// Backend
import scfunkin.backend.assets.Paths;
import scfunkin.backend.assets.Mods;
import scfunkin.backend.misc.Language;
import scfunkin.backend.data.StageData;
import scfunkin.backend.data.WeekData;
import scfunkin.backend.data.judgement.ComboStats;
import scfunkin.backend.data.save.ClientPrefs;
import scfunkin.backend.gamejolt.GJKeys;
import scfunkin.backend.gamejolt.GameJoltAPI;
// Play
import scfunkin.play.Conductor;
import scfunkin.play.input.Controls;
import scfunkin.play.stage.*;
import scfunkin.play.song.Song;
import scfunkin.play.song.data.SongData;
import scfunkin.play.song.data.Difficulty;
// Psych-UI
import scfunkin.backend.ui.*;
// Objects
import scfunkin.objects.FunkinSCSprite;
import scfunkin.objects.note.*;
import scfunkin.objects.stage.*;
import scfunkin.objects.ui.Alphabet;
import scfunkin.objects.ui.BGSprite;
import scfunkin.objects.ui.Hud;
import scfunkin.objects.ui.ComboRatingGroup;
// States
import scfunkin.states.PlayState;
import scfunkin.states.LoadingState;
import scfunkin.states.MusicBeatState;
// Substates
import scfunkin.states.substates.MusicBeatSubState;
import scfunkin.states.substates.engine.IndieDiamondTransSubState;
// Flixel
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxStringUtil;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.graphics.FlxGraphic;
// Flixel Addons
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.effects.FlxSkewedSprite as FlxSkewed;
// FlxAnimate
#if flxanimate
import flxanimate.*;
import flxanimate.PsychFlxAnimate as FlxAnimate;
#end
// Utils
import scfunkin.utils.Constants;
// Modchart
#if FunkinModchart
import modchart.*;
#end
// Filters
#if flixelsoundfilters
import flixel.sound.filters.*;
import flixel.sound.filters.effects.*;
#end

// Usings
using Lambda;
using StringTools;
using thx.Arrays;
using scfunkin.utils.tools.ArraySortTools;
using scfunkin.utils.tools.ArrayTools;
using scfunkin.utils.tools.FloatTools;
using scfunkin.utils.tools.Int64Tools;
using scfunkin.utils.tools.IntTools;
using scfunkin.utils.tools.IteratorTools;
using scfunkin.utils.tools.MapTools;
using scfunkin.utils.tools.StringTools;
using scfunkin.utils.tools.CameraTools;
#end
