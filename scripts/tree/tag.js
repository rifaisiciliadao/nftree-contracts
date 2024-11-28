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
    const treeId = 1
    const metadata = JSON.stringify({
        "name": "Test tree",
        "description": "Test tree description",
        "image": "https://example.com/image.png",
        "coordinates": "123.456,789.012",
        "planted_at": "2024-01-01",
        "planted_by": "John Doe"
    })
    const tx = await contract.setTreeExtendedMetadata(
        treeId,
        metadata
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
