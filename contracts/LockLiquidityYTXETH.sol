// The contract to lock the YTX liquidity and earn fees
pragma solidity =0.6.0;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';

interface ILockLiquidityYTXETH {
    function totalLiquidityLocked(address _user) external view;
    function getUserLockedLiquidity(address _user) external view;
}

/// @notice This contract allows you to lock liquidity LP tokens and receive earnings
/// It also allows you to extract those earnings. It's the treasury where the fee YTX is stored
contract LockLiquidityYTXETH is Initializable, OwnableUpgradeSafe {
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
    
    function initialize(address _uniswapLPContract, address _ytx) public initializer {
        uniswapLPContract = _uniswapLPContract;
        ytx = _ytx;
    }

    function setYtx(address _ytx) public onlyOwner {
        ytx = _ytx;
    }

    function setUniswapLPContract(address _uniswapLPContract) public onlyOwner {
        uniswapLPContract = _uniswapLPContract;
    }

    function lockLiquidity(uint256 _amount) public {
        // Transfer UNI-LP-V2 tokens inside here forever while earning fees from every transfer, LP tokens can't be extracted
        uint256 approval = IERC20(uniswapLPContract).allowance(msg.sender, address(this));
        require(approval >= _amount, 'You must approve the desired amount of liquidity tokens to this contract first');
        IERC20(uniswapLPContract).transferFrom(msg.sender, address(this), _amount);
        initialLockedLiquidity[msg.sender] = initialLockedLiquidity[msg.sender].add(_amount);
        totalLiquidityLocked = totalLiquidityLocked.add(_amount);
        uint256 myYtxFee = _amount.div(ytxFeePrice);
        totalYtxFeeMined = totalYtxFeeMined.add(myYtxFee);
        // The price doesn't change when locking liquidity. It changes when fees are generated from transfers
        // TODO: update price on fee generation (when transfering from the YTX contract)
        ytxFee[msg.sender] = ytxFee[msg.sender].add(myYtxFee);
    }

    // We check for new earnings by seeing if the price the user last extracted his earnings
    // is the same or not to determine whether he can extract new earnings or not
    function extractEarnings() public {
        require(lastPriceEarningsExtracted[msg.sender] != ytxFeePrice, 'You already extracted your earnings');
        // The ytxFee price minus the last price extracted
        uint256 myPrice = ytxFeePrice - lastPriceEarningsExtracted[msg.sender];
        uint256 earnings = ytxFee[msg.sender].mul(myPrice);
        lastPriceEarningsExtracted[msg.sender] = ytxFeePrice;
        IERC20(ytx).transfer(msg.sender, earnings);
    }

    function extractTokensIfStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_tokens).transfer(owner(), _amount);
    }

    function extractETHIfStruck() public onlyOwner {
        payable(address(owner())).transfer(address(this).balance);
    }

    // Used to check how much liquidity the specific user has locked
    function getUserLockedLiquidity(address _user) public view {
        return initialLockedLiquidity[_user];
    }
    
    function getYtxFee(address _user) public view {
        return ytxFee[_user];
    }
}