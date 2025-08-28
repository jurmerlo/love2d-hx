typedef JsonApi = {
  var version: String;
  var types: Array<JsonType>;
  var modules: Array<JsonModule>;
  var functions: Array<JsonFunction>;
  var callbacks: Array<JsonFunction>;
}

typedef JsonProperty = {
  var name: String;
  var ?description: String;
  var type: String;
  var ?defaultValue: String;
  var ?signature: JsonVariant;
}

typedef JsonEnumField = {
  var name: String;
  var ?description: String;
}

typedef JsonVariant = {
  var ?arguments: Array<JsonProperty>;
  var ?returns: Array<JsonProperty>;
}

typedef JsonFunction = {
  var name: String;
  var ?description: String;
  var variants: Array<JsonVariant>;
}

typedef JsonType = {
  var name: String;
  var ?supertypes: Array<String>;
  var ?description: String;
  var ?functions: Array<JsonFunction>;
  var ?constructors: Array<String>;
}

typedef JsonEnum = {
  var name: String;
  var ?supertypes: Array<String>;
  var ?description: String;
  var constants: Array<JsonEnumField>;
}

typedef JsonModule = {
  var name: String;
  var ?description: String;
  var ?types: Array<JsonType>;
  var ?functions: Array<JsonFunction>;
  var ?enums: Array<JsonEnum>;
  var ?callbacks: Array<JsonFunction>;
}

typedef ConvertedFile = {
  var filename: String;
  var content: String;
}
