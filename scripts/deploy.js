const hre = require("hardhat");

async function main() {

  const BST = await hre.ethers.getContractFactory("BetSportToken");
  const bst = await BST.deploy();
  await bst.waitForDeployment();

  let account = await bst.getAddress();
  console.log("BetSportToken deployed to: ", bst.target);

  const Gambling = await hre.ethers.getContractFactory("Gambling");
  const gambling = await Gambling.deploy(
      "35288072947669997916278381871618468922383519722879305904038802101294624721639",
      "0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B",
      "0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae",
      40000,
      3,
      1,
      account
  )
  await gambling.waitForDeployment();

  console.log("Gambling Game deployed to: ", gambling.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


