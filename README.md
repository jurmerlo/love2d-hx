# Haxe externs for Love2D.

The externs are generated using the [love-api](https://github.com/love2d-community/love-api) this is a submodule in this repo.

The current externs are for Love2D 11.5.

## Installation
```bash
haxelib git https://github.com/square-two/love2d-hx
```


## Generating externs
To generate new externs you need to have [lua](https://lua.org) and [haxe](https://haxe.org) installed.

Clone the repo
```bash
git clone https://github.com/square-two/love2d-hx
```

Initialize the git submodules
```bash
git submodules update --init
```


Generate the api json file:
```bash
lua gen_json.lua
```

Generate the externs:
```bash
haxe generate.hxml
```

This will update the externs files in the `src` folder.