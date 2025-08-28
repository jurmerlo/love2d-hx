package;

import Types.JsonApi;

class SuperType {
  final priorities: Map<String, Int>;

  public function new(api: JsonApi) {
    priorities = new Map();
    priorities['Object'] = 0;

    final superTypes = buildTypes(api);

    for (typeName in superTypes.keys()) {
      assignPriority(typeName, superTypes);
    }
  }

  public function getNearestSuperType(typeNames: Array<String>): String {
    var superType = 'UserData';
    var maxPriority = -1;

    for (typeName in typeNames) {
      final priority = priorities[typeName];
      if (priority > maxPriority) {
        maxPriority = priority;
        superType = typeName;
      }
    }
    return superType;
  }

  function buildTypes(api: JsonApi): Map<String, Array<String>> {
    final superTypes: Map<String, Array<String>> = new Map();
    for (type in api.types) {
      superTypes[type.name] = type.supertypes ?? [];
    }

    for (module in api.modules) {
      if (module.types != null) {
        for (type in module.types) {
          superTypes[type.name] = type.supertypes ?? [];
        }
      }

      if (module.enums != null) {
        for (em in module.enums) {
          superTypes[em.name] = em.supertypes ?? [];
        }
      }
    }
    return superTypes;
  }

  function assignPriority(typeName: String, superTypes: Map<String, Array<String>>): Int {
    if (!priorities.exists(typeName)) {
      var max = -1;
      for (superType in superTypes[typeName]) {
        max = Std.int(Math.max(max, assignPriority(superType, superTypes)));
      }
      priorities[typeName] = max + 1;
    }

    return priorities[typeName];
  }
}
