// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract BloodOfMoloch is ERC1155, Ownable, Pausable {
    uint256 public constant MAX_BREWS = 400;
    uint8 public constant BREW_TOKEN_ID = 1;
    uint8 public constant REDEEM_TOKEN_ID = 2;
    uint256 public constant BREW_PRICE = 0.01 ether;

    uint256 public redemptionStartDate = 1662402600; 

    mapping(uint => string) private tokenUri;
    uint256 public brewsCount;
    uint256 public redeemsCount;

    constructor(string memory _brewUri, string memory _redeemUri) ERC1155(_brewUri) {
        tokenUri[BREW_TOKEN_ID] = _brewUri;
        tokenUri[REDEEM_TOKEN_ID] = bytes(_redeemUri).length > 0 ? _redeemUri : "";
    }

    modifier brewCompliance() {
        require(brewsCount + redeemsCount < MAX_BREWS, "Max brews made.");
        require(msg.value == BREW_PRICE, "Invalid value sent.");
        _;
    }

    modifier redeemCompliance() {
        require(!paused(), "Redemption is paused.");
        require(block.timestamp >= redemptionStartDate, "Redemption not begun.");
        require(balanceOf(msg.sender, 1) >= 1, "Not enough balance.");
        _;
    }

    function brewOne() payable public brewCompliance {
        _mint(msg.sender, BREW_TOKEN_ID, 1, '');
        brewsCount += 1;
    }

    function redeemOne() public redeemCompliance {
        _burn(msg.sender, BREW_TOKEN_ID, 1);
        _mint(msg.sender, REDEEM_TOKEN_ID, 1, '');
        brewsCount -= 1;
        redeemsCount += 1;
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return tokenUri[_id];
    }

    function updateRedemptionUri(string memory _uri) external onlyOwner {
        require(bytes(_uri).length > 0, "Cannot be empty uri.");
        tokenUri[REDEEM_TOKEN_ID] = _uri;
    }

    function updateRedemptionStartDate(uint256 _timestamp) external onlyOwner {
        require(_timestamp > block.timestamp, "Time cannot be in past.");
        redemptionStartDate = _timestamp;
    }

    function pauseRedemption() external onlyOwner whenNotPaused {
        _pause();
    }

    function resumeRedemption() external onlyOwner whenPaused {
        _unpause();
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Not enough balance.");
        payable(owner()).transfer(address(this).balance);
    }

    function checkContractBalance() external view returns(uint256) {
        return address(this).balance;
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}