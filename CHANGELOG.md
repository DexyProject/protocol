# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [unreleased]

### Added
 - Traded Hook to subscribe to trade events.

## [2.0.0] - 2018-04-18

### Changed
 - Vault can have multiple spenders.
 - Rearrange parameter ordering for trade function.
 - Using eth constant in exchange
 - Removed user from ```fills```
 - Renamed give / get to maker / taker.
 
### Fixed
 - Checks for rounding errors
 - Invariant with small denominations that may end with 0 value transfers. 

## [1.0.0] - 2018-04-03

### Added
 - Truffle configuration files
 - package.json
 - Solium files
 - Travis configuration
 - Base exchange contracts
