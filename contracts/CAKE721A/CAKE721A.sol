// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract CAKE721A is ERC721A, ERC721AQueryable, ERC721ABurnable, PaymentSplitter, AccessControl, ERC2981 {

  /// @dev Mutable general-purpose contract variables
  uint256 public MAX_TOKEN_SUPPLY;
  uint256 public MAX_TOTAL_MINTS_BY_ADDRESS;
  uint256 public MAX_TXN_MINT_LIMIT;
  uint256 public PRIVATE_SALE_TIMESTAMP;
  uint256 public PUBLIC_SALE_TIMESTAMP;  
  uint256 public PRICE;

  bytes32 public MERKLEROOT;  
  
  string public PROVENANCE_HASH;
  string public BASE_URI = '';
  string public CONTRACT_URI;

  bytes32 public constant PROVISIONED_ACCESS = keccak256("PROVISIONED_ACCESS");

  constructor(
    string[] memory description, // [name, symbol]
    uint256[] memory limits, // [supply, price, maxTotalMints, maxTxnMints]
    uint256[] memory timestamps, // [privateSaleTimestamp, publicSaleTimestamp]     
    address superAdmin,
    address[] memory primaryDistRecipients,
    uint256[] memory primaryDistShares,
    address secondaryDistRecipient,
    uint96 secondaryDistShare
    ) ERC721A(description[0], description[1]) PaymentSplitter(primaryDistRecipients, primaryDistShares){
      require(primaryDistRecipients.length > 0, "Invalid payment address"); 
      require(superAdmin != address(0), "Admin zero_addr"); 
      
      require( primaryDistRecipients.length == primaryDistShares.length, "Invalid payment params");      

      MAX_TOKEN_SUPPLY = limits[0];
      PRICE = limits[1];
      MAX_TOTAL_MINTS_BY_ADDRESS = limits[2];
      MAX_TXN_MINT_LIMIT = limits[3];

      PRIVATE_SALE_TIMESTAMP = timestamps[0];
      PUBLIC_SALE_TIMESTAMP = timestamps[1];      

      _grantRole(DEFAULT_ADMIN_ROLE, superAdmin);

      _setDefaultRoyalty(secondaryDistRecipient, secondaryDistShare);    

  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, IERC721A, AccessControl, ERC2981)
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

  /**
  * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
  */
  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);
    // _resetTokenRoyalty(tokenId);
  }
}

