--DiscordClient Functions--
changeDiscordPresence(details, state, smallImageKey, hasStartTimestamp, endTimeStamp)

changeDiscordClientID(newID)

--Achievements Functions--
getAchievementScore(name)

setAchievementScore(name, value, saveIfNotUnlocked)

addAchievementScore(name, value, saveIfNotUnlocked)

unlockAchievement(name)

isAchievementUnlocked(name)

achievementExists(name)

--Reflection Functions--
getProperty(variable, allowMaps)

setProperty(variable, value, allowMaps)

getPropertyFromClass(classVar, variable, allowMaps)

setPropertyFromClass(classVar, variable, value, allowMaps)

getPropertyFromGroup(obj, index, variable, allowMaps)

setPropertyFromGroup(obj, index, variable, value, allowMaps)

removeFromGroup(obj, index, dontDestroy)

callMethod(funcToRun, args)

callMethodFromClass(className, funToRun, args)

createInstance(variableToSave, classNAme, args)

addInstance(objectName, inFront)

--Text Functions
makeLuaText(tag, text, width, x, y)

setTextString(tag, text)

setTextSize(tag, size)

setTextWidth(tag, width)

setTextHeight(tag, height) --Only able to use if version of flixel is greater than or equal to (5.4.0)

setTextAutoSize(tag, bool)

setTextBorder(tag, size, color, style)

setTextColor(tag, color)

setTextFont(tag, newFont)

setTextItalic(tag, italic)

setTextAlignment(tag, alignment)

getTextString(tag)

getTextSize(tag)

getTextFont(tag)

getTextWidth(tag)

addLuaText(tag)

removeLuaText(tag, destroy)

--Extra Functions
keyboardJustPressed(name)

keyboardPressed(name)

keybaordReleased(name)

anyGamepadJustPressed(name)

anyGamepadPressed(name)

anyGamepadReleased(name)

gamepadAnalogX(id, leftStick)

gamepadAnalogY(id, leftStick)

gamepadJustPressed(id, name)

gamepadPressed(id, name)

gamepadReleased(id, name)

keyJustPressed(name)

keyPressed(name)

keyReleased(name)

initSaveData(name, folder)

flushSaveData(name)

getDataFromSave(name, field, defaultValue)

setDataFromSave(name, field, value)

eraseSaveData(name)

checkFileExists(filename, absolute)

saveFile(path, content, absolute)

deleteFile(path, ignoreModFolders)

getTextFromFile(path, ignoreModFolders)

directoryFileList(folder)

stringStartsWith(str, start)

stringEndsWith(str, endPart)

stringSplit(str, split)

stringTrim(str)

getRandomInt(min, max, exclude)

getRandomFloat(min, max, exclude)

paths(tag, text)

--CustomSubState Functions
openCustomSubState(name, pauseGame)

closeCustomSubstate()

insertToCustomSubstate(tag, pos)

--Shader Functions
initLuaShader(name, glslVersion)

setSpriteShader(obj, shader)

removeSpriteShader(obj)

getShaderBool(obj, prop)

getShaderBoolArray(obj, prop)

getShaderInt(obj, prop)

getShaderIntArray(obj, prop)

getShaderFloat(obj, prop)

getShaderFloatArray(obj, prop)

setShaderBool(obj, prop, value)

setShaderBoolArray(obj, prop, value)

setShaderInt(obj, prop, value)

setShaderIntArray(obj, prop, value)

setShaderFloat(obj, prop, value)

setShaderFloatArray(obj, prop, value)

setShaderSampler2D(obj, prop, bitmapdataPath)

setActorNoShader(id)

initShaderFromSource(name, classString)

setActorShader(actorStr, shaderName)

setCameraShader(camStr, shaderName)

removeCameraShader(camStr, shaderName)

createCustomShader(id, file, glslVersion)

setActorCustomShader(id, actor)

setActorNoCustomShader(actor)

setCameraCustomShader(id, camera)

pushShaderToCamera(id, camera)

setCameraNoCustomShader(shader)

doTweenCustomShaderFloat(shaderName, prop, value, time, easeStr)

doTweenShaderFloat(tag, object, nameOfFloatVar, newFloat, duration, easeType, swagShader) --Swag Shader is a set shader.

--Deprecated Functions
addAnimationByIndicesLoop(obj, name, prefix, indices, framerate)

objectPlayAnimation(obj, name, forced, startFrame)

characterPlayAnim(character, anim, forced)

luaSpriteMakeGraphic(tag, width, height, color)

luaSpriteAddAnimationByPrefix(obj, name, prefix, framerate, loop)

luaSpriteAddAnimationByIndices(obj, name, prefix, indices, framerate)

luaSpritePlayAnimation(tag, name, forced)

setLuaSpriteCamera(tag, camera)

setLuaSpriteScrollFactor(tah, scrollX, scrollY)

scaleLuaSprite(tag, x, y)

getPropertyLuaSprite(tag, variable)

setPropertyLuaSprite(tag, variable, value)

musicFadeIn(duration, fromValue, toValue)

musicFadeOut(duration, toValue)

--Modchart Functions (Modcharting Tool functions for lua)
startMod(name, modClass, Type, pf)

setMod(name, value)

setSubMod(name, subValName, value)

setModTargetLane(name, value)

setModPlayfield(idx)

addPlayfield(x, y, z)

removePlayfield(idx)

tweenModifier(modifier, val, time, ease)

tweenModifierSubValue(modifier, subValue, val, time, ease)

setModEaseFunc(name, ease)

set(beat, argsAsString)

ease(beat, time, ease, argsAsString)
