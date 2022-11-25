const BulletproofMultiNFTGenesis = artifacts.require("BulletproofMultiNFTGenesis");

require("dotenv").config();

const deployWalletAddress = process.env["DEPLOY_WALLET_ADDRESS"];
module.exports = async function (deployer) {
  await deployer.deploy(
    BulletproofMultiNFTGenesis,
    {from: deployWalletAddress}
  );
  const instance = await BulletproofMultiNFTGenesis.deployed();
};