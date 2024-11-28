const { ethers, utils } = require("ethers");
const fs = require('fs')


async function main() {
    const configs = JSON.parse(fs.readFileSync(process.env.CONFIG).toString())
    const artifact = JSON.parse(fs.readFileSync('./artifacts/contracts/RifaiNFTree.sol/RifaiNFTree.json'))
    const provider = new ethers.providers.JsonRpcProvider(configs.provider);
    const wallet = new ethers.Wallet(configs.owner_key).connect(provider)
    const contract = new ethers.Contract(configs.contract_address, artifact.abi, wallet)

    // Adopt a tree
    const treeIds = [1, 2, 3]
    const metadata = await contract.getTreeExtendedMetadataBatch(treeIds)
    console.log(metadata)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
