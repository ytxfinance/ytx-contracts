const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades')
const DistributeEarnings = artifacts.require('DistributeEarnings')
const YTX = artifacts.require('YTX')
const YTXV2 = artifacts.require('YTXV2')

module.exports = async function(deployer) {
  const existing = await YTX.deployed()
  // 1. Initial deployment
  // await deployProxy(YTX, [], { deployer, initializer: 'initialize' });
  // 2. Deploy upgraded contract
  await upgradeProxy(existing.address, YTXV2, { deployer })
  // await deployProxy(DistributeEarnings);
}
