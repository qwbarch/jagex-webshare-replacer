# Changelog for `webshare-replacer`

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to the
[Haskell Package Versioning Policy](https://pvp.haskell.org/).

## 0.3.0.1 - 2026-02-28

- Added option to replace proxy with a random country's. Note: This is untested since it's a requested
  feature that I don't want to use my proxy replacements on to test.

## 0.3.0.0 - 2026-02-21

- Fixed a bug that caused the config to generate with no replacement country code.
- Added option to replace proxy if it fails to connect (default: false).
- User options are now saved as they are entered.

## 0.2.0.0 - 2026-02-20

- Changed configuration to be more user-friendly by prompting for inputs instead.
- **Warning:** If you have run a previous version, you will need to delete ``config.json`` and redo your settings.

## 0.1.0.1 - 2026-02-19

- Fixed active proxy count on repeated runs.

## 0.1.0.0 - 2026-02-19

- Initial release.