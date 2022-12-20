// imports
const { ethers, run, network } = require("hardhat");

// async main
async function main() {
  const FactoryERC1155Factory = await ethers.getContractFactory("FactoryERC1155");
  console.log("Deploying contract...");
  const factoryERC1155 = await FactoryERC1155Factory.deploy();
  await factoryERC1155.deployed();
  // what's the private key?
  // what's the rpc url?
  console.log(`Deployed contract to: ${factoryERC1155.address}`);
  // what happens when we deploy to our hardhat network

  if(network.config.chainId === 80001 && process.env.POLYGONSCAN_API_KEY){
    console.log("Waiting for block txes...");
    await factoryERC1155.deployTransaction.wait(20);
    await verify(factoryERC1155.address, []);
  }

  // Create LoyaltyNFT token
  let contractName = "LoyaltyNFT";
  let tokenUri = "";
  let ids = [];
  let names = [];
  let tokenContractAddress = await factoryERC1155.deployERC1155(contractName, tokenUri, ids, names);
  console.log(tokenContractAddress);
  // let instance = await ERC1155Token.at(tokenContractAddress);
  

  // Add Retailer
  let index = 0;
  let retailerName = "Adidas";
  let tokenId = 1;
  const transactionResponse = await factoryERC1155.addRetailer(index, retailerName, tokenId);
  console.log(transactionResponse);

  // Mint NFT related to retailer
  let index2 = 0;
  let name = "Adidas";
  let amount = "24";
  let metadata = "ipfs://bafyreie5k4fycgqef6hfphpplrfixvnz44fgvdffi5wsbq2m7ivi5yqr4m/metadata.json";
  const transactionResponse2 = await factoryERC1155.mintERC1155(index2, name, amount, metadata);
  console.log(transactionResponse2);

  // Get token's retailers
  // let tokenRetailers = instance.names;
  // console.log(tokenRetailers);



  // const currentValue = await simpleStorage.retrieve();
  // console.log(`Current value is: ${currentValue}`);

  // Update the current value
  // const transactionResponse = await simpleStorage.store(7);
  // await transactionResponse.wait(1);
  // const updatedValue = await simpleStorage.retrieve();
  // console.log(`Updated value is: ${updatedValue}`);
}

async function verify(contractAddress, args){
  // async (contractAddress, args) => {
    console.log("Verifying contract...");
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args
    });
  }
  catch(e) {
    if(e.message.toLowerCase().includes("already verified")){
      console.log("Already Verified!");
    }
    else{
      console.log(e);
    }
  }

}

// main
main().then(() => {
  process.exit(0);
}).catch((error) => {
  console.error(error);
  process.exit(1);
})