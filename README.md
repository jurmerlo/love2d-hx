# Haxe externs for Love2D.

The externs are generated using the [love-api](https://github.com/love2d-community/love-api) this is a submodule in this repo.

The current externs are for Love2D 11.5.

Based on [love-haxe-wrappergen](https://github.com/bartbes/love-haxe-wrappergen) but using haxe and json instead of lua to generate the externs.

## Installation
```bash
haxelib git https://github.com/jurmerlo/love2d-hx
```


## Generating externs
To generate new externs you need to have [lua](https://lua.org) and [haxe](https://haxe.org) installed.

Clone the repo
```bash
git clone https://github.com/jurmerlo/love2d-hx
```

Initialize the git submodule
```bash
git submodule update --init
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
