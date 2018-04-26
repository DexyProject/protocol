# DEXY

[![Build Status](https://travis-ci.com/DexyProject/contracts.svg?token=SGE7GHsjEHmsR4VosLJx&branch=development)](https://travis-ci.com/DexyProject/contracts) [![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)

Smart Contracts for the DEXY exchange project.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Installing

DEXY uses npm to manage dependencies, therefore the installation process is kept simple:

```
npm install
```

### Running tests

DEXY uses truffle for its ethereum development environment. All tests can be run using truffle:

```
truffle test
```

To run linting, use solium:

```
solium --dir ./contracts
```

### Deployed Addresses

#### Mainnet
 - Exchange: [0x1d150cfcd9bfa01e754e034442341ba85b85f1bb](https://etherscan.io/address/0x1d150cfcd9bfa01e754e034442341ba85b85f1bb)
 - Vault: [0x3956925d7d5199a6db1f42347fedbcd35312ae82](https://etherscan.io/address/0x3956925d7d5199a6db1f42347fedbcd35312ae82)

#### Ropsten
 - Exchange: [0xeea40bf84bd146ec53063b6aacfec250e23e200b](https://ropsten.etherscan.io/address/0xeea40bf84bd146ec53063b6aacfec250e23e200b)
 - Vault: [0xbac2d30ecf6e22080ad8d11c892456c569a2f4dd](https://ropsten.etherscan.io/address/0xbac2d30ecf6e22080ad8d11c892456c569a2f4dd)

#### Kovan
 - Exchange: [0x0fc2843d2bb414a896cbbba613c75e1d05e2eee4](https://kovan.etherscan.io/address/0x0fc2843d2bb414a896cbbba613c75e1d05e2eee4)
 - Vault: [0xf7d3db5afbee4e0a4f0935133fb71f57633f51a5](https://kovan.etherscan.io/address/0xf7d3db5afbee4e0a4f0935133fb71f57633f51a5)

## Built With
* [Truffle](https://github.com/trufflesuite/truffle) - Ethereum development environment 

## Authors

* **Dean Eigenmann** - [decanus](https://github.com/decanus)
* **Matthew Di Ferrante** - [mattdf](https://github.com/mattdf)

See also the list of [contributors](https://github.com/DexyProject/contracts/contributors) who participated in this project.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/DexyProject/contracts/tags).

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details
