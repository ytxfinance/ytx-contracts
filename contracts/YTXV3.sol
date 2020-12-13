pragma solidity =0.6.2;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import './ERC20UpgradeSafe.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';

interface ILockLiquidity {
    function addFeeAndUpdatePrice(uint256 _amount) external;
}

contract YTXV3 is Initializable, OwnableUpgradeSafe, ERC20UpgradeSafe {
    using SafeMath for uint256;

    mapping (address => bool) public isFrozen;
    uint256 public transferFee;
    address public lockLiquidityContract;
    address public gameTreasury;

    event Fee(address sender, uint256 amount);
    
    function initialize(address _gameTreasury) public initializer {
        __ERC20_init('YTX', 'YTX');
        __Ownable_init();
        // Decimals are set to 18 by default
        // Total supply is 60000 * 1e18; // 60k tokens
        _mint(msg.sender, 60000 * 1e18);
        transferFee = 1e16; // 1% out of 100% which is 1e16 out of 1e18
        gameTreasury = _gameTreasury;
    }

    function setGameTreasury(address _gameTreasury) public onlyOwner {
        gameTreasury = _gameTreasury;
    }

    function setLockLiquidityContract(address _lockLiquidityContract) public onlyOwner {
        lockLiquidityContract = _lockLiquidityContract;
    }

    /// @notice A 1% fee is applied to every transaction where 90% goes to the lock liquidity contract
    /// to distribute to locked liquidity providers while the remaining 10% goes to the game treasury
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(!isFrozen[msg.sender], 'YTX: Your transfers are frozen');
        require(sender != address(0), "YTX: ERC20: transfer from the zero address");
        require(recipient != address(0), "YTX: ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        // YTX
        (uint256 fee, uint256 remaining) = calculateFee(amount);
        uint256 gameTreasuryFee = fee.div(10);
        fee = fee.sub(gameTreasuryFee);

        _balances[sender] = _balances[sender].sub(amount, "YTX: ERC20: transfer amount exceeds balance");
        // Remaining transfer
        _balances[recipient] = _balances[recipient].add(remaining);
        // Fee transfer
        _balances[gameTreasury] = _balances[gameTreasury].add(gameTreasuryFee);
        _balances[lockLiquidityContract] = _balances[lockLiquidityContract].add(fee);
        ILockLiquidity(lockLiquidityContract).addFeeAndUpdatePrice(fee);

        emit Transfer(sender, recipient, remaining);
        emit Fee(sender, fee);
    }

    function burn(address _account, uint256 _amount) public onlyOwner returns (bool) {
        _burn(_account, _amount);
        return true;
    }

    function extractETHIfStuck() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function extractTokenIfStuck(address _token, uint256 _amount) public onlyOwner {
        ERC20UpgradeSafe(_token).transfer(owner(), _amount);
    }

    function freezeTokens(address _of) public onlyOwner {
        isFrozen[_of] = true;
    }
    
    function unFreezeTokens(address _of) public onlyOwner {
        isFrozen[_of] = false;
    }

    function changeFee(uint256 _fee) public onlyOwner {
        transferFee = _fee;
    }

    function calculateFee(uint256 _amount) internal view returns(uint256 fee, uint256 remaining) {
        fee = _amount.mul(transferFee).div(1e18);
        remaining = _amount.sub(fee);
    }
}