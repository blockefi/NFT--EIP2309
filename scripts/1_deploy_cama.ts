import { ethers } from 'hardhat';

async function main() {
  const CAMA = await ethers.getContractFactory("contracts/CAMA.sol:AppolloAddress");
  const cama = await CAMA.deploy();
  console.log("cama deployed to:", cama.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
