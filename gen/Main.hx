package;

import Types.ConvertedFile;
import Types.JsonApi;
import Types.JsonEnum;
import Types.JsonFunction;
import Types.JsonModule;
import Types.JsonProperty;
import Types.JsonType;
import Types.JsonVariant;

import Utils.deleteDir;

import haxe.Json;
import haxe.io.Path;

import sys.FileSystem;
import sys.io.File;

using StringTools;

function getType(jsonType: String): String {
  if (jsonType.indexOf(' or ') != -1) {
    return 'Dynamic';
  }

  switch (jsonType) {
    case 'string', 'ShaderVariableType':
      return 'String';

    case 'number':
      return 'Float';

    case 'boolean':
      return 'Bool';

    case 'table':
      return 'Table<Dynamic, Dynamic>';

    case 'light userdata', 'userdata':
      return 'UserData';

    case 'function', 'mixed', 'value', 'any', 'Variant', 'cdata':
      return 'Dynamic';

    default:
      return jsonType;
  }
}

function correctIdentifier(id: String): String {
  if (~/^[0-9]/.match(id)) {
    return '_' + id;
  }

  return id;
}

function main() {
  final content = File.getContent('api/love_api.json');
  final data: JsonApi = Json.parse(content);

  if (FileSystem.exists('src')) {
    deleteDir('src');
  }

  final superType = new SuperType(data);
  final resolver = new PackageResolver(data);

  for (module in data.modules) {
    final moduleResult = createModule(module, superType, resolver);
    FileSystem.createDirectory(moduleResult.outputFolder);
    for (file in moduleResult.files) {
      File.saveContent(Path.join([moduleResult.outputFolder, file.filename]), file.content);
    }
  }

  final moduleResult = createModule(cast data, superType, resolver, 'love');
  FileSystem.createDirectory(moduleResult.outputFolder);
  for (file in moduleResult.files) {
    File.saveContent(Path.join([moduleResult.outputFolder, file.filename]), file.content);
  }
}

function createImports(): Array<String> {
  return ['import haxe.extern.Rest;', 'import lua.Table;', 'import lua.UserData;'];
}

function getHaxeType(type: JsonProperty, types: Map<String, Bool>): String {
  var haxeType = '';

  if (type.type == 'function') {
    haxeType = funcArguments(type?.signature?.arguments, types, true);
    haxeType += ' -> ';

    if (type?.signature?.returns != null && type?.signature?.returns?.length > 0) {
      haxeType += getHaxeType(type.signature.returns[0], types);
    } else {
      haxeType += 'Void';
    }
  } else {
    haxeType = getType(type.type);
    types[haxeType] = true;
  }

  return haxeType;
}

function funcArguments(arguments: Null<Array<JsonProperty>>, types: Map<String, Bool>, isFuncType: Bool): String {
  if (arguments == null || arguments.length == 0) {
    return isFuncType ? 'Void' : '()';
  }

  var argsResult = '(';
  for (i in 0...arguments.length) {
    final arg = arguments[i];
    if (i > 0) {
      argsResult += ', ';
    }

    if (isFuncType) {
      argsResult += '${arg.name}: ';
    }

    argsResult += getHaxeType(arg, types);
  }
  argsResult += ')';

  return argsResult;
}

function createMultiReturnType(name: String, returns: Array<JsonProperty>, types: Map<String, Bool>): String {
  final lines: Array<String> = ['', '@:multiReturn', 'extern class ${name} {'];
  for (ret in returns) {
    if (ret.name != '...') {
      final type = getHaxeType(ret, types);
      lines.push('\tvar ${ret.name}: ${type};');
    }
  }
  lines.push('}');

  return lines.join('\n');
}

function createOverload(typeName: String, name: String, variant: JsonVariant, types: Map<String, Bool>,
    multiReturns: Map<String, String>): String {
  final arguments: Array<String> = [];

  if (variant.arguments != null) {
    for (arg in variant.arguments) {
      final type = getHaxeType(arg, types);

      if (arg.name == '...') {
        arguments.push('args: Rest<${type}>');
      } else {
        final regex = ~/([^, ]+)/;
        var txt = arg.name;
        while (regex.match(txt)) {
          final argName = regex.matched(0);
          txt = regex.matchedRight();
          final ar = '${arg.defaultValue != null ? '?' : ''}${correctIdentifier(argName)}: ${type}'
            + '${arg.defaultValue != null ? ' = ${arg.defaultValue}' : ''}';
          arguments.push(ar);
        }
      }
    }
  }

  var returnType = 'Void';
  if (variant.returns != null && variant.returns.length > 0) {
    if (variant.returns.length == 1) {
      returnType = getHaxeType(variant.returns[0], types);
    } else {
      returnType = '${typeName}${capitalizeFirstLetter(name)}Result';
      multiReturns[name] = createMultiReturnType(returnType, variant.returns, types);
    }
  }

  return '(${arguments.join(', ')}): ${returnType}';
}

