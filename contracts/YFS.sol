pragma solidity =0.6.2;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';

contract YFS is Initializable, OwnableUpgradeSafe, ERC20UpgradeSafe {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    mapping (address => bool) public isFrozen;
    address public nftManager;

    modifier onlyManager {
        require(msg.sender == nftManager || msg.sender == owner(), 'Only executable by the NFTManager contract or owner');
        _;
    }
    
    function initialize(address _nftManager) public initializer {
        _name = 'YFS';
        _symbol = 'YFS';
        _decimals = 18;
        nftManager = _nftManager;
    }

    function setManager(address _nftManager) public onlyOwner {
        nftManager = _nftManager;
    }

    function mint(address _to, uint256 _amount) public onlyManager {
        _mint(_to, _amount);
    }

    function burn(address _account, uint256 _amount) public onlyManager {
        _burn(_account, _amount);
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(!isFrozen[msg.sender], 'Your transfers are frozen');
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function extractETHIfStuck() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function extractTokenIfStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    function freezeTokens(address _of) public onlyOwner {
        isFrozen[_of] = true;
    }
    
    function unFreezeTokens(address _of) public onlyOwner {
        isFrozen[_of] = false;
    }
}