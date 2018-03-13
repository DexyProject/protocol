const libFiles = require('glob').sync('contracts/Libraries/*.sol').map(n => n.replace('contracts/', ''));
const tokens = require('glob').sync('contracts/Tokens/*.sol').map(n => n.replace('contracts/', ''));
const interfaces = ['Ownership/Ownable.sol', 'Vault/VaultInterface.sol', 'ExchangeInterface.sol']

module.exports = {
    norpc: true,
    compileCommand: '../node_modules/.bin/truffle compile',
    testCommand: 'node --max-old-space-size=4096 ../node_modules/.bin/truffle test --network coverage',
    skipFiles: tokens.concat(libFiles).concat(interfaces),
    copyNodeModules: false,
}