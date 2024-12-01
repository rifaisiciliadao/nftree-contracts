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
    const beneficiary = "0x108675f06FdEc2F12af3fFbf8171C3335E1efA92"
    const contributeToken = configs.usdc
    const contributeAmount = 10 * 10 ** 6 // 10 USDC
    const rifaiDaoFee = 2 * 10 ** 6 // 2 USDC
    const campaignMetadata = JSON.stringify({
        "name": "Maccia Festival 2024",
        "organizer": "CaratoDAO",
        "location": "Ragusa, Italia",
        "description": "The Maccia Festival is a project created by CaratoDAO, an informal network of environmental associations in the Ragusa area, which carries out reforestation and environmental education activities every year. This year we will establish an oak grove and an agroforest. The planting event will be done in the Public Park 'Alessandro Licitra' in Ragusa on 22th of December 2024.",
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
