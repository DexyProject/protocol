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
 - Exchange: [0x9d160e257f1dff52ec81d5a4e7326dd82e144177](https://etherscan.io/address/0x9d160e257f1dff52ec81d5a4e7326dd82e144177)
 - Vault: [0x54b0de285c15d27b0daa687bcbf40cea68b2807f](https://etherscan.io/address/0x54b0de285c15d27b0daa687bcbf40cea68b2807f)

#### Ropsten
 - Exchange: [0xbdf08896a74a1d02b06a4e9bacc2f1cff1537f1d](https://ropsten.etherscan.io/address/0xbdf08896a74a1d02b06a4e9bacc2f1cff1537f1d)
 - Vault: [0x301700d86fc22befdf71ed7bb87425bf4e9dea65](https://ropsten.etherscan.io/address/0x301700d86fc22befdf71ed7bb87425bf4e9dea65)

#### Kovan
 - Exchange: [0xdc34b283d1fedd95fa6631ad2d0454cc088f8c93](https://kovan.etherscan.io/address/0xdc34b283d1fedd95fa6631ad2d0454cc088f8c93)
 - Vault: [0x6bfb55b095d3b33dead74fa0a0cfe2aa5ef88d76](https://kovan.etherscan.io/address/0x6bfb55b095d3b33dead74fa0a0cfe2aa5ef88d76)

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
