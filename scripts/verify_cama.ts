const har = require("hardhat");
// 0xf240D8E0B9Cb493b380791b65CAFEef62080E5A1
// 0x823e620f112154b38C250c1595Ae0df2916d0dC8
async function main() {
  await har.run("verify:verify", {
    address: "0xa5d8E9ED9c270fb6c93A8193c25c57e7508dD3E4",
    constructorArguments: [],
    contract: "contracts/CAMA_flat.sol:AppolloAddress",
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });