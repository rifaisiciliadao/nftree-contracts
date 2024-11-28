const hre = require("hardhat");
const fs = require('fs');

async function main() {
  const configs = JSON.parse(fs.readFileSync(process.env.CONFIG).toString())
  console.log('Deploying contract..')

  const provider = new ethers.providers.JsonRpcProvider(configs.provider);
  const wallet = new ethers.Wallet(configs.owner_key).connect(provider);
  const baseFeePerGas = (await provider.getFeeData()).lastBaseFeePerGas
  const baseFeePerGasBoosted = await baseFeePerGas.div(100).mul(20).add(baseFeePerGas)
  console.log('Base fee per gas:', baseFeePerGasBoosted.toString())

  // Deploy
  nonce = await wallet.getTransactionCount()
  const contract = await hre.ethers.getContractFactory(configs.contract_name);
  let arguments = [configs.default_admin, configs.minter, configs.validator]
  console.log("Arguments:", arguments)
  const contractLP = await contract.deploy(...arguments, { gasPrice: baseFeePerGasBoosted, nonce });
  console.log('Deploy transaction is: ' + contractLP.deployTransaction.hash)
  await contractLP.deployed();
  console.log("Contract deployed to:", contractLP.address);
  configs.contract_address.lp = contractLP.address

  // Save to disk
  fs.writeFileSync(process.env.CONFIG, JSON.stringify(configs, null, 4))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
