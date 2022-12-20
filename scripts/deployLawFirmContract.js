// imports
const { ethers, run, network } = require("hardhat");

// async main
async function main() {
  const LawFirmContractFactory = await ethers.getContractFactory("LawFirmContract");
  console.log("Deploying contract...");
  const lawFirmContract = await LawFirmContractFactory.deploy();
  await lawFirmContract.deployed();
  // what's the private key?
  // what's the rpc url?
  console.log(`Deployed contract to: ${lawFirmContract.address}`);
  // what happens when we deploy to our hardhat network

  if(network.config.chainId === 80001 && process.env.POLYGONSCAN_API_KEY){
    console.log("Waiting for block txes...");
    await lawFirmContract.deployTransaction.wait(20);
    await verify(lawFirmContract.address, []);
  }

// // Add Retailer
// let retailerName = "Adidas";
// let transactionResponse = await membershipToken.addRetailer(retailerName);
// await transactionResponse.wait(1);
// console.log("\n Add Retailer Transaction Hash:")
// console.log(transactionResponse.hash);

// // Get Token ID by Retailer Name
// let tokenId = await membershipToken.getTokenIdByRetailerName(retailerName);
// console.log("Token ID for Retailer: " + retailerName);
// console.log(tokenId);



// // Mint Tokens
// let tokenQuantity = 21;
// let ipfsURL = 'ipfs://bafyreie5k4fycgqef6hfphpplrfixvnz44fgvdffi5wsbq2m7ivi5yqr4m/metadata.json';
// let transactionResponse2 = await membershipToken.mintTokens(retailerName, tokenQuantity, ipfsURL);
// await transactionResponse2.wait(1);
// console.log("\n Mint Tokens Transaction Hash:")
// console.log(transactionResponse2.hash);
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