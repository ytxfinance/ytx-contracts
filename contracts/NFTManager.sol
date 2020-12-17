pragma solidity =0.6.2;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';

interface IYFS {
    function mint(address _to, uint256 _amount) external;
    function burn(address _to, uint256 _amount) external;
}

contract NFTManager is Initializable, OwnableUpgradeSafe, ERC721UpgradeSafe {
    using SafeMath for uint256;
    
    // Time staked in blocks
    mapping (address => uint256) public timeStaked;
    mapping (address => uint256) public amountStaked;
    // TokenURI => blueprint
    // the array is a Blueprint with 4 elements. We use this method instead of a struct since structs are not upgradeable
    // [0] uint256 mintMax;
    // [1] uint256 currentMint; // How many tokens of this type have been minted already
    // [2] uint256 ytxCost;
    // [3] uint256 yfsCost;
    mapping (string => uint256[4]) public blueprints;
    mapping (string => bool) public blueprintExists;
    // Token ID -> tokenURI without baseURI
    mapping (uint256 => string) public myTokenURI;
    string[] public tokenURIs;
    uint256[] public mintedTokenIds;
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

    // Allows the owner to create a blueprint which is how many card can be minted for a particular tokenURI
    // NOTE: Remember to deploy the json file to the right URI with the baseURI
    function createBlueprint(string memory _tokenURI, uint256 _maxMint, uint256 _ytxCost, uint256 _yfsCost) public onlyOwner {
        uint256[4] memory blueprint = [_maxMint, 0, _ytxCost, _yfsCost];
        blueprints[_tokenURI] = blueprint;
        blueprintExists[_tokenURI] = true;
        tokenURIs.push(_tokenURI);
    }

    // Stacking YTX RESETS the staking time
    function stakeYTX(uint256 _amount) public {
        // Check allowance
        uint256 allowance = IERC20(ytx).allowance(msg.sender, address(this));
        require(allowance >= _amount, 'NFTManager: You have to approve the required token amount to stake');
        IERC20(ytx).transferFrom(msg.sender, address(this), _amount);
        // Apply 1% fee from the transfer
        _amount = _amount.mul(99).div(100);
        timeStaked[msg.sender] = block.number;
        amountStaked[msg.sender] = amountStaked[msg.sender].add(_amount);
    }

    function receiveYFS() public {
        require(amountStaked[msg.sender] > 0, 'You must have YTX staked to receive YFS');
        uint256 blocksPassed = block.number.sub(timeStaked[msg.sender]);
        uint256 yfsGenerated = amountStaked[msg.sender].mul(blocksPassed).div(oneDayInBlocks);
        timeStaked[msg.sender] = block.number;
        IYFS(yfs).mint(msg.sender, yfsGenerated);
    }

    // Unstake YTX tokens and receive YFS tokens tradable for NFTs
    function unstakeYTXAndReceiveYFS(uint256 _amount) public {
        require(_amount <= amountStaked[msg.sender], "NFTManager: You can't unstake more than your current stake");
        receiveYFS();
        amountStaked[msg.sender] = amountStaked[msg.sender].sub(_amount);
        IERC20(ytx).transfer(msg.sender, _amount);
    }

    // Mint a card for the sender
    // NOTE: remember that the tokenURI most not have the baseURI. For instance:
    // - BaseURI is https://examplenft.com/
    // - TokenURI must be "token-1" or whatever without the BaseURI
    // To create the resulting https://exampleNFT.com/token-1
    function safeMint(string memory _tokenURI) public {
        // Check that this tokenURI exists
        require(blueprintExists[_tokenURI], "NFTManager: That token URI doesn't exist");
        // Require than the amount of tokens to mint is not exceeded
        require(blueprints[_tokenURI][0] > blueprints[_tokenURI][1], 'NFTManager: The total amount of tokens for this URI have been minted already');
        uint256 allowanceYTX = IERC20(ytx).allowance(msg.sender, address(this));
        uint256 allowanceYFS = IERC20(yfs).allowance(msg.sender, address(this));
        require(allowanceYTX >= blueprints[_tokenURI][2], 'NFTManager: You have to approve the required token amount of YTX to stake');
        require(allowanceYFS >= blueprints[_tokenURI][3], 'NFTManager: You have to approve the required token amount of YFS to stake');
        // Payment
        IERC20(ytx).transferFrom(msg.sender, address(this), blueprints[_tokenURI][2]);
        IERC20(yfs).transferFrom(msg.sender, address(this), blueprints[_tokenURI][3]);

        blueprints[_tokenURI][1] = blueprints[_tokenURI][1].add(1);
        lastId = lastId.add(1);
        mintedTokenIds.push(lastId);
        myTokenURI[lastId] = _tokenURI;
        // The token URI determines which NFT this is
        _safeMint(msg.sender, lastId, "");
        _setTokenURI(lastId, _tokenURI);
    }

    /// @notice To break a card and receive the YTX inside, which is inside this contract
    /// @param _id The token id of the card to burn and extract the YTX
    function breakCard(uint256 _id) public {
        require(_exists(_id), "The token doesn't exist with that tokenId");
        address owner = ownerOf(_id);
        require(owner != address(0), "The token doesn't have an owner");
        require(owner == msg.sender, 'You must be the owner of this card to break it');
        // Don't use the function tokenURI() because it combines the baseURI too
        string memory userURI = myTokenURI[_id];
        uint256[4] storage blueprint = blueprints[userURI];
        _burn(_id);
        // Consider the 1% cost when minting the card since the contract should not have more than that inside
        IERC20(ytx).transfer(msg.sender, blueprint[2].mul(99).div(100));
        // Make sure to increase the supply again
        blueprint[1] = blueprint[1].sub(1);
    }

    function extractTokensIfStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    function extractETHIfStruck() public onlyOwner {
        payable(address(owner())).transfer(address(this).balance);
    }

    function getBlueprint(string memory _tokenURI) public view returns(uint256[4] memory) {
        return blueprints[_tokenURI];
    }
}