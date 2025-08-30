package;

import Functions.createFunction;
import Functions.createMethod;
import Functions.funcArguments;
import Functions.getHaxeType;

import KeyboardEnum.mapKeyboardId;
import KeyboardEnum.mapKeyboardValue;

import Types.ConvertedFile;
import Types.JsonApi;
import Types.JsonEnum;
import Types.JsonFunction;
import Types.JsonModule;
import Types.JsonType;

import Utils.capitalizeFirstLetter;
import Utils.correctIdentifier;
import Utils.createComment;
import Utils.deleteDir;

import haxe.Json;
import haxe.io.Path;

import sys.FileSystem;
import sys.io.File;

function main() {
  final content = File.getContent('api/love_api.json');
  final api: JsonApi = Json.parse(content);

  if (FileSystem.exists('src')) {
    deleteDir('src');
  }

  final superType = new SuperType(api);
  final resolver = new PackageResolver(api);
  final version = api.version;

  for (module in api.modules) {
    final moduleResult = createModule(module, superType, resolver);
    FileSystem.createDirectory(moduleResult.outputFolder);
    for (file in moduleResult.files) {
      File.saveContent(Path.join([moduleResult.outputFolder, file.filename]), file.content);
    }
  }

  final moduleResult = createModule(cast api, superType, resolver, 'love');
  FileSystem.createDirectory(moduleResult.outputFolder);
  for (file in moduleResult.files) {
    File.saveContent(Path.join([moduleResult.outputFolder, file.filename]), file.content);
  }
}

private function createModule(module: JsonModule, superType: SuperType, resolver: PackageResolver,
    ?luaName: String): {
  files: Array<ConvertedFile>,
  outputFolder: String
} {
  final files: Array<ConvertedFile> = [];
  var lines: Array<String> = [];
  final types: Map<String, Bool> = new Map();
  final multiReturns: Map<String, String> = new Map();

  final packageName = luaName != null ? luaName : 'love.';
  final moduleName = packageName == 'love' ? packageName : packageName + module.name;

  final packageLines = resolver.createPackageLine(moduleName);

  if (module.description != null) {
    lines = lines.concat(createComment(module.description));
  }

  lines.push('@:native(\'${moduleName}\')');
  var className = capitalizeFirstLetter(luaName != null ? luaName : module.name);
  if (className != 'Love') {
    className += 'Module';
  }

  lines.push('extern class ${className} {');

  if (module.functions != null) {
    for (func in module.functions) {
      lines = lines.concat(createFunction(className, func, types, multiReturns));
    }
  }

  if (module.callbacks != null) {
    for (cb in module.callbacks) {
      lines = lines.concat(createCallback(cb, types));
    }
  }

  lines.push('}');

  if (module.enums != null) {
    for (em in module.enums) {
      files.push(createEnum(em, moduleName, resolver));
    }
  }

  if (module.types != null) {
    for (type in module.types) {
      files.push(createType(type, moduleName, superType, resolver));
    }
  }

  final resolvedImports = resolver.getImportLines(types, moduleName);
  final imports = createImports(resolvedImports);

  for (ret in multiReturns) {
    lines.push(ret);
  }

  final content = packageLines.join('\n') + imports.join('\n') + '\n\n' + lines.join('\n');
  files.push({ filename: '${className}.hx', content: content });

  var outputFolder = '';
  if (luaName == 'love') {
    outputFolder = 'src/love/';
  } else {
    outputFolder = 'src/love/${luaName ?? module.name}/';
  }

  return { files: files, outputFolder: outputFolder };
}

private function createType(type: JsonType, packageName: String, superType: SuperType,
    resolver: PackageResolver): ConvertedFile {
  var lines: Array<String> = [];

  final packageLines = resolver.createPackageLine(packageName);
  final types: Map<String, Bool> = new Map();
  final multiReturns: Map<String, String> = new Map();

  final currentSuperType = type.supertypes != null
    && type.supertypes.length > 0 ? superType.getNearestSuperType(type.supertypes) : 'UserData';

  if (type.description != null) {
    lines = lines.concat(createComment(type.description));
  }

  lines.push('extern class ${type.name} extends ${currentSuperType} {');

  if (type.functions != null) {
    for (func in type.functions) {
      lines = lines.concat(createMethod(type.name, func, types, multiReturns));
    }
  }

  lines.push('}');

  final resolvedImports = resolver.getImportLines(types, packageName);
  final imports = createImports(resolvedImports);

  final content = packageLines.join('\n') + imports.join('\n') + '\n\n' + lines.join('\n');

  return { filename: '${type.name}.hx', content: content };
}

private function createEnum(em: JsonEnum, packageName: String, resolver: PackageResolver): ConvertedFile {
  var lines = resolver.createPackageLine(packageName);

  if (em.description != null) {
    lines = lines.concat(createComment(em.description));
  }
  lines.push('enum abstract ${em.name} (String) {');

  for (con in em.constants) {
    var name = con.name;
    var value = con.name;
    if (em.name == 'KeyConstant' || em.name == 'Scancode') {
      name = mapKeyboardId(name);
      value = mapKeyboardValue(value);
    }
    final id = correctIdentifier(capitalizeFirstLetter(name));
    if (con.description != null) {
      lines.push('');
      lines = lines.concat(createComment(con.description, '\t'));
    }
    lines.push('\tvar ${id} = \'${value}\';');
  }
  lines.push('}');

  return { filename: '${em.name}.hx', content: lines.join('\n') };
}

private function createCallback(cb: JsonFunction, types: Map<String, Bool>): Array<String> {
  var lines: Array<String> = [];
  var signature = funcArguments(cb.variants[0].arguments, types, false);
  signature += ' -> ';

  if (cb.variants[0].returns != null && cb.variants[0].returns.length > 0) {
    if (cb.variants[0].returns[0].type == 'function') {
      signature += '(${getHaxeType(cb.variants[0].returns[0], types)})';
    } else {
      signature += getHaxeType(cb.variants[0].returns[0], types);
    }
  } else {
    signature += 'Void';
  }

  lines.push('');
  if (cb.description != null) {
    lines = lines.concat(createComment(cb.description, '\t', cb.variants[0]));
  }
  lines.push('\tpublic static var ${cb.name}: ${signature};');

  return lines;
}

private function createImports(resolvedImports: Array<String>): Array<String> {
  var imports = ['import haxe.extern.Rest;', 'import lua.Table;', 'import lua.UserData;'];
  imports = imports.concat(resolvedImports);
  imports.sort((a, b) -> {
    if (a < b) {
      return -1;
    } else if (a > b) {
      return 1;
    }
    return 0;
  });

  return imports;
}
