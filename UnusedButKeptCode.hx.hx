class UnusedButKeptCode
{
  public var externalSoundTracks:Map<String, FlxSound>;

  public dynamic function generateSong()
  {
    // Extra song tracks
    if (extraSongData != null && extraSongData._extraTracks != null)
    {
      externalSoundTracks = new Map<String, FlxSound>();
      var extraTracks:Array<ExternalSoundFile> = extraSongData._extraTracks;
      for (extraTrack in extraTracks)
      {
        final characterType:String = extraTrack.side == null ? '' : extraTrack.side;
        var character:String = extraTrack.character == null ? '' : extraTrack.character;
        var externVocals:String = extraTrack.vocal == null ? '' : extraTrack.vocal;
        if (characterType != '')
        {
          switch (characterType)
          {
            case 'dad', 'opponent', 'op':
              if (character == '') character = dad.curCharacter;
              if (externVocals == '') externVocals = vocalOp;
            case 'boyfriend', 'bf', 'player', 'pl':
              if (character == '') character = boyfriend.curCharacter;
              if (externVocals == '') externVocals = vocalPl;
          }
        }
        final type:String = extraTrack.type.toLowerCase();
        final finalName:String = extraTrack.name == null ? SONG.getSongData('songId') : finalName;
        final finalFolder:String = extraTrack.folder == null ? 'songs' : extraTrack.folder;
        final finalPrefix:String = extraTrack.prefix == null ? currentPrefix : extraTrack.prefix;
        final finalSuffix:String = extraTrack.suffix == null ? currentSuffix : extraTrack.suffix;
        final props =
          {
            song: finaName,
            prefix: finalPrefix,
            suffix: finalSuffix,
            externVocal: externVocals
          };
        final extensiveProps =
          {
            soundProps: props,
            name: finalName
            folder: finalFolder
          };
        var finalSound:Sound = null;
        var volume:Float = 0.0;

        switch (type)
        {
          case 'inst', 'instrumental', 'vocal', 'vocals':
            var finalType:String = type.contains('in') ? 'INST' : 'VOCALS';
            finalSound = SoundUtil.findVocalOrInst(props, type);
            volume = finalType == 'INST' ? inst.volume : vocals.volume;
          default:
            finalSound = SoundUtil.findSound(extensiveProps, true);
            volume = extraTrack.volume > 0 ? extraTrack.volume : 1;
        }
        if (finalSound != null && extraTrack.tag != null)
        {
          var sound:FlxSound = new FlxSound().loadEmbedded(finalSound);
          sound.volume = volume;
          if (!externalSoundTracks.exists(extraTrack.tag)) externalSoundTracks.set(extraTrack.tag, sound);
          FlxG.sound.list.add(sound);
        }
      }
    }
  }

  public function performESTAction(action:String = 'NONE', ?value:Dynamic = -1)
  {
    if (externalSoundTracks == null) return;

    for (extraSoundTrack in externalSoundTracks.keys())
    {
      if (externalSoundTracks.exists(extraSoundTrack) && externalSoundTracks.get(extraSoundTrack) != null)
      {
        switch (action)
        {
          case 'PLAY':
            externalSoundTracks.get(extraSoundTrack).time = FlxG.sound.music.time;
            #if FLX_PITCH externalSoundTracks.get(extraSoundTrack).pitch = playbackRate; #end
            externalSoundTracks.get(extraSoundTrack).play();
          case 'PAUSE':
            externalSoundTracks.get(extraSoundTrack).pause();
          case 'STOP', 'SM', 'SMDA':
            externalSoundTracks.get(extraSoundTrack).stop();
          case 'DEACTIVATE', 'SMDA':
            externalSoundTracks.get(extraSoundTrack).active = false;
          case 'CHANGE VOLUME', 'SMDA':
            externalSoundTracks.get(extraSoundTrack).volume = (action == 'SMDA' || action == 'SM') ? 0.0 : value;
          case 'PITCH':
            externalSoundTracks.get(extraSoundTrack).pitch = value;
        }
      }
    }
  }
}
