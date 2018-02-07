pragma solidity ^0.4.18;

contract Token {

    mapping (address => uint) balances;

    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender] - value;
        balances[to] = balances[to] + value;
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
        balances[from] = balances[from] - value;
        balances[to] = balances[to] + value;
        return true;
    }

    function mint(address to, uint _amount) public {
        balances[to] = balances[to] + _amount;
    }
}
