const BigNumber = require('bignumber.js')
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades')
const NFTManager = artifacts.require('NFTManager')
const YTXV3 = artifacts.require('YTXV3')
const TestToken = artifacts.require('TestToken')
const LockLiquidity = artifacts.require('LockLiquidity')
let yfs // YFS is a TestToken
let ytx
let LPToken
let gameTreasury
let lockLiquidity
let managerInstance

contract('NFTManager', accs => {
	const defaultAmount = BigNumber(1e19)
	const defaultPriceIncrease = BigNumber(9e15)

	beforeEach(async () => {
        LPToken = await deployProxy(TestToken, [])
		gameTreasury = await deployProxy(TestToken, [])
		yfs = await deployProxy(TestToken, [])
        ytx = await deployProxy(YTXV3, [gameTreasury.address])
        lockLiquidity = await deployProxy(LockLiquidity, [
			LPToken.address,
			ytx.address,
		])
		managerInstance = await deployProxy(NFTManager, [
			ytx.address,
            yfs.address,
            'https://example-base-uri.com/',
		])
		await ytx.setLockLiquidityContract(lockLiquidity.address)
        await lockLiquidity.setYtx(ytx.address)
        console.log('managerInstance', managerInstance)
	})

	// Works
	it("should not change the price if there aren't liquidity provider", async () => {
		// const ytxFeePriceBefore = await lockLiquidity.ytxFeePrice()
		// // Send YTX to a random address to activate the fee system
		// await ytx.transfer(
		// 	'0x7c5bAe6BC84AE74954Fd5672feb6fB31d2182EC6',
		// 	defaultAmount
		// )
		// const ytxFeePriceAfter = await lockLiquidity.ytxFeePrice()
		// assert.ok(
		// 	ytxFeePriceBefore.eq(ytxFeePriceAfter),
		// 	'The price should be unchanged'
		// )
	})
})
