const libFiles = require('glob').sync('contracts/Libraries/*.sol').map(n => n.replace('contracts/', ''));
const tokens = require('glob').sync('contracts/Tokens/*.sol').map(n => n.replace('contracts/', ''));
const interfaces = ['Ownership/Ownable.sol', 'Vault/VaultInterface.sol', 'ExchangeInterface.sol', 'Migrations.sol'];

module.exports = {
    norpc: true,
    skipFiles: tokens.concat(libFiles).concat(interfaces),
    copyNodeModules: false,
}
