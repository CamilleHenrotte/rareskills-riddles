const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "DeleteUser";

describe(NAME, function () {
    async function setup() {
        const [owner, attackerWallet] = await ethers.getSigners();

        const VictimFactory = await ethers.getContractFactory(NAME);
        const victimContract = await VictimFactory.deploy();

        const AttackerFactory = await ethers.getContractFactory("DeleteUserAttacker");
        const attackerContract = await AttackerFactory.connect(attackerWallet).deploy(victimContract.address);
        await victimContract.deposit({ value: ethers.utils.parseEther("1") });

        return { victimContract, attackerContract, attackerWallet };
    }

    describe("exploit", async function () {
        let victimContract, attackerWallet, attackerContract;
        before(async function () {
            ({ victimContract, attackerWallet, attackerContract } = await loadFixture(setup));
        });

        it("conduct your attack here", async function () {
            await attackerContract.attack({ value: ethers.utils.parseEther("1") });
        });

        after(async function () {
            expect(await ethers.provider.getBalance(victimContract.address)).to.be.equal(0);
            expect(await ethers.provider.getTransactionCount(attackerWallet.address)).to.equal(
                1,
                "must exploit one transaction"
            );
        });
    });
});
