## Sick Coders Engine
* This engine brings features the may apply to modified game play!, other results screens!, betadciu things support!, more stuff is added to the engine for it to be modified however *you* intend to use this engine!*
* SCE brings NotITG modchart support along with many other features!
* This engine is made with **Psych Engine**!

## SCE Credits:
* Glowsoony - Programmer
* Edwhak_Killbot - Programmer (Leader of SCE)
* Slushi - Programmer (Has helped with the Crash Handler and a few other things! he is also a beta tester for bugs! ***thanks***)!

## Credits To Other Engine / Most Engine Features And Where They Come From! (Sorry if only now the credits exist!, extermely sorry!):
* BETADCIU Engine By Blantados [Stuff like character change and others are used from here!](https://github.com/Blantados/BETADCIU-Engine-Source/tree/main)
* Kade stuff added from original stuff and my friend bolo! TYSM [Kade ResultsScreen and most stuff](https://github.com/BoloVEVO/Kade-Engine)
* FlxCustomColor Stuff from TheLeerName [Thanks](https://github.com/ShadowMario/FNF-PsychEngine/pull/13323)
* Most other fixes, noteskin support, char json edits, and more all by me *glowsoony*
* Scripting HX from codeNameEngine/Macros for compiling [Macro class, Hx Scripting, Custom Shaders, MultiFramesCollection](https://github.com/FNF-CNE-Devs/CodenameEngine) //So sorry for not crediting, I completely did plan but forgot 😭🙏
* Lots of code from original game, V-SLICE FNF [ReflectUtil, WaveFormSprite, Audio, Scoring, Results](https://github.com/FunkinCrew/Funkin)
* Most shaders originally from Voiid-Chronicles V2 [RayMarch, ChromaticAbberation, ThreeD, WaveCircle, etc..](https://github.com/TheZoroForce240/Voiid-Chronicles-V2-Source)
* FPS Plus [WaveformSprite](https://github.com/ThatRozebudDude/FPS-Plus-Public)

## Installation:
You must have [the most up-to-date version of Haxe](https://haxe.org/download/), seriously, stop using 4.1.5, it messes some stuff.

open up a Command Prompt/PowerShell or Terminal, type `haxelib install hmm`

after it finishes, simply type `haxelib run hmm install` in order to install all the needed libraries for *Psych Engine!*

## HXVlc in Linux:

Use the following commands:

```cmd
sudo apt-get install libvlc-dev
sudo apt-get install libvlccore-dev
sudo apt-get install vlc-bin
sudo apt-get install glibc-source
sudo apt-get install libidn12
sudo apt-get install libidn-dev
```

It doesn't matter if you already have some of those libraries, just use the command and retry the compile command (``lime test linux``?)

## Customization:

if you wish to disable things like *Lua Scripts* or *Video Cutscenes*, you can read over to `Project.xml`

inside `Project.xml`, you will find several variables to customize Psych Engine to your liking

to start you off, disabling Videos should be simple, simply Delete the line `"VIDEOS_ALLOWED"` or comment it out by wrapping the line in XML-like comments, like this `<!-- YOUR_LINE_HERE -->`

same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED`, this and other customization options are all available within the `Project.xml` file

_____________________________________

## Psych Engine Credits:
* Shadow Mario - Head Developer, Programmer.
* Riveren - Main Artist.

### Psych Engine - Special Thanks
* bbpanzu - Ex-Team Member (Programmer).
* crowplexus - HScript Iris, Input System v3, and Other PRs.
* Kamizeta - Creator of Pessy, Psych Engine's mascot.
* MaxNeton - Loading Screen Easter Egg Artist/Animator.
* Keoiki - Note Splash Animations and Latin Alphabet.
* SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform.
* EliteMasterEric - Runtime Shaders support and Other PRs.
* MAJigsaw77 - .MP4 Video Loader Library (hxvlc).
* Tahir Toprak Karabekiroglu - Note Splash Editor and Other PRs.
* iFlicky - Composer of Psync,  Tea Time, and some sound effects.
* KadeDev - Fixed some issues on Chart Editor and Other PRs.
* superpowers04 - LUA JIT Fork.
* CheemsAndFriends - Creator of FlxAnimate.
* Ezhalt - Pessy's Easter Egg Jingle.
* MaliciousBunny - Video for the Final Update.
_____________________________________

# Features

## Attractive animated dialogue boxes:

![](https://user-images.githubusercontent.com/44785097/127706669-71cd5cdb-5c2a-4ecc-871b-98a276ae8070.gif)


## Mod Support
* Probably one of the main points of this engine, you can code in .lua files outside of the source code, making your own weeks without even messing with the source!
* Comes with a Mod Organizing/Disabling Menu.


## Atleast one change to every week:
### Week 1:
  * New Dad Left sing sprite
  * Unused stage lights are now used
### Week 2:
  * Both BF and Skid & Pump does "Hey!" animations (Todo: Make bf use "cheer" from VSlice)
  * Thunders does a quick light flash and zooms the camera in slightly
  * Added a quick transition/cutscene to Monster
### Week 3:
  * BF does "Hey!" during Philly Nice
  * Blammed has a cool new colors flash during that sick part of the song
### Week 4:
  * Better hair physics for Mom/Boyfriend (Maybe even slightly better than Week 7's :eyes:)
  * Henchmen die during all songs. Yeah :(
### Week 5:
  * Bottom Boppers and GF does "Hey!" animations during Cocoa and Eggnog
  * On Winter Horrorland, GF bops her head slower in some parts of the song.
### Week 6:
  * On Thorns, the HUD is hidden during the cutscene
  * Also there's the Background girls being spooky during the "Hey!" parts of the Instrumental
  * ~~Added rain for roses, added some effects to thorns but left senpai alone~~ <- Todo
### Week 7:
  * No extra features yet!
### Weekend1:
  * No extra features yet!

## Cool new Chart Editor changes and countless bug fixes
![](https://github-production-user-asset-6210df.s3.amazonaws.com/84847356/280155297-2838bc71-8d1b-4cd3-9086-922e4d85f0f8.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20231103%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20231103T004728Z&X-Amz-Expires=300&X-Amz-Signature=90fb8001a383a492bee7b6d284106a4c75a1b41c82b8c2154497ab0e751c9a40&X-Amz-SignedHeaders=host&actor_id=84847356&key_id=0&repo_id=620069939)
* You can now chart "Event" notes, which are bookmarks that trigger specific actions that usually were hardcoded on the vanilla version of the game.
* Your song's BPM can now have decimal values
* You can manually adjust a Note's strum time if you're really going for milisecond precision
* You can change a note's type on the Editor, it comes with two example types:
  * Alt Animation: Forces an alt animation to play, useful for songs like Ugh/Stress
  * Hey: Forces a "Hey" animation instead of the base Sing animation, if Boyfriend hits this note, Girlfriend will do a "Hey!" too.
  * You can use gf and mom notes to make the second opponent or gf play animations!
* You can now use up to 14 values for each event!

## Multiple editors to assist you in making your own Mod
![Screenshot_3](https://user-images.githubusercontent.com/44785097/144629914-1fe55999-2f18-4cc1-bc70-afe616d74ae5.png)
* Working both for Source code modding and Downloaded builds!
* And a special one added was the modchart editor!

## Story mode menu rework:
![](https://i.imgur.com/UB2EKpV.png)
* Added a different BG to every song (Other than Tutorial)
* All menu characters are now in individual spritesheets, makes modding it easier.

## Credits menu
![Screenshot_1](https://github.com/EdwhakKB/SC-SP-ENGINE/assets/84847356/238c2a8d-edb9-441e-8162-588fbc2eb207)
* You can add a head icon, name, description and a Redirect link for when the player presses Enter while the item is currently selected.

## Awards/Achievements
* The engine comes with 16 example achievements that you can mess with and learn how it works (Check Achievements.hx and search for "checkForAchievement" on PlayState.hx)

## Options menu:
* You can change Note colors, Delay and Combo Offset, Controls and Preferences there.
 * On Preferences you can toggle Downscroll, Middlescroll, Anti-Aliasing, Framerate, Low Quality, Note Splashes, Flashing Lights, etc.
 * On Misc you can change stuff about the fps counter and change the results Screen to which one you want!

## Other gameplay features:
* When the enemy hits a note, their strum note also glows.
 * Lag doesn't impact the camera movement and player icon scaling anymore.
  * Some stuff based on Week 7's changes has been put in (Background colors on Freeplay, Note splashes)
   * You can reset your Score on Freeplay/Story Mode by pressing Reset button.
    * You can listen to a song or adjust Scroll Speed/Damage taken/etc. on Freeplay by pressing Space.
   * You can play on the opponent's side!
  * You can turn off the sustains!
 * You can do a show casing mode for gameplay, playing normaly, or even for videos!

---
 - [Todo](docs/files/TODO.md)
---
