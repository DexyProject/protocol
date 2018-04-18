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
 - Exchange: (0xae84be55ca6f4486911a7bb33a34293327ba52a5)[https://etherscan.io/address/0xae84be55ca6f4486911a7bb33a34293327ba52a5]
 - Vault: (0x89b2eab864e30691804d3e1be7b007c49864a286)[https://etherscan.io/address/0x89b2eab864e30691804d3e1be7b007c49864a286]

#### Ropsten
 - Exchange: [0x4f09a1292a4ec37e7186fe2d9bdfd2252427c5e9](https://ropsten.etherscan.io/address/0x4f09a1292a4ec37e7186fe2d9bdfd2252427c5e9)
 - Vault: [0x2be091449b89a15fb6b959f3da35ffb419620f89](https://ropsten.etherscan.io/address/0x2be091449b89a15fb6b959f3da35ffb419620f89)

#### Kovan
 - Exchange: [0xc018f2b0d8608b43b2bbbe29f5cd21e852b0bd96](https://kovan.etherscan.io/address/0xc018f2b0d8608b43b2bbbe29f5cd21e852b0bd96)
 - Vault: [0x5c64dbdc3618995b76677b1d3a0d3b1a5c21b41f](https://kovan.etherscan.io/address/0x5c64dbdc3618995b76677b1d3a0d3b1a5c21b41f)

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
