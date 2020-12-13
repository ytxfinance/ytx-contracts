const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades')
const LockLiquidity = artifacts.require('LockLiquidity')
const YTXV3 = artifacts.require('YTXV3')
const TestToken = artifacts.require('TestToken')

module.exports = async deployer => {
  // await deployYTX()
  // await deployLockLiquidity()
  // await setLockLiquidityContract()
}

// Returns the deployed token with the address and functionality
const deployYTX = async deployer => {
  await deployProxy(YTXV3, [], { deployer, initializer: 'initialize' });
  return await YTXV3.deployed()
}

const deployTestToken = async deployer => {
  await deployProxy(TestToken, [], { deployer, initializer: 'initialize' });
  return await TestToken.deployed()
}

const deployLockLiquidity = async (deployer, LPTokenAddress, ytxTokenAddress) => {
  await deployProxy(LockLiquidity, [LPTokenAddress, ytxTokenAddress], { deployer, initializer: 'initialize' });
  return await LockLiquidity.deployed()
}

const setLockLiquidityContract = async lockLiquidityAddress => {
  await currentYtx.setLockLiquidityContract(lockLiquidityAddress)
}