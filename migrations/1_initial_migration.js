const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades')
const LockLiquidity = artifacts.require('LockLiquidity')
const YTXV3 = artifacts.require('YTXV3')
const YFS = artifacts.require('YFS')
const NFTManager = artifacts.require('NFTManager')
const DistributeEarnings = artifacts.require('DistributeEarnings')
const BigNumber = require('bignumber.js')

const uris = [
  'adembite.json',
  'archment.json',
  'borarite.json',
  'broctanite.json',
  'harmepite.json',
  'idrosite.json',
  'magboleite.json',
  'massaz.json',
  'nicmond.json',
  'paryite.json',
  'pasciclase.json',
  'rosatorite.json',
  'zabukite.json',
  'zanspore.json',
]

module.exports = async deployer => {
  const baseURI = 'https://ytxfinance.github.io/ytx-server/'

  // DistributeEarnings
  await deployProxy(DistributeEarnings, [], { deployer, initializer: 'initialize' })
  const distributeEarnings = await DistributeEarnings.deployed()

  // YTX & YFS
  const ytx = await deployProxy(YTXV3, [distributeEarnings.address], { deployer, initializer: 'initialize' })
  const yfs = await deployProxy(YFS, ['0x0000000000000000000000000000000000000000'], { deployer, initializer: 'initialize' })
  console.log('YTX is', ytx.address)
  console.log('YFS is', yfs.address)

  // LockLiquidity
  const lockLiquidity = await deployProxy(LockLiquidity, [
    distributeEarnings.address,
    ytx.address,
  ], { deployer, initializer: 'initialize' })
  console.log('LockLiquidity is', lockLiquidity.address)

  // Config
  await ytx.setLockLiquidityContract(lockLiquidity.address)
  await lockLiquidity.setYtx(ytx.address)

  // NFTManager
  await deployProxy(NFTManager, [
    ytx.address,
    yfs.address,
    baseURI,
  ], { deployer, initializer: 'initialize' })
  const manager = await NFTManager.deployed()
  await yfs.setManager(manager.address)
  console.log('Manager is', manager.address)
  // createBlueprint(string memory _tokenURI, uint256 _maxMint, uint256 _ytxCost, uint256 _yfsCost)
  await manager.createBlueprint('adembite.json', BigNumber(10000), BigNumber(0.1e18), BigNumber(0.1e18))
  await manager.createBlueprint('archment.json', BigNumber(10000), BigNumber(0.1e18), BigNumber(0.1e18))
  await manager.createBlueprint('borarite.json', BigNumber(10000), BigNumber(0.1e18), BigNumber(0.1e18))
  await manager.createBlueprint('idrosite.json', BigNumber(10000), BigNumber(0.1e18), BigNumber(0.1e18))
  await manager.createBlueprint('rosatorite.json', BigNumber(10000), BigNumber(0.1e18), BigNumber(0.1e18))
  await manager.createBlueprint('zanspore.json', BigNumber(10000), BigNumber(0.1e18), BigNumber(0.1e18))

  await manager.createBlueprint('broctanite.json', BigNumber(3000), BigNumber(1e18), BigNumber(1e18))
  await manager.createBlueprint('harmepite.json', BigNumber(3000), BigNumber(1e18), BigNumber(1e18))
  await manager.createBlueprint('paryite.json', BigNumber(3000), BigNumber(1e18), BigNumber(1e18))
  await manager.createBlueprint('zabukite.json', BigNumber(3000), BigNumber(1e18), BigNumber(1e18))

  await manager.createBlueprint('nicmond.json', BigNumber(500), BigNumber(10e18), BigNumber(10e18))
  await manager.createBlueprint('pasciclase.json', BigNumber(500), BigNumber(10e18), BigNumber(10e18))

  await manager.createBlueprint('magboleite.json', BigNumber(30), BigNumber(100e18), BigNumber(100e18))
  await manager.createBlueprint('massaz.json', BigNumber(30), BigNumber(100e18), BigNumber(100e18))
}