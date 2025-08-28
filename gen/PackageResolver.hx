import Types.JsonApi;

class PackageResolver {
  final paths: Map<String, String>;

  public function new(api: JsonApi) {
    paths = buildPackagePaths(api);
  }

  public function getImportLines(types: Map<String, Bool>, pkgName: String): Array<String> {
    var imports: Array<String> = [];
    for (type in types.keys()) {
      final module = paths[type];
      if (module != null && module != pkgName) {
        imports.push('import ${module}.${type};');
      }
    }

    return imports;
  }

  function buildPackagePaths(api: JsonApi): Map<String, String> {
    final lovePaths: Map<String, String> = new Map();

    for (type in api.types) {
      lovePaths[type.name] = 'love';
    }

    for (module in api.modules) {
      var moduleName = 'love.${module.name}';
      if (module.types?.length > 0) {
        for (type in module.types) {
          lovePaths[type.name] = moduleName;
        }
      }

      if (module.enums?.length > 0) {
        for (type in module.enums) {
          lovePaths[type.name] = moduleName;
        }
      }
    }

    return lovePaths;
  }
}
