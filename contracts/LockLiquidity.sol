// The contract to lock the YTX liquidity and earn fees
pragma solidity =0.6.2;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';

/// @notice This contract allows you to lock liquidity LP tokens and receive earnings
/// It also allows you to extract those earnings
/// It's the treasury where the feeYTX, YTX and LP YTX tokens are stored
contract LockLiquidity is Initializable, OwnableUpgradeSafe {
    using SafeMath for uint256;

    // How many LP tokens each user has
    mapping (address => uint256) public amountLocked;
    // The price when you extracted your earnings so we can whether you got new earnings or not
    mapping (address => uint256) public lastPriceEarningsExtracted;
    // The uniswap LP token contract
    address public uniswapLPContract;
    // The YTX token
    address public ytx;
    // How many LP tokens are locked
    uint256 public totalLiquidityLocked;
    // The total YTXFee generated
    uint256 public totalYtxFeeMined;
    uint256 public ytxFeePrice;
    uint256 public accomulatedRewards;
    uint256 public pricePadding;
    
    function initialize(address _uniswapLPContract, address _ytx) public initializer {
        __Ownable_init();
        uniswapLPContract = _uniswapLPContract;
        ytx = _ytx;
        pricePadding = 1e18;
    }

    function setYtx(address _ytx) public onlyOwner {
        ytx = _ytx;
    }

    function setUniswapLPContract(address _uniswapLPContract) public onlyOwner {
        uniswapLPContract = _uniswapLPContract;
    }

    /// @notice When fee is added, the price is increased
    /// Price is = (feeIn / totalYTXFeeDistributed) + currentPrice
    /// padded with 18 zeroes that get removed after the calculations
    /// if there are no locked LPs, the price is 0
    function addFeeAndUpdatePrice(uint256 _amount) public {
        require(msg.sender == ytx, 'LockLiquidity: Only the YTX contract can execute this function');
        accomulatedRewards = accomulatedRewards.add(_amount);
        if (totalLiquidityLocked == 0) {
            ytxFeePrice = 0;
        } else {
            ytxFeePrice = (_amount.mul(pricePadding).div(totalLiquidityLocked)).add(ytxFeePrice);
        }
    }

    function lockLiquidity(uint256 _amount) public {
        require(_amount > 0, 'LockLiquidity: Amount must be larger than zero');
        // Transfer UNI-LP-V2 tokens inside here forever while earning fees from every transfer, LP tokens can't be extracted
        uint256 approval = IERC20(uniswapLPContract).allowance(msg.sender, address(this));
        require(approval >= _amount, 'LockLiquidity: You must approve the desired amount of liquidity tokens to this contract first');
        IERC20(uniswapLPContract).transferFrom(msg.sender, address(this), _amount);
        totalLiquidityLocked = totalLiquidityLocked.add(_amount);
        // Set the initial price 
        if (ytxFeePrice == 0) {
            ytxFeePrice = (accomulatedRewards.mul(pricePadding).div(_amount)).add(1e18);
            lastPriceEarningsExtracted[msg.sender] = 1e18;
        } else {
            lastPriceEarningsExtracted[msg.sender] = ytxFeePrice;
        }
        // The price doesn't change when locking liquidity. It changes when fees are generated from transfers
        amountLocked[msg.sender] = amountLocked[msg.sender].add(_amount);
    }

    // We check for new earnings by seeing if the price the user last extracted his earnings
    // is the same or not to determine whether he can extract new earnings or not
    function extractEarnings() public {
        require(lastPriceEarningsExtracted[msg.sender] != ytxFeePrice, 'LockLiquidity: You have already extracted your earnings');
        // The amountLocked price minus the last price extracted
        uint256 myPrice = ytxFeePrice.sub(lastPriceEarningsExtracted[msg.sender]);
        uint256 earnings = amountLocked[msg.sender].mul(myPrice).div(pricePadding);
        lastPriceEarningsExtracted[msg.sender] = ytxFeePrice;
        accomulatedRewards = accomulatedRewards.sub(earnings);
        IERC20(ytx).transfer(msg.sender, earnings);
    }

    function getAmountLocked(address _user) public view returns (uint256) {
        return amountLocked[_user];
    }

    function extractTokensIfStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    function extractETHIfStruck() public onlyOwner {
        payable(address(owner())).transfer(address(this).balance);
    }
}