//0xf240D8E0B9Cb493b380791b65CAFEef62080E5A1
//0x7a28d142Bf1559C7e620CCdcb60ffBD31104bA69
import { ethers } from 'hardhat';

async function main() {
  // We get the contract to deploy
  const owner = "0x7a28d142Bf1559C7e620CCdcb60ffBD31104bA69";//change this before deploying
  const implAddress = '0xa5d8E9ED9c270fb6c93A8193c25c57e7508dD3E4';//check this for mainnet
  const Proxy = await ethers.getContractFactory("OwnedUpgradeabilityProxy");
  const impl = await ethers.getContractFactory("contracts/CAMA.sol:AppolloAddress");
  const proxy = await Proxy.deploy();
  console.log("Proxy deployed to:", proxy.address);

  const initializeData = impl.interface.encodeFunctionData('initialize', [
    owner, 1000000000, "Appollo Address", "CAMA"
  ]);

  await proxy.upgradeToAndCall(implAddress, initializeData);

  const camaImpl = await proxy.implementation();

  console.log('Implementation is: ', camaImpl);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
