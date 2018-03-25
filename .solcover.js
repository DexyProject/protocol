const tokens = require('glob').sync('contracts/Tokens/*.sol').map(n => n.replace('contracts/', ''));
const interfaces = [
    'Ownership/Ownable.sol',
    'Vault/VaultInterface.sol',
    'ExchangeInterface.sol',
    'Migrations.sol',
    'Libraries/SafeMath.sol'
];

module.exports = {
    norpc: true,
    skipFiles: tokens.concat(interfaces),
    copyNodeModules: false,
};
