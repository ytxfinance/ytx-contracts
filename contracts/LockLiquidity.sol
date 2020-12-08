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

    mapping (address => uint256) public initialLockedLiquidity;
    mapping (address => uint256) public ytxFee;
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
    
    function initialize(address _uniswapLPContract, address _ytx) public initializer {
        __Ownable_init();
        uniswapLPContract = _uniswapLPContract;
        ytx = _ytx;
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
        if (totalYtxFeeMined == 0) {
            ytxFeePrice = 0;
        } else {
            ytxFeePrice = (_amount.add(1e18).div(totalYtxFeeMined)).add(ytxFeePrice).sub(1e18);
        }
    }

    // I.E. 10 LP tokens first liquidity provider
    // ytxFee[msg.sender] = 10 ytxFeePrice = 0
    // 

    function lockLiquidity(uint256 _amount) public {
        // Transfer UNI-LP-V2 tokens inside here forever while earning fees from every transfer, LP tokens can't be extracted
        uint256 approval = IERC20(uniswapLPContract).allowance(msg.sender, address(this));
        require(approval >= _amount, 'LockLiquidity: You must approve the desired amount of liquidity tokens to this contract first');
        IERC20(uniswapLPContract).transferFrom(msg.sender, address(this), _amount);
        initialLockedLiquidity[msg.sender] = initialLockedLiquidity[msg.sender].add(_amount);
        totalLiquidityLocked = totalLiquidityLocked.add(_amount);
        uint256 myYtxFee = _amount;
        if (ytxFeePrice != 0) {
            myYtxFee = _amount.div(ytxFeePrice);
        }        
        totalYtxFeeMined = totalYtxFeeMined.add(myYtxFee);
        // The price doesn't change when locking liquidity. It changes when fees are generated from transfers
        ytxFee[msg.sender] = ytxFee[msg.sender].add(myYtxFee);
    }

    // We check for new earnings by seeing if the price the user last extracted his earnings
    // is the same or not to determine whether he can extract new earnings or not
    function extractEarnings() public {
        require(lastPriceEarningsExtracted[msg.sender] != ytxFeePrice, 'LockLiquidity: You already extracted your earnings');
        // The ytxFee price minus the last price extracted
        uint256 myPrice = ytxFeePrice - lastPriceEarningsExtracted[msg.sender];
        uint256 earnings = ytxFee[msg.sender].mul(myPrice);
        lastPriceEarningsExtracted[msg.sender] = ytxFeePrice;
        IERC20(ytx).transfer(msg.sender, earnings);
    }

    function extractTokensIfStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    function extractETHIfStruck() public onlyOwner {
        payable(address(owner())).transfer(address(this).balance);
    }

    // Used to check how much liquidity the specific user has locked
    function getUserLockedLiquidity(address _user) public view returns (uint256) {
        return initialLockedLiquidity[_user];
    }
    
    function getYtxFee(address _user) public view returns (uint256) {
        return ytxFee[_user];
    }
}