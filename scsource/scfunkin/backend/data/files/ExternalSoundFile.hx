package scfunkin.backend.data.files;

typedef ExternalSoundFile =
{
  > ExternalFile,
  var ?prefix:String;
  var ?suffix:String;
  var ?character:String;
  var ?vocal:String;
  var ?difficulty:String;
  var ?volume:Float;
  var ?side:String;
};
