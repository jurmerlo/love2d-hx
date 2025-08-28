import haxe.io.Path;

import sys.FileSystem;

/**
 * Recursive delete a directory.
 * @param dir The directory to delete.
 */
function deleteDir(dir: String) {
  final files = FileSystem.readDirectory(dir);
  for (file in files) {
    final filePath = Path.join([dir, file]);
    if (FileSystem.isDirectory(filePath)) {
      deleteDir(filePath);
    } else {
      FileSystem.deleteFile(filePath);
    }
  }
  FileSystem.deleteDirectory(dir);
}
