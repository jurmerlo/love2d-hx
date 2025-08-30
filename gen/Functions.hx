import Types.JsonFunction;
import Types.JsonProperty;
import Types.JsonVariant;

import Utils.capitalizeFirstLetter;
import Utils.correctIdentifier;
import Utils.createComment;

function createFunction(typeName: String, func: JsonFunction, types: Map<String, Bool>,
    multiReturns: Map<String, String>): Array<String> {
  return createFunctionBase(typeName, func, types, true, multiReturns);
}

function createMethod(typeName: String, method: JsonFunction, types: Map<String, Bool>,
    multiReturns: Map<String, String>): Array<String> {
  return createFunctionBase(typeName, method, types, false, multiReturns);
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

    if (arg.name == '...') {
      argsResult += 'args: Rest<${getHaxeType(arg, types)}>';
    } else {
      if (isFuncType) {
        argsResult += '${arg.name}: ';
      }

      argsResult += getHaxeType(arg, types);
    }
  }
  argsResult += ')';

  return argsResult;
}

private function createFunctionBase(typeName: String, func: JsonFunction, types: Map<String, Bool>, isStatic: Bool,
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

private function getType(jsonType: String): String {
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

private function createMultiReturnType(name: String, returns: Array<JsonProperty>, types: Map<String, Bool>): String {
  final lines: Array<String> = ['', '@:multiReturn', 'extern class ${name} {'];

  final addedNames: Array<String> = [];
  for (ret in returns) {
    if (ret.name != '...' && !addedNames.contains(ret.name)) {
      final type = getHaxeType(ret, types);
      lines.push('\tvar ${ret.name}: ${type};');
      addedNames.push(ret.name);
    }
  }
  lines.push('}');

  return lines.join('\n');
}

private function createOverload(typeName: String, name: String, variant: JsonVariant, types: Map<String, Bool>,
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
          final id = correctIdentifier(argName);

          final ar = '${arg.defaultValue != null ? '?' : ''}${id}: ${type}';
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
      final capitalized = capitalizeFirstLetter(name);
      returnType = '${typeName}${capitalized}Result';
      multiReturns[name] = createMultiReturnType(returnType, variant.returns, types);
    }
  }

  return '(${arguments.join(', ')}): ${returnType}';
}
