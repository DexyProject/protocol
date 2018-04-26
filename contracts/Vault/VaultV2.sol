pragma solidity ^0.4.23;

import "./Connectors/ConnectorInterface.sol";

contract VaultV2 {

    event Deposited(address token, address user, uint amount);
    event Withdrawn(address token, address user, uint amount);

    mapping (bytes4 => ConnectorInterface) public receivers;
    mapping (address => ConnectorInterface) public connectors;

    function () payable {
        // @todo move deposit into here potentially

        ConnectorInterface connector = receivers[msg.sig];
        require(address(connector) != 0x0);

        assembly {
            calldatacopy(0x0, 0x0, calldatasize)

            result := delegatecall(sub(gas, 10000), connector, 0x0, calldatasize, 0, 0)
            size := returndatasize

            returndatacopy(0, 0, size)

            switch result case 0 { revert(0, size) }
            default { return(0, size) }
        }
    }

    function deposit(address token, address user, uint amount) external payable {
        ConnectorInterface connector = connectors[token];
        connectors[token].delegatecall.value(msg.value)(
            connector.deposit.selector,
            user,
            amount
        );

        emit Deposited(token, user, amount);
    }

    function withdraw(address token, address user, uint amount) external {
        ConnectorInterface connector = connectors[token];
        require(connector.balanceOf(token, user) >= amount);
        connector.delegatecall(connector.withdraw.selector, token, user, amount);

        emit Withdrawn(token, user, amount);
    }
}