function createCallback(cb: JsonFunction, types: Map<String, Bool>): Array<String> {
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

function createFunctionBase(typeName: String, func: JsonFunction, types: Map<String, Bool>, isStatic: Bool,
    multiReturns: Map<String, String>): Array<String> {
  var lines: Array<String> = [''];

  if (func.description != null) {
    lines = lines.concat(createComment(func.description, '\t', func.variants[0]));
  }

  final signatures: Array<String> = [];
  for (variant in func.variants) {
    signatures.push(createOverload(typeName, func.name, variant, types, multiReturns));
  }

  final mainFunc = signatures.shift();

  for (sig in signatures) {
    lines.push('\t@:overload(function ${sig} {})');
  }

  lines.push('\tpublic${isStatic ? ' static' : ''} function ${func.name}${mainFunc};');

  return lines;
}

function createFunction(typeName: String, func: JsonFunction, types: Map<String, Bool>,
    multiReturns: Map<String, String>): Array<String> {
  return createFunctionBase(typeName, func, types, true, multiReturns);
}

function createMethod(typeName: String, method: JsonFunction, types: Map<String, Bool>,
    multiReturns: Map<String, String>): Array<String> {
  return createFunctionBase(typeName, method, types, false, multiReturns);
}

function createEnum(em: JsonEnum, packageName: String): ConvertedFile {
  var lines: Array<String> = ['package ${packageName};'];

  if (em.description != null) {
    lines = lines.concat(createComment(em.description));
  }
  lines.push('enum abstract ${em.name} (String) {');

  for (con in em.constants) {
    final id = correctIdentifier(capitalizeFirstLetter(con.name));
    lines.push('\tvar ${id} = "${con.name}";');
  }
  lines.push('}');

  return { filename: '${em.name}.hx', content: lines.join('\n') };
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

function createType(type: JsonType, packageName: String, superType: SuperType,
    resolver: PackageResolver): ConvertedFile {
  var lines: Array<String> = [];

  final packageLine = 'package ${packageName};\n\n';
  var imports = createImports();
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

  imports = imports.concat(resolver.getImportLines(types, packageName));
  imports.sort((a, b) -> {
    if (a < b) {
      return -1;
    } else if (a > b) {
      return 1;
    }
    return 0;
  });

  final content = packageLine + imports.join('\n') + '\n\n' + lines.join('\n');

  return { filename: '${type.name}.hx', content: content };
}

function createModule(module: JsonModule, superType: SuperType, resolver: PackageResolver,
    ?luaName: String): { files: Array<ConvertedFile>, outputFolder: String } {
  final files: Array<ConvertedFile> = [];
  var lines: Array<String> = [];
  final types: Map<String, Bool> = new Map();
  final multiReturns: Map<String, String> = new Map();

  final packageName = luaName != null ? luaName : 'love.';
  final moduleName = packageName == 'love' ? packageName : packageName + module.name;

  final packageLine = 'package ${moduleName};\n\n';
  var imports = createImports();

  if (module.description != null) {
    lines = lines.concat(createComment(module.description));
  }

  lines.push('@:native(${moduleName})');
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
      files.push(createEnum(em, moduleName));
    }
  }

  if (module.types != null) {
    for (type in module.types) {
      files.push(createType(type, moduleName, superType, resolver));
    }
  }

  imports = imports.concat(resolver.getImportLines(types, moduleName));
  imports.sort((a, b) -> {
    if (a < b) {
      return -1;
    } else if (a > b) {
      return 1;
    }
    return 0;
  });

  for (ret in multiReturns) {
    lines.push(ret);
  }

  final content = packageLine + imports.join('\n') + '\n\n' + lines.join('\n');
  files.push({ filename: '${className}.hx', content: content });

  var outputFolder = '';
  if (luaName == 'love') {
    outputFolder = 'src/love/';
  } else {
    outputFolder = 'src/love/${luaName ?? module.name}/';
  }

  return { files: files, outputFolder: outputFolder };
}

function capitalizeFirstLetter(text: String): String {
  return text.substring(0, 1).toUpperCase() + text.substring(1);
}
