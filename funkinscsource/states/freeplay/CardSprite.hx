package states.freeplay;

import openfl.utils.Assets as OpenFLAssets;

typedef CardMeta =
{
  var name:String;
  @:default(true)
  var ?active:Bool;
  var image:String;
  @:default([])
  var ?scale:Array<Float>;
  @:default([])
  var ?graphicScale:Array<Float>;
}

typedef CardAnimationData =
{
  var name:String;
  var fps:Int;
  @:default([])
  var ?offsets:Array<Int>;
  @:default([])
  var ?indices:Array<Int>;
  var loop:Bool;
}

typedef CardData =
{
  var ?idle_anim:CardAnimationData;
  var ?select_anim:CardAnimationData;
  var ?hover_anim:CardAnimationData;
  @:default(0)
  var offsetX:Float;
  @:default(0)
  var offsetY:Float;
  var metaData:CardMeta;
}

class CardSprite extends FunkinSCSprite
{
  public var data:CardData;
  public var imagePath:String;
  public var calls:CardSpriteCalls = new CardSpriteCalls();
  public var folder:String = "";
  public var name:String = "";
  public var index:Int = -1;

  public function new(data:CardData)
  {
    this.data = data;
    this.imagePath = data.metaData.image;
    super();
    createDataAnimations(data.metaData.image, data.idle_anim, data.select_anim, data.hover_anim);
    if (frames != null)
    {
      calls.onSelect = function() {
        playAnim('select', true);
      }
      calls.onIdle = function() {
        playAnim('idle', true);
      }
      calls.onHover = function() {
        if (animation.getByName('hover') != null) playAnim('hover', true);
      }
    }
    else
    {
      calls.onSelect = function() {
        final selectPath:String = Paths.getPath('images/' + data.metaData.image + '-Select');
        final hasSelect:Bool = #if MODS_ALLOWED FileSystem.exists(selectPath) || #end OpenFLAssets.exists(selectPath);
        if (hasSelect) loadGraphic(Paths.image(data.metaData.image + '-Select'));
      }

      calls.onIdle = function() {
        loadGraphic(Paths.image(data.metaData.image));
      }

      calls.onHover = function() {
        final hoverPath:String = Paths.getPath('images/' + data.metaData.image + '-Hover');
        final hasHover:Bool = #if MODS_ALLOWED FileSystem.exists(hoverPath) || #end OpenFLAssets.exists(hoverPath);
        if (hasHover) loadGraphic(Paths.image(data.metaData.image + '-Hover'));
      }
    }
    if (data.metaData.scale != null && data.metaData.scale.length > 1)
    {
      scale.set(data.metaData.scale[0], data.metaData.scale[1]);
    }
    else if (data.metaData.graphicScale != null && data.metaData.graphicScale.length > 1)
    {
      final widthApply:Bool = !Math.isNaN(data.metaData.graphicScale[0]) && data.metaData.graphicScale[0] != 0;
      final heightApply:Bool = !Math.isNaN(data.metaData.graphicScale[1]) && data.metaData.graphicScale[1] != 0;
      final finalWidth:Float = widthApply ? width * data.metaData.graphicScale[0] : 0;
      final finalHeight:Float = heightApply ? height * data.metaData.graphicScale[1] : 0;
      setGraphicSize(finalWidth, finalHeight);
    }
    calls.onIdle();
  }

  public function createDataAnimations(image:String, idle:CardAnimationData, select:CardAnimationData, hover:CardAnimationData)
  {
    if (image == null || idle == null || select == null) return;
    if (image.length < 1 || idle.name.length < 1 || select.name.length < 1) return;

    frames = Paths.getAtlas(image);
    if (frames == null) return;

    if (idle.indices != null && idle.indices.length > 0) animation.addByIndices('idle', idle.name, idle.indices, "", idle.fps, idle.loop);
    else
      animation.addByPrefix('idle', idle.name, idle.fps, idle.loop);
    if (select.indices != null && select.indices.length > 0) animation.addByIndices('select', select.name, select.indices, "", select.fps, select.loop);
    else
      animation.addByPrefix('select', select.name, select.fps, select.loop);

    if (hover != null)
    {
      if (hover.indices != null && hover.indices.length > 0) animation.addByIndices('hover', hover.name, hover.indices, "", hover.fps, hover.loop);
      else
        animation.addByPrefix('hover', hover.name, hover.fps, hover.loop);
    }
  }
}

class CardSpriteCalls
{
  public var onSelect:Void->Void = null;
  public var onIdle:Void->Void = null;
  public var onHover:Void->Void = null;

  public function new()
  {
    onSelect = function() {
    }
    onIdle = function() {
    }
    onHover = function() {
    }
  }
}
