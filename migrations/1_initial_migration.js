const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades')
const LockLiquidityYTXETH = artifacts.require('LockLiquidityYTXETH')
const YTXV3 = artifacts.require('YTXV3')
const TestToken = artifacts.require('TestToken')

module.exports = async function(deployer) {
  await deployProxy(TestToken, [], { deployer, initializer: 'initialize' });
  await deployProxy(YTXV3, [], { deployer, initializer: 'initialize' });
  const currentTestToken = await TestToken.deployed()
  const currentYtx = await YTXV3.deployed()

  await deployProxy(LockLiquidityYTXETH, [currentTestToken, currentYtx], { deployer, initializer: 'initialize' });
  const currentTreasury = await LockLiquidityYTXETH.deployed()
  await currentYtx.setTreasury(currentTreasury)

  const setTreasury = await currentYtx.treasury()
  console.log('Set treasury', setTreasury)
}
