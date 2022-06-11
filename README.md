# 🐏👑 purescript-yoga-json

**Note**: This is a fork [simple-json](https://github.com/justinwoo/purescript-simple-json) ([MIT Licence](./LICENSE/simple-json.LICENSE)).

## Table of Contents
* [usage](#usage)
* [migrate from `simple-json`](#migrate-from-purescript-simple-json)

## Usage

```purescript
import Yoga.JSON as JSON

serialised :: String
serialised =
  JSON.writeJSON { first_name: "Lola", last_name: "Flores" }
```

Check out the tests for how to encode/decode increasingly complex types.

## Migrate from `purescript-simple-json`

`purescript-yoga-json` is a drop-in replacement for `purescript-simple-json`. Just change the imports from `Simple.JSON` to `Yoga.JSON`.

## Differences to `simple-json`

There is an inbuilt codec for `Tuple`s thanks to @ursi

It includes @justinwoo's codecs for en- and decoding generics inspired by
[simple-json-generics](https://github.com/justinwoo/purescript-simple-json-generics)
