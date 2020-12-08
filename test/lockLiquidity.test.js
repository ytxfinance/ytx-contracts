const BigNumber = require('bignumber.js')
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades')
const LockLiquidity = artifacts.require('LockLiquidity')
const YTXV3 = artifacts.require('YTXV3')
const TestToken = artifacts.require('TestToken')
let testToken
let ytx
let lockLiquidity

contract('LockLiquidity', accs => {
	beforeEach(async () => {
		testToken = await deployProxy(TestToken, [])
		ytx = await deployProxy(YTXV3, [])
		lockLiquidity = await deployProxy(LockLiquidity, [
			testToken.address,
			ytx.address,
		])
		await ytx.setLockLiquidityContract(lockLiquidity.address)
		await lockLiquidity.setYtx(ytx.address)
	})

	it("should not change the price if there aren't liquidity provider", async () => {
		const ytxFeePriceBefore = await lockLiquidity.ytxFeePrice()
		await ytx.transfer(
			'0x7c5bAe6BC84AE74954Fd5672feb6fB31d2182EC6',
			BigNumber(10e18)
		)
		const ytxFeePriceAfter = await lockLiquidity.ytxFeePrice()
		assert.ok(
			ytxFeePriceBefore.eq(ytxFeePriceAfter),
			'The price should be unchanged'
		)
	})

	it('should add a liquidity provider successful with locked LP tokens', async () => {
		// First approve LPs
		const amount = BigNumber(10e18)
		await testToken.approve(lockLiquidity.address, amount)
		// Then lock liquidity
		await lockLiquidity.lockLiquidity(amount)
	})

	it('should update the ytxFee price correctly', async () => {
		const ytxFeePriceBefore = await lockLiquidity.ytxFeePrice()
		// Transfer 10 YTX tokens to another user to see if the fee generated
		// ends up creating an increase in the ytx fee price
		await ytx.transfer(
			'0x7c5bAe6BC84AE74954Fd5672feb6fB31d2182EC6',
			BigNumber(10e18)
		)
		const ytxFeePriceAfter = await lockLiquidity.ytxFeePrice()

		console.log(
			'Price before',
			String(ytxFeePriceBefore),
			'Price after',
			String(ytxFeePriceAfter)
		)
	})
})
