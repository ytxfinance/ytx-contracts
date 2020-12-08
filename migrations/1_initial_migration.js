const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades')
const LockLiquidity = artifacts.require('LockLiquidity')
const YTXV3 = artifacts.require('YTXV3')
const TestToken = artifacts.require('TestToken')

module.exports = async deployer => {
  await deployProxy(TestToken, [], { deployer, initializer: 'initialize' });
  await deployProxy(YTXV3, [], { deployer, initializer: 'initialize' });
  const currentTestToken = await TestToken.deployed()
  const currentYtx = await YTXV3.deployed()
  console.log('Deployed test token', currentTestToken.address)
  console.log('Deployed YTX', currentYtx.address)
  await deployProxy(LockLiquidity, [currentTestToken.address, currentYtx.address], { deployer, initializer: 'initialize' });
  const lockLiquidityContract = await LockLiquidity.deployed()
  console.log('Deployed LockLiquidity', lockLiquidityContract.address)
  console.log('Executing setLockLiquidityContract...')
  await currentYtx.setLockLiquidityContract(lockLiquidityContract.address)
}
