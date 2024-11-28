const { ethers, utils } = require("ethers");
const fs = require('fs')


async function main() {
    const configs = JSON.parse(fs.readFileSync(process.env.CONFIG).toString())
    const artifact = JSON.parse(fs.readFileSync('./artifacts/contracts/RifaiNFTree.sol/RifaiNFTree.json'))
    const provider = new ethers.providers.JsonRpcProvider(configs.provider);
    const wallet = new ethers.Wallet(configs.owner_key).connect(provider)
    const contract = new ethers.Contract(configs.contract_address, artifact.abi, wallet)

    // Adopt a tree
    const campaignId = 1
    const tx = await contract.adoptTree(
        campaignId,
        wallet.address
    )
    console.log("Waiting for transaction to be confirmed...", tx.hash)
    const receipt = await tx.wait()
    console.log("Gas used:", receipt.gasUsed.toString())
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
