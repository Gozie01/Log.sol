// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";

contract HEALTHLogistics is ERC721, ERC721Burnable, AccessControl, EIP712, ERC721Votes {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");

    struct ProductDetails {
        string productName;
        string batchNumber;
        string manufacturingDate;
        string expiringDate;
        string certificationID;
    }

    // Mapping to store product details for each token ID
    mapping(uint256 => ProductDetails) private productDetails;

    // Mapping to store whether a token is frozen (frozen tokens cannot be transferred)
    mapping(uint256 => bool) private frozenTokens;

    constructor(address defaultAdmin, address minter)
        ERC721("HEALTH logistics", "HlG")
        EIP712("HEALTH logistics", "1")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(FREEZER_ROLE, defaultAdmin); // Admin has rights to freeze tokens
    }

    // Override the base URI
    function _baseURI() internal pure override returns (string memory) {
        return "https://github.com/Gozie01/HealthcareCert.git/";
    }

    // Mint function with product details input
    function safeMint(
        address to,
        uint256 tokenId,
        string memory productName,
        string memory batchNumber,
        string memory manufacturingDate,
        string memory expiringDate,
        string memory certificationID
    ) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
        productDetails[tokenId] = ProductDetails(productName, batchNumber, manufacturingDate, expiringDate, certificationID);
    }

    // Function to verify product details and freeze token if they don't match
    function verifyAndRetrieveToken(
        uint256 tokenId,
        string memory productName,
        string memory batchNumber,
        string memory manufacturingDate,
        string memory expiringDate,
        string memory certificationID
    ) public view returns (string memory, bool) {
        require(_tokenExists(tokenId), "HEALTHLogistics: Token does not exist");

        ProductDetails memory details = productDetails[tokenId];

        // Verify that all provided product details match the stored details
        bool isMatching = (
            keccak256(abi.encodePacked(details.productName)) == keccak256(abi.encodePacked(productName)) &&
            keccak256(abi.encodePacked(details.batchNumber)) == keccak256(abi.encodePacked(batchNumber)) &&
            keccak256(abi.encodePacked(details.manufacturingDate)) == keccak256(abi.encodePacked(manufacturingDate)) &&
            keccak256(abi.encodePacked(details.expiringDate)) == keccak256(abi.encodePacked(expiringDate)) &&
            keccak256(abi.encodePacked(details.certificationID)) == keccak256(abi.encodePacked(certificationID))
        );

        if (isMatching) {
            // If details match, return the base URI and true
            return (_baseURI(), true);
        } else {
            // If details don't match, return an empty string and false
            return ("", false);
        }
    }

    // Custom internal function to check token existence using ownerOf
    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        try this.ownerOf(tokenId) {
            return true;
        } catch {
            return false;
        }
    }

    // Function to freeze the token if details don't match
    function freezeToken(uint256 tokenId) public onlyRole(FREEZER_ROLE) {
        require(_tokenExists(tokenId), "HEALTHLogistics: Token does not exist");
        frozenTokens[tokenId] = true;
    }

    // Override _beforeTokenTransfer to prevent frozen tokens from being transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {
        require(!frozenTokens[firstTokenId], "HEALTHLogistics: Token is frozen and cannot be transferred");
        _beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    // Function to check if a token is frozen
    function isFrozen(uint256 tokenId) public view returns (bool) {
        require(_tokenExists(tokenId), "HEALTHLogistics: Token does not exist");
        return frozenTokens[tokenId];
    }

    // Clock functions as required
    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    // Solidity required overrides
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Votes)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Votes)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool){
        return super.supportsInterface(interfaceId);
        }}

