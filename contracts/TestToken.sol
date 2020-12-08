pragma solidity =0.6.2;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';

contract TestToken is Initializable, OwnableUpgradeSafe, ERC20UpgradeSafe {
    function initialize() public initializer {
        __Ownable_init();
        __ERC20_init('Test Token', 'TEST');
        // Decimals are set to 18 by default
        _mint(msg.sender, 100e24);
    }

    function extractETHIfStuck() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function extractTokenIfStuck(address _token, uint256 _amount) public onlyOwner {
        ERC20(_token).transfer(owner(), _amount);
    }
}