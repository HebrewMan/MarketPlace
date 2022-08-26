const api = require('./api');

async function main() {

  // check api service healthy
  var isHealthy = await api.checkHealthy()
  if (!isHealthy) {
    return
  }

  // // get arc governance
  // const arcGovernance = await api.getArcGovernance()
  // if (arcGovernance === false || arcGovernance === "") {
  //   console.error("undefined arc governance address");
  //   return;
  // }

  // console.log("arc governance:", arcGovernance)

  let contractsList = api.contracts.split(',')

  if (contractsList.length == 0) {
    console.error('no contract to deploy');
    return false;
  }

  // ethers is avaialble in the global scope
  const [deployer] = await ethers.getSigners()
  console.log(
    'Deploying the contracts with the account:',
    await deployer.getAddress()
  )

  for (let i = 0; i < contractsList.length; i++) {
    let contractName = String(contractsList[i]);

    console.log("deploy contract:", contractName);

    const factory = await ethers.getContractFactory(contractName);
    const contract = await factory.deploy();

    await contract.deployed();

    console.log(contractName + ' address:', contract.address);

    // post contract address to database
    await api.postAddr(contractName, contract.address);
  }

  // sync contract abi and bytecode to database
  await api.syncContracts();

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })