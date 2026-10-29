
import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { network } from "hardhat";
import { getAddress, parseEther } from "viem";

const { viem, networkHelpers } = await network.create();

describe("SavingsVault (TypeScript integration)", function () {
  async function deployFixture() {
    const [owner, alice, bob] = await viem.getWalletClients();
    const vault = await viem.deployContract("SavingsVault");
    const publicClient = await viem.getPublicClient();

    return { vault, owner, alice, bob, publicClient };
  }

  it("emits Withdrawn with the fee and keeps the fee in the vault", async function () {
    const { vault, alice, publicClient } =
      await networkHelpers.loadFixture(deployFixture);

    await vault.write.deposit({
      value: parseEther("1"),
      account: alice.account,
    });

    await viem.assertions.emitWithArgs(
      vault.write.withdrawAll({ account: alice.account }),
      vault,
      "Withdrawn",
      [
        getAddress(alice.account.address),
        parseEther("1"),
        parseEther("0.005"),
      ],
    );

    const vaultBalance = await publicClient.getBalance({
      address: vault.address,
    });

    assert.equal(vaultBalance, parseEther("0.005"));
    assert.equal(await vault.read.collectedFees(), parseEther("0.005"));
  });

  it("reverts when there is nothing to withdraw", async function () {
    const { vault, alice } =
      await networkHelpers.loadFixture(deployFixture);

    await viem.assertions.revertWith(
      vault.write.withdrawAll({ account: alice.account }),
      "nothing to withdraw",
    );
  });

  it("reverts when a non-owner tries to claim fees", async function () {
    const { vault, alice } =
      await networkHelpers.loadFixture(deployFixture);

    await viem.assertions.revertWith(
      vault.write.claimFees([alice.account.address], {
        account: alice.account,
      }),
      "not owner",
    );
  });

  it("keeps the balances of two depositors independent", async function () {
    const { vault, alice, bob } =
      await networkHelpers.loadFixture(deployFixture);

    await vault.write.deposit({
      value: parseEther("1"),
      account: alice.account,
    });

    await vault.write.deposit({
      value: parseEther("2"),
      account: bob.account,
    });

    assert.equal(
      await vault.read.balances([alice.account.address]),
      parseEther("1"),
    );

    assert.equal(
      await vault.read.balances([bob.account.address]),
      parseEther("2"),
    );
  });
});
