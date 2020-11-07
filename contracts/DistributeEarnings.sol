pragma solidity =0.6.0;

import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';

contract Ownable {
    address payable public owner;
    mapping(address => bool) public approved;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyApproved {
        require(msg.sender == owner || approved[msg.sender]);
        _;
    }

    function addApproved(address _to) public onlyOwner {
        approved[_to] = true;
    }

    function removeApproved(address _to) public onlyOwner {
        approved[_to] = false;
    }
}

contract DistributeEarnings is Ownable {
    function init() public {
        require(owner == address(0));
        owner = msg.sender;
        addApproved(msg.sender);
    }

    function transferTokens(address _token, address _to, uint256 _amount) public onlyApproved {
        IERC20(_token).transfer(_to, _amount);
    }

    function extractETHIfStuck() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function extractTokensIfStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(owner, _amount);
    }
}