const { assert, expect } = require("chai")
const { getNamedAccounts, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Polla Unit Test", async function () {
          let polla, pollaEntranceFee, deployer, pollaEleccionJugador

          beforeEach(async function () {
              deployer = (await getNamedAccounts()).deployer
              await deployments.fixture(["all"])
              polla = await ethers.getContract("Polla", deployer)
              pollaEntranceFee = await polla.getEntry_Fee()
          })

          describe("constructor", async function () {
              it("initializes the polla correctly", async function () {
                  const polla_state = await polla.getPOLLA_STATE()
                  assert.equal(polla_state.toString(), "0")
              })
          })

          describe("enterPolla", async function () {
              it("reverts when you don't pay enough", async function () {
                  await expect(polla.enterPolla()).to.be.revertedWith("Polla_NotAmountToEnter")
              })
              it("record players when they enter", async function () {
                  await polla.enterPolla({ value: pollaEntranceFee })
                  const playerFromContract = await polla.getPlayer(0)
                  assert.equal(playerFromContract, deployer)
              })
              it("emits event on enter", async function () {
                  await expect(polla.enterPolla({ value: pollaEntranceFee })).to.emit(
                      polla,
                      "PollaEnter"
                  )
              })
          })
      })
