# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
