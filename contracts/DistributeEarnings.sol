pragma solidity =0.6.2;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';

// The YTX contract to send earnings after playing games
contract DistributeEarnings is OwnableUpgradeSafe {
    mapping(address => bool) public approved;

    modifier onlyManager {
        require(msg.sender == owner() || approved[msg.sender], 'DistributeEarnings: You must be a manager or the owner to execute that function');
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function modifyManager(address _to, bool _add) public onlyOwner {
        approved[_to] = _add;
    }

    function transferTokens(address _token, address _to, uint256 _amount) public onlyManager {
        IERC20(_token).transfer(_to, _amount);
    }

    function extractETHIfStuck() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function extractTokensIfStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }
}