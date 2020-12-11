const BigNumber = require('bignumber.js')
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades')
const LockLiquidity = artifacts.require('LockLiquidity')
const YTXV3 = artifacts.require('YTXV3')
const TestToken = artifacts.require('TestToken')
let testToken
let ytx
let lockLiquidity

contract('LockLiquidity', accs => {
	const defaultAmount = BigNumber(10e18)

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

	// Works
	it("should not change the price if there aren't liquidity provider", async () => {
		const ytxFeePriceBefore = await lockLiquidity.ytxFeePrice()
		// Send YTX to a random address to activate the fee system
		await ytx.transfer(
			'0x7c5bAe6BC84AE74954Fd5672feb6fB31d2182EC6',
			defaultAmount,
		)
		const ytxFeePriceAfter = await lockLiquidity.ytxFeePrice()
		assert.ok(
			ytxFeePriceBefore.eq(ytxFeePriceAfter),
			'The price should be unchanged'
		)
	})

	// Works
	it('should add a liquidity provider successful with locked LP tokens', async () => {
		// Add some fee YTX tokens to distribute
		await ytx.transfer(
			'0x7c5bAe6BC84AE74954Fd5672feb6fB31d2182EC6',
			defaultAmount,
		)
		// First approve LPs
		await testToken.approve(lockLiquidity.address, defaultAmount)
		// Then lock liquidity
		await lockLiquidity.lockLiquidity(defaultAmount)
	})

	// Works
	it('should setup the initial ytxFeePrice', async () => {
		const expectedFee = 1e16 // From a 10e18 transfer, a 1% fee is .1e18
		await addInitialLiquidityWithFee(defaultAmount, ytx, testToken, lockLiquidity,)
		const updatedYtxFeePrice = String(await lockLiquidity.ytxFeePrice())

		assert.ok(updatedYtxFeePrice == 1e18 + expectedFee, 'The updated ytxFeePrice is not correct')
		assert.ok(updatedYtxFeePrice * defaultAmount == defaultAmount * (1e18 + expectedFee), 'The converted value is not correct')
	})

	// Works
	it('should update the ytxFee price correctly after the initial price', async () => {
		const expectedFee = 1e16 // From a 10e18 transfer, a 1% fee is .1e18
		await addInitialLiquidityWithFee(defaultAmount, ytx, testToken, lockLiquidity)
		// Add some fee YTX tokens to distribute and see if the price changes
		await ytx.transfer(
			'0x7c5bAe6BC84AE74954Fd5672feb6fB31d2182EC6',
			defaultAmount,
		)

		const finalUpdatedYtxFeePrice = String(await lockLiquidity.ytxFeePrice())
		assert.ok(finalUpdatedYtxFeePrice == 1e18 + expectedFee * 2, 'The final updated ytxFeePrice is not correct after 2 liquidity provisions and providers')
	})
})

const addInitialLiquidityWithFee = async (defaultAmount, ytx, testToken, lockLiquidity) => {
	// Add some fee YTX tokens to distribute
	await ytx.transfer(
		'0x7c5bAe6BC84AE74954Fd5672feb6fB31d2182EC6',
		defaultAmount,
	)
	// First approve LPs
	await testToken.approve(lockLiquidity.address, defaultAmount)
	// Then lock liquidity
	await lockLiquidity.lockLiquidity(defaultAmount)
}