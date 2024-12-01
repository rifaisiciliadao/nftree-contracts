const { ethers } = require("ethers");
const fs = require('fs')


async function main() {
    const configs = JSON.parse(fs.readFileSync(process.env.CONFIG).toString())
    const artifact = JSON.parse(fs.readFileSync('./artifacts/contracts/RifaiNFTree.sol/RifaiNFTree.json'))
    const provider = new ethers.providers.JsonRpcProvider(configs.provider);
    const wallet = new ethers.Wallet(configs.owner_key).connect(provider)
    const contract = new ethers.Contract(configs.contract_address, artifact.abi, wallet)

    // Create the campaign
    const campaignId = 1
    const startDate = Math.floor(Date.now() / 1000); // 1 minute from now
    const endDate = startDate + 30 * 24 * 60 * 60 // 30 days from now
    const totalTrees = 20
    const beneficiary = configs.owner_address
    const contributeToken = configs.usdc
    const contributeAmount = 10 * 10 ** 6 // 10 USDC
    const rifaiDaoFee = 2 * 10 ** 6 // 2 USDC
    const campaignMetadata = JSON.stringify({
        "name": "Maccia Festival 2024",
        "organizer": "CaratoDAO",
        "location": "Ragusa, Italia",
        "description": "Il maccia festival è un progetto nato da CaratoDAO, una rete informale di associazioni ambientali nel ragusano, che ogni anno effettua attività di riforestazione e di educazione ambientale. Quest'anno metteremo a dimora un querceto e un'agroforesta.",
        "image": "https://ipfs.io/ipfs/QmRNFBPs99RixtSjp4chzUcKBCMiYJkUS89ZqrPEBFhzdJ"
    })
    const tx = await contract.setPublicCampaign(
        campaignId,
        startDate,
        endDate,
        totalTrees,
        beneficiary,
        contributeToken,
        contributeAmount,
        rifaiDaoFee,
        campaignMetadata
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
