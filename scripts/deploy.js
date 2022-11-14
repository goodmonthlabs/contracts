async function main() {

  const [deployer] = await ethers.getSigners("0x29c6a598a3447F69ff52b9b96dadf630750886FD");  

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Token = await ethers.getContractFactory("CAKE721A");   
  const client = "0x29c6a598a3447F69ff52b9b96dadf630750886FD" 
  const token = await Token.deploy(["Probably Nothing Cup","PNC"], [64,ethers.utils.parseEther("0.1"),1,1], [1667517644, 1667517644], client, [client], [1], client, 50);

  console.log("Token address:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });