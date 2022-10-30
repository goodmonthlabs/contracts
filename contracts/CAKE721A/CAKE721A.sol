// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CAKE721A is ERC721A, ERC721AQueryable, ERC721ABurnable, PaymentSplitter, AccessControl {

  /// @dev Mutable general-purpose contract variables
  uint256 public MAX_TOKEN_SUPPLY;
  uint256 public MAX_TOTAL_MINTS_BY_ADDRESS;
  uint256 public MAX_TXN_MINT_LIMIT;
  uint256 public PRIVATE_SALE_TIMESTAMP;
  uint256 public PUBLIC_SALE_TIMESTAMP;  
  uint256 public PRICE;

  uint96 public ROYALTY_AMOUNT;

  bytes32 public MERKLEROOT;  
  
  string public PROVENANCE_HASH;
  string public BASE_URI = '';
  string public CONTRACT_URI;

  bytes32 public constant PROVISIONED_ACCESS = keccak256("PROVISIONED_ACCESS");
  

  /// @dev Object with royalty info
  struct RoyaltyInfo {
    address receiver;
    uint96 royaltyFraction;
  }

  /// @dev Fallback royalty information
  RoyaltyInfo private _defaultRoyaltyInfo;

  /// @dev Royalty information
  mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

  constructor(
    string[] memory description, // [name, symbol]
    uint256[] memory limits, // [supply, price, maxTotalMints, maxTxnMints]
    uint256[] memory timestamps, // [privateSaleTimestamp, publicSaleTimestamp]     
    address superAdmin,
    address[] memory primaryDistRecipients,
    uint256[] memory primaryDistShares,
    address[] memory secondaryDistRecipients,
    uint256[] memory secondaryDistShares
    ) ERC721A(description[0], description[1]) PaymentSplitter(primaryDistRecipients, primaryDistShares){
      require(primaryDistRecipients.length > 0, "Invalid payment address"); 
      require(superAdmin != address(0), "Admin zero_addr"); 
      
      require( primaryDistRecipients.length == primaryDistShares.length, "Invalid payment params");
      require( secondaryDistRecipients.length == secondaryDistShares.length, "Invalid royalty params");

      MAX_TOKEN_SUPPLY = limits[0];
      PRICE = limits[1];
      MAX_TOTAL_MINTS_BY_ADDRESS = limits[2];
      MAX_TXN_MINT_LIMIT = limits[3];

      PRIVATE_SALE_TIMESTAMP = timestamps[0];
      PUBLIC_SALE_TIMESTAMP = timestamps[1];      

      _grantRole(DEFAULT_ADMIN_ROLE, superAdmin);

      _setDefaultRoyalty(
        secondaryDistRecipients[0],
        uint96(secondaryDistShares[0])
      );    

  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, IERC721A, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
  
  modifier onlyAdmin(){
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(PROVISIONED_ACCESS, msg.sender), 'Unauthorized');
    _;
  }

  function mint(address to, uint256 quantity, bytes32[] calldata proof) external payable {
    string memory eligibilityCheck = checkMintEligibilityMethod(to, quantity, proof, msg.value); 
    require(bytes(eligibilityCheck).length==0, eligibilityCheck);
    _mint(to, quantity);
  }

  function reserveTokens(address to, uint256 quantity) external onlyAdmin {  
    require(totalSupply() + quantity <= MAX_TOKEN_SUPPLY, 'Exceeds max supply');    
    _mint(to, quantity);
  }
  
  function checkMintEligibilityMethod(address to, uint256 quantity, bytes32[] calldata proof, uint256 value) public view returns(string memory) {
    
    require(to!= address(0), "Invalid receiver");
    require(block.timestamp >= PRIVATE_SALE_TIMESTAMP || block.timestamp >= PUBLIC_SALE_TIMESTAMP, 'Sale not active');
    
    if(block.timestamp < PUBLIC_SALE_TIMESTAMP){
      require(verifyWhitelistMembership(proof, to), "Unauthroized WL mint");
    }

    require(totalSupply() + quantity <= MAX_TOKEN_SUPPLY, 'Exceeds token supply');  
    
    if(MAX_TXN_MINT_LIMIT > 0){
     require(quantity <= MAX_TXN_MINT_LIMIT, 'Exceeds max txn limit'); 
    }

    if(MAX_TOTAL_MINTS_BY_ADDRESS > 0){
     require(balanceOf(to) + quantity <= MAX_TOTAL_MINTS_BY_ADDRESS, 'Exceeds max total'); 
    }

    if(PRICE > 0){
      require(value >= PRICE * quantity , 'Payment below price');
    }
          
    return '';
  }

  function verifyWhitelistMembership(bytes32[] calldata proof, address _address) internal view returns (bool){        
    bytes32 leaf = keccak256(abi.encodePacked(_address));        
    return MerkleProof.verify(proof, MERKLEROOT, leaf);
  }

  function setMerkleroot(bytes32 merkleroot) external onlyAdmin {
    MERKLEROOT = merkleroot;
  }

  function setTotalSupply(uint256 supply) external onlyAdmin {
    require(supply >= totalSupply(), 'Invalid supply');
    MAX_TOKEN_SUPPLY = supply;
  }

  function setMaxTotalMintsByAddrss(uint256 max) external onlyAdmin {
    MAX_TOTAL_MINTS_BY_ADDRESS = max;
  }

  function setMaxMintsPerTxn(uint256 max) external onlyAdmin {
    MAX_TXN_MINT_LIMIT = max;
  }

  function setPrice(uint256 price) external onlyAdmin {
    require(price >= 0, 'Invalid price');
    PRICE = price;
  }

  function setPrivateSaleTimestamp(uint256 timestamp) external onlyAdmin {
    require(timestamp >= 0, 'Invalid timestamp');
    PRIVATE_SALE_TIMESTAMP = timestamp;
  }

  function setPublicSaleTimestamp(uint256 timestamp) external onlyAdmin {
    require(timestamp >= 0, 'Invalid timestamp');
    PUBLIC_SALE_TIMESTAMP = timestamp;
  }

  function setProvenanceHash(string calldata provenanceHash) external onlyAdmin {
    require(bytes(PROVENANCE_HASH).length==0, 'Cannot set hash');
    PROVENANCE_HASH = provenanceHash;
  }

  function _baseURI() internal view override returns (string memory) {
    return BASE_URI;
  }

  function setBaseURI(string calldata baseURI) external onlyAdmin {
    BASE_URI = baseURI;
  }

  function contractURI() public view returns (string memory) {
    return CONTRACT_URI;
  }

  function setContractURI(string memory _contractURI) external onlyAdmin {
    CONTRACT_URI = _contractURI;
  }
  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyAdmin {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() external onlyAdmin {
    _deleteDefaultRoyalty();
  }

  function resetTokenRoyalty(uint256 tokenId) external onlyAdmin {
    _resetTokenRoyalty(tokenId);
  }

  /**
  * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
  * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
  * override.
  */
  function _feeDenominator() internal pure returns (uint96) {
    return 10000;
  }

  /**
  * @dev Sets the royalty information that all ids in this contract will default to.
  *
  * Requirements:
  *
  * - `receiver` cannot be the zero address.
  * - `feeNumerator` cannot be greater than the fee denominator.
  */
  function _setDefaultRoyalty(address receiver, uint96 feeNumerator)
    internal
  {
    require(feeNumerator <= _feeDenominator(), "Invalid price");
    require(receiver != address(0), "Invalid receiver");

    _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
  }

  /**
  * @dev Removes default royalty information.
  */
  function _deleteDefaultRoyalty() internal {
      delete _defaultRoyaltyInfo;
  }

  /**
  * @dev Sets the royalty information for a specific token id, overriding the global default.
  *
  * Requirements:
  *
  * - `tokenId` must be already minted.
  * - `receiver` cannot be the zero address.
  * - `feeNumerator` cannot be greater than the fee denominator.
  */
  function _setTokenRoyalty(
      uint256 tokenId,
      address receiver,
      uint96 feeNumerator
  ) internal {
    require(feeNumerator <= _feeDenominator(), "Invalid price");
    require(receiver != address(0), "Invalid receiver");

    _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
  }

  /**
  * @dev Resets royalty information for the token id back to the global default.
  */
  function _resetTokenRoyalty(uint256 tokenId) internal {
    delete _tokenRoyaltyInfo[tokenId];
  }

  /**
  * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
  */
  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);
    _resetTokenRoyalty(tokenId);
  }
}

