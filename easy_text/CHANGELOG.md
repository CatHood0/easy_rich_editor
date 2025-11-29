# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 1.0.8 - 11 / 29 / 2025

### Added

* `StylesExtension` to get more easily standard attributes.

## 1.0.7 - 11 / 27 / 2025

### Fixed

* `LinkAttribute` is not exported.

## 1.0.6 - 11 / 27 / 2025

### Added 

* implemented `getByType<T>` in `EasyAttributeStyles` to get attributes by a type easily.

## 1.0.5 - 09 / 24 / 2025

### Fixes

* Inserting text into instances that contains same `styles` property than the passed in `insert` method should be merged without unlink it.

## 1.0.4 - 09 / 10 / 2025

### Changed

* Removed nullability in `before`, `between`, `after` methods.
* Renamed `_splitExactRanges` method to `extractAt`.

## 1.0.3 - 9 / 04 / 2025

### Changed

* `id` property now is available on `constructors` and `copyWith` method.
* `deepEquals` was deprecated since does not fit with the new custom `hashCode` method

### Added

* Added `charAt`, `toLowerCase`, `toUpperCase`, and `split` shortcuts to avoid calling `text` property unnecessarily on `EasyText` instances.
* Added `strictEquals` and `strictHashCode` for cases where we need more control on the equality of two `EasyText` instances.

### Fixes

* README code samples show an **old** usage of the API.
* Code samples in `delete`, `insert` and `formatRange` methods were using wrong constructors.

## 1.0.2 - 9 / 03 / 2025

### Changed

* Removed `text` property from `EasyTextList` since we cannot make a properly caching and update of this value.
* Removed `insertText` and `removeText` methods from `EasyTextList`.
* Removed `invalidateParentCache` method from `EasyText` class.

* Updated README to include `EasyTextList` implementation.

### Added

* New constructors for `EasyTextList` class:
    ```
      EasyTextList list = EasyTextList.from(<EasyText>[]);
      EasyTextList list2 = 
        EasyTextList.easy(EasyText.fromStr(text: ''));
      EasyTextList list3 = EasyTextList.fromStr('');
    ```

## 1.0.1 - 8 / 27 / 2025

### Fixes

* `EasyAttributeStyles` does not recognize `bold` or other unknown attributes.
* `key` in FontSizeAttribute is referencing FontFamily `key.
* `merge` method from `EasyAttributeStyles` is not applying `exclusive` rules.
* Bad relative imports for attributes.

### Added

* Support to use `UnknownAttribute` instead throwing an `assertion error` during `EasyAttributeStyles.fromJson` call is being executed,
* Support to use `EasyAttributes.alternativesNames` of some `EasyAttributes` that can are used by other libraries.
* Support for missing `ScriptAttribute`.
* `str` method to `EasyText` class to get `String` easily.



## 1.0.0 - 8 / 24 / 2025

* Feat: released package
