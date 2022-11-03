const { ethers, network } = require("hardhat")
const fs = require("fs")

const FRONT_END_ADDRESSES_FILE =
    "../nextjs-smartcontract-polla-fcc/constants/contractAddresses.json"
const FRONT_END_ABI_FILE = "../nextjs-smartcontract-polla-fcc/constants/abi.json"

module.exports = async function () {
    if (process.env.UPDATE_FRONT_END) {
        console.log("Updating front end ...")
        updateContractAddresses()
        updateAbi()
    }
}

async function updateAbi() {
    const polla = await ethers.getContract("Polla")
    fs.writeFileSync(FRONT_END_ABI_FILE, polla.interface.format(ethers.utils.FormatTypes.json))
}

async function updateContractAddresses() {
    const polla = await ethers.getContract("Polla")
    const chainId = network.config.chainId.toString()
    const currentAddresses = JSON.parse(fs.readFileSync(FRONT_END_ADDRESSES_FILE, "utf8"))
    if (chainId in currentAddresses) {
        if (!currentAddresses[chainId].includes(polla.address)) {
            currentAddresses[chainId].push(raffle.address)
        }
    } else {
        currentAddresses[chainId] = [polla.address]
    }
    fs.writeFileSync(FRONT_END_ADDRESSES_FILE, JSON.stringify(currentAddresses))
}

module.exports.tags = ["all", "frontend"]
