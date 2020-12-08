pragma solidity =0.6.2;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Metadata.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';

interface IYFS {
    function mint(address _to, uint256 _amount) external;
    function burn(address _to, uint256 _amount) external;
}

// TODO Be able to break NFTs into their YTX tokens
contract NFTManager is Initializable, OwnableUpgradeSafe, ERC721UpgradeSafe {
    using SafeMath for uint256;

    struct Blueprint {
        string tokenURI;
        uint256 mintMax;
        uint256 currentMint; // How many tokens of this type have been minted already
        uint256 ytxCost;
        uint256 yfsCost;
    }
    
    // Time staked in blocks
    mapping (address => uint256) public timeStaked;
    mapping (address => uint256) public amountStaked;
    mapping (string => Blueprint) public blueprints;
    uint256 public lastId;
    address public ytx;
    address public yfs;
    uint256 public oneDayInBlocks;

    function initialize(address _ytx, address _yfs, string memory baseUri_) public initializer {
        __Ownable_init();
        __ERC721_init('NFTManager', 'YTXNFT');
        _setBaseURI(baseUri_);
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

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    // Stacking YTX RESETS the staking time
    function stakeYTX(uint256 _amount) public {
        // Check allowance
        uint256 allowance = IERC20(ytx).allowance(msg.sender, address(this));
        require(allowance >= _amount, 'You have to approve the required token amount to stake');
        IERC20(ytx).transferFrom(msg.sender, address(this), _amount);
        timeStaked[msg.sender] = block.number;
        amountStaked[msg.sender] = amountStaked[msg.sender].add(_amount);
    }

    // Unstake YTX tokens and receive YFS tokens tradable for NFTs
    function unstakeYTXAndReceiveYFS(uint256 _amount) public {
        require(_amount < amountStaked[msg.sender], "You can't unstake more than your current stake");
        uint256 yfsGenerated = amountStaked[msg.sender].mul(timeStaked[msg.sender]).div(oneDayInBlocks);
        timeStaked[msg.sender] = block.number;
        amountStaked[msg.sender] = amountStaked[msg.sender].sub(_amount);
        IYFS(yfs).mint(msg.sender, yfsGenerated);
        IERC20(ytx).transfer(msg.sender, _amount);
    }

    // Allows the owner to create a blueprint which is how many card can be minted for a particular tokenURI
    // NOTE: Remember to deploy the json file to the right URI with the baseURI
    function createBlueprint(string memory _tokenURI, uint256 _maxMint, uint256 _ytxCost, uint256 _yfsCost) public onlyOwner {
        blueprints[_tokenURI] = Blueprint(_tokenURI, _maxMint, 0, _ytxCost, _yfsCost);
    }

    // Mint a card for the sender
    // NOTE: remember that the tokenURI most not have the baseURI. For instance:
    // - BaseURI is https://examplenft.com/
    // - TokenURI must be "token-1" or whatever without the BaseURI
    // To create the resulting https://exampleNFT
    function safeMint(string memory _tokenURI) public {
        string memory emptyString = "";
        // Check that this tokenURI exists
        require(keccak256(bytes(blueprints[_tokenURI].tokenURI)) == keccak256(bytes(emptyString)) , "That token URI doesn't exist");
        // Require than the amount of tokens to mint is not exceeded
        require(blueprints[_tokenURI].mintMax > blueprints[_tokenURI].currentMint, 'The total amount of tokens for this URI have been minted already');
        uint256 allowanceYTX = IERC20(ytx).allowance(msg.sender, address(this));
        uint256 allowanceYFS = IERC20(yfs).allowance(msg.sender, address(this));
        require(allowanceYTX >= blueprints[_tokenURI].ytxCost, 'You have to approve the required token amount of YTX to stake');
        require(allowanceYFS >= blueprints[_tokenURI].yfsCost, 'You have to approve the required token amount of YFS to stake');
        // Payment
        IERC20(ytx).transferFrom(msg.sender, address(this), blueprints[_tokenURI].ytxCost);
        IERC20(yfs).transferFrom(msg.sender, address(this), blueprints[_tokenURI].yfsCost);

        blueprints[_tokenURI].currentMint++;
        lastId++;
        _safeMint(msg.sender, lastId, "");
        // The token URI determines which NFT this is
        _setTokenURI(lastId, _tokenURI);
    }

    function extractTokensIfStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    function extractETHIfStruck() public onlyOwner {
        payable(address(owner())).transfer(address(this).balance);
    }
}