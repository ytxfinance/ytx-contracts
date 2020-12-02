pragma solidity =0.6.2;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';

contract TestToken is Initializable, OwnableUpgradeSafe, ERC20UpgradeSafe {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function initialize() public initializer {
        _name = 'Test Token';
        _symbol = 'TEST';
        _decimals = 18;
        _totalSupply = 100e24; // 1 million
    }

    function extractETHIfStuck() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function extractTokenIfStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }
}