// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BloodOfMoloch is ERC721Pausable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;
    uint256 public constant MAX_SUPPLY = 400;
    uint256 public constant MINT_PRICE = 0.01 ether;

    // Token URI before redeemption
    string public mintUri;
    // Token URI after redeemption
    string public redeemUri;
    // Unix timestamp for redemption
    uint256 redeemWindowCloses;
    // Mapping tokens that are redeemed
    mapping(uint256 => bool) public isRedeemed;

    event Redeem(uint256 tokenId, address tokenOwner);

    /**
    * @notice Constructor to initialize the token contract
    * @param _mintUri -> token URI before redemption
    */
    constructor(string memory _mintUri, uint256 _redeemWindowCloses) ERC721("BLOOD OF MOLOCH", "BOM") {
        mintUri = _mintUri;
        redeemWindowCloses = _redeemWindowCloses;
    }

    /**
    * @notice Returns the current total supply
    */
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    /**
    * @notice Update the token URI
    * @param _mintUri -> token URI before redemption
    */
    function updateMintUri(string calldata _mintUri) public onlyOwner {
        mintUri = _mintUri;
    }

    /**
    * @notice Update the token URI
    * @param _redeemUri -> token URI after redemption
    */
    function updateRedeemUri(string calldata _redeemUri) public onlyOwner {
        redeemUri = _redeemUri;
    }

    /**
    * @notice Pause mint & redeem until unpause is called
    */
    function pause() external onlyOwner {
        _pause();
    }

    /**
    * @notice Unpause mint & redeem until pause is called
    */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    * @notice Update redemption end time
    * @param _timestamp -> Unix timestamp in future
    */
    function updateRedeemWindow(uint256 _timestamp) external onlyOwner {
        require(_timestamp > block.timestamp, "Timestamp cannot be in past!");
        redeemWindowCloses = _timestamp;
    }

    /**
     * @dev Modifier for mint
     */
    modifier mintCompliance {
        require(supply.current() < MAX_SUPPLY, "Max supply reached!");
        require(!paused(), "Contract paused!");
        require(msg.value == MINT_PRICE, "Invalid mint value!");
        _;
    }

    /**
     * @dev Modifier for redeem
     */
    modifier redeemCompliance(uint256 _tokenId) {
        require(!paused(), "Contract paused!");
        require(block.timestamp < redeemWindowCloses, "Redemption finished!");
        require(_exists(_tokenId), "Token does not exist!");
        require(ownerOf(_tokenId) == msg.sender, "Not a owner!");
        require(isRedeemed[_tokenId] == false, "Already redeemed!");
        _;
    }

    /**
    * @notice Mints a new token
    */
    function mint() public payable mintCompliance {
        supply.increment();
        _safeMint(msg.sender, supply.current());
        payable(owner()).transfer(msg.value);
    }

    /**
    * @notice Redeem a token that's minted
    * @param _tokenId -> ID of the token to be redeemed
    */
    function redeem(uint256 _tokenId) public redeemCompliance(_tokenId) {
        isRedeemed[_tokenId] = true;
        emit Redeem(_tokenId, msg.sender);
    }

    /**
    * @notice Returns the token URI based on it's redemption state
    * @param _tokenId -> ID of the token
    */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist!");
        if (isRedeemed[_tokenId] == true) {
            return redeemUri;
        }
        return mintUri;
    }
}