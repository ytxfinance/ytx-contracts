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
        testToken = await TestToken.new()
        ytx = await YTXV3.new()
        lockLiquidity = await LockLiquidity.new(testToken.address, ytx.address)
        console.log('Executing setLockLiquidityContract...')
        await ytx.setLockLiquidityContract(lockLiquidity.address)
    })

    it('should update the ytxFee price correctly', async () => {
        console.log('Deployed LockLiquidity', lockLiquidity.address)
        console.log('ytxFeePrice before', await lockLiquidity.ytxFeePrice())

        const ytxFeePriceBefore = await lockLiquidity.ytxFeePrice()
        // Transfer 10 YTX tokens to another user to see if the fee generated
        // ends up creating an increase in the ytx fee price
        await currentYTX.transfer('0x7c5bAe6BC84AE74954Fd5672feb6fB31d2182EC6', BigNumber(10e18))
        const ytxFeePriceAfter = await lockLiquidity.ytxFeePrice()

        console.log('Price before', ytxFeePriceBefore, 'Price after', ytxFeePriceAfter)
    })
})