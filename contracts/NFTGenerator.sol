pragma solidity =0.6.0;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Metadata.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';

contract NFTGenerator is Initializable, OwnableUpgradeSafe, ERC721, IERC721Metadata {
    using SafeMath for uint256;
    
    // Time staked in blocks
    mapping (address => uint256) public timeStaked;
    mapping (address => uint256) public amountStaked;
    uint256 public lastId;
    address public ytx;
    address public yfs;
    uint256 public oneDayInBlocks;

    function initialize(address _ytx, address _yfs) public initializer {
        ytx = _ytx;
        yfs = _yfs;
        oneDayInBlocks = 6500;
    }

    function setYTX(address _ytx) public onlyOwner {
        ytx = _ytx;
    }

    function setYFS(address _yfs) public onlyOwner {
        yfs = _yfs;
    }

    // Stacking YTX RESETS the staking time
    function stakeYTX(uint256 _amount) public {
        // Check allowance
        uint256 allowance = IERC20(ytx).allowance(msg.sender, address(this));
        require(allowance >= _amount, 'You have to approve the required token amount to stake');
        // Stake tokens here
        IERC20(ytx).transfer(address(this), _amount);
        amountStaked[msg.sender] = amountStaked[msg.sender].add(_amount);
        timeStaked[msg.sender] = block.number;
    }

    // Unstake YTX tokens and receive YFS tokens tradable for NFTs
    function unstakeYTXAndReceiveYFS(uint256 _amount) public {
        require(_amount < amountStaked[msg.sender], "You can't unstake more than your current stake");
        uint256 yfsGenerated = amountStaked[msg.sender].mul(timeStaked[msg.sender]).div(oneDayInBlocks);
    }

    // Allows the owner to create a blueprint which is a card with the defined properties
    function createBlueprint() public onlyOwner {

    }

    // Mint a card for the sender
    function safeMint() public {
        lastId++;
        // require()
        _safeMint(msg.sender, lastId, "");
    }

    function extractTokensIfStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_tokens).transfer(owner(), _amount);
    }

    function extractETHIfStruck() public onlyOwner {
        payable(address(owner())).transfer(address(this).balance);
    }
}