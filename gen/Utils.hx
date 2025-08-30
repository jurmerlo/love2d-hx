import Types.JsonVariant;

import haxe.io.Path;

import sys.FileSystem;

using StringTools;

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

function capitalizeFirstLetter(text: String): String {
  return text.substring(0, 1).toUpperCase() + text.substring(1);
}

function createComment(description: String, prefix = '', ?variantData: JsonVariant): Array<String> {
  final lines: Array<String> = ['${prefix}/**'];
  for (line in description.split('\n')) {
    if (line.trim().length == 0) {
      continue;
    }
    lines.push('${prefix} * ${line}');
  }

  if (variantData != null) {
    if (variantData.arguments != null) {
      for (argument in variantData.arguments) {
        lines.push('${prefix} * @param ${argument.name} ${argument.description}');
      }
    }

    if (variantData.returns != null && variantData.returns.length == 1) {
      lines.push('${prefix} * @return ${variantData.returns[0].description}');
    }
  }

  lines.push('${prefix} */');
  return lines;
}

function correctIdentifier(id: String): String {
  if (~/^[0-9]/.match(id)) {
    return '_' + id;
  }

  return id;
}
