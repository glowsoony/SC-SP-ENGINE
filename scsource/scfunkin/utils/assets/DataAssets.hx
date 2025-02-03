package scfunkin.utils.assets;

class DataAssets
{
  public static function listDataFilesInPath(path:String, ?filesToIgnore:Array<String> = null):Array<String>
  {
    var results:Array<String> = [];
    var directories:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$path');
    for (directory in directories)
      if (FileSystem.exists(directory))
      {
        for (file in FileSystem.readDirectory(directory))
        {
          if (!results.contains('$file/$file'))
          {
            if (filesToIgnore != null)
            {
              for (fileIgnored in filesToIgnore)
              {
                if (file.contains(fileIgnored)) continue;
                results.push('$file/$file');
              }
            }
            else
              results.push('$file/$file');
          }
        }
      }

    return results;
  }
}
