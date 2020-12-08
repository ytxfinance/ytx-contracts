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

    event Fee(address sender, uint256 amount);
    
    function initialize() public initializer {
        __Ownable_init();
        __ERC20_init('YTX', 'YTX');
        // Decimals are set to 18 by default
        // Total supply is 60000 * 1e18; // 60k tokens
        _mint(msg.sender, 60000 * 1e18);
        transferFee = 1e16; // 1% out of 100% which is 1e16 out of 1e18
    }

    function setLockLiquidityContract(address _lockLiquidityContract) public onlyOwner {
        lockLiquidityContract = _lockLiquidityContract;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(!isFrozen[msg.sender], 'Your transfers are frozen');
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        // YTX
        (uint256 fee, uint256 remaining) = calculateFee(amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        // Remaining transfer
        _balances[recipient] = _balances[recipient].add(remaining);
        // Fee transfer
        // TODO Check the price is updated on fee added
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