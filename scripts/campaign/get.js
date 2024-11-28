const { ethers, utils } = require("ethers");
const fs = require('fs')


async function main() {
    const configs = JSON.parse(fs.readFileSync(process.env.CONFIG).toString())
    const artifact = JSON.parse(fs.readFileSync('./artifacts/contracts/RifaiNFTree.sol/RifaiNFTree.json'))
    const provider = new ethers.providers.JsonRpcProvider(configs.provider);
    const wallet = new ethers.Wallet(configs.owner_key).connect(provider)
    const contract = new ethers.Contract(configs.contract_address, artifact.abi, wallet)

    // Create the campaign
    const campaign = await contract.plantingCampaigns(1)
    console.log("Campaign metadata:", campaign.campaignMetadata)
    console.log("Campaign start date:", new Date(campaign.startDate * 1000).toLocaleString())
    console.log("Campaign end date:", new Date(campaign.endDate * 1000).toLocaleString())
    console.log("Campaign total trees:", campaign.totalTrees.toString())
    console.log("Campaign trees planted:", campaign.treesPlanted.toString())
    console.log("Campaign beneficiary:", campaign.beneficiary)
    console.log("Campaign contribute token:", campaign.contributeToken)
    console.log("Campaign contribute amount:", campaign.contributeAmount.toString())
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
