const BigNumber = require('bignumber.js')
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades')
const LockLiquidity = artifacts.require('LockLiquidity')
const YTXV3 = artifacts.require('YTXV3')
const TestToken = artifacts.require('TestToken')
let testToken
let ytx
let lockLiquidity

contract('LockLiquidity', accs => {
	const defaultAmount = BigNumber(1e19)
	const defaultPriceIncrease = BigNumber(1e16)

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
			defaultAmount
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
			defaultAmount
		)
		// First approve LPs
		await testToken.approve(lockLiquidity.address, defaultAmount)
		// Then lock liquidity
		await lockLiquidity.lockLiquidity(defaultAmount)
	})

	// Works
	it.only('should setup the initial ytxFeePrice', async () => {
		await addInitialLiquidityWithFee(
			defaultAmount,
			ytx,
			testToken,
			lockLiquidity
		)
		const updatedYtxFeePrice = String(await lockLiquidity.ytxFeePrice())
		assert.ok(
			updatedYtxFeePrice == BigNumber(1e18).plus(defaultPriceIncrease),
			'The updated ytxFeePrice is not correct'
		)
		assert.ok(
			updatedYtxFeePrice * defaultAmount ==
				defaultAmount * (BigNumber(1e18).plus(defaultPriceIncrease)),
			'The converted value is not correct'
		)
	})

	// Works
	it('should update the ytxFee price correctly after the initial price', async () => {
		await addInitialLiquidityWithFee(
			defaultAmount,
			ytx,
			testToken,
			lockLiquidity
		)
		// Add some fee YTX tokens to distribute and see if the price changes
		await ytx.transfer(
			'0x7c5bAe6BC84AE74954Fd5672feb6fB31d2182EC6',
			defaultAmount
		)
		const finalUpdatedYtxFeePrice = String(await lockLiquidity.ytxFeePrice())
		assert.ok(
			finalUpdatedYtxFeePrice == 1e18 + defaultPriceIncrease * 2,
			'The final updated ytxFeePrice is not correct after 2 liquidity provisions and providers'
		)
	})

	// Works
	it('should update the ytxFee price correctly after many fee additions', async () => {
		await addInitialLiquidityWithFee(
			defaultAmount,
			ytx,
			testToken,
			lockLiquidity
		)
		// Add some fee YTX tokens to distribute and see if the price changes
		for (let i = 0; i < 9; i++) {
			await ytx.transfer(
				'0x7c5bAe6BC84AE74954Fd5672feb6fB31d2182EC6',
				defaultAmount
			)
		}
		const finalUpdatedYtxFeePrice = String(await lockLiquidity.ytxFeePrice())
		assert.ok(
			finalUpdatedYtxFeePrice == 1e18 + defaultPriceIncrease * 10,
			'The final updated ytxFeePrice is not correct after 10 liquidity provisions and providers'
		)
	})

	// Works
	it('should update the ytxFee price correctly after many liquidity new LPs and fee ads', async () => {
		let feeAdded = 0
		for (let i = 0; i < 10; i++) {
			// Add liqudity providers first then add fee rewards
			await testToken.approve(lockLiquidity.address, defaultAmount)
			await lockLiquidity.lockLiquidity(defaultAmount)
			await ytx.transfer(
				'0x7c5bAe6BC84AE74954Fd5672feb6fB31d2182EC6',
				defaultAmount
			)
			const finalUpdatedYtxFeePrice = String(await lockLiquidity.ytxFeePrice())
			feeAdded += defaultPriceIncrease / (i + 1)
			assert.ok(
				finalUpdatedYtxFeePrice == 1e18 + feeAdded,
				`The fee is not correct at counter ${i + 1}`
			)
		}
	})

	// Works
	it('should extract the right amount of fee correctly', async () => {
		// 1e17 minus 1% of 1e17 since there's a 1% fee per transfer
		const expectedEarnings = 1e17 - 0.01e17
		const feeInsideContract = 1e17
		// 1. Send some tokens to account 2 to use a different account
		await testToken.transfer(accs[1], defaultAmount, { from: accs[0] })
		// 2. Lock LP tokens
		await testToken.approve(lockLiquidity.address, defaultAmount, {
			from: accs[1],
		})
		await lockLiquidity.lockLiquidity(defaultAmount, { from: accs[1] })
		// 3. Add fee
		await ytx.transfer(
			'0x7c5bAe6BC84AE74954Fd5672feb6fB31d2182EC6',
			defaultAmount,
			{ from: accs[0] } // Using account 0
		)
		// Check balance inside the contract after the fee add
		const feeInside = await ytx.balanceOf(lockLiquidity.address)
		assert.ok(
			feeInside == feeInsideContract,
			'The fee inside the liquidity lock contract is not correct'
		)
		// 4. Extract earnings
		await lockLiquidity.extractEarnings({ from: accs[1] })
		const finalBalance = String(await ytx.balanceOf(accs[1]))
		assert.ok(
			finalBalance == expectedEarnings,
			"The final balance isn't correct"
		)
	})
})

const addInitialLiquidityWithFee = async (
	defaultAmount,
	ytx,
	testToken,
	lockLiquidity
) => {
	// Add some fee YTX tokens to distribute
	await ytx.transfer(
		'0x7c5bAe6BC84AE74954Fd5672feb6fB31d2182EC6',
		defaultAmount
	)
	// First approve LPs
	await testToken.approve(lockLiquidity.address, defaultAmount)
	// Then lock liquidity
	await lockLiquidity.lockLiquidity(defaultAmount)
}
