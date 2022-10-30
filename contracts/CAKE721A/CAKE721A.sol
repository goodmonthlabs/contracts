// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CAKE721A is ERC721A, ERC721AQueryable, ERC721ABurnable {

  uint256 public MAX_TOKEN_SUPPLY;
  uint256 public MAX_TOTAL_MINTS_BY_ADDRESS;
  uint256 public MAX_TXN_MINT_LIMIT;
  uint256 public PRIVATE_SALE_TIMESTAMP;
  uint256 public PUBLIC_SALE_TIMESTAMP;  
  bytes32 public MERKLEROOT;  
  uint256 public PRICE;
  string public PROVENANCE_HASH;
  string public BASE_URI = '';

  constructor(
    string memory name, 
    string memory symbol, 
    uint256 supply,
    uint256 price,
    uint256 maxTotalMints,
    uint256 maxTxnMints,
    uint256 privateSaleTimestamp,
    uint256 publicSaleTimestamp   
    ) ERC721A(name, symbol) {
      MAX_TOKEN_SUPPLY = supply;
      PRICE = price;
      MAX_TOTAL_MINTS_BY_ADDRESS = maxTotalMints;
      MAX_TXN_MINT_LIMIT = maxTxnMints;
      PRIVATE_SALE_TIMESTAMP = privateSaleTimestamp;
      PUBLIC_SALE_TIMESTAMP = publicSaleTimestamp;      
  }

  function mint(address to, uint256 quantity, bytes32[] calldata proof) external payable {
    string memory eligibilityCheck = checkMintEligibilityMethod(to, quantity, proof, msg.value); 
    require(bytes(eligibilityCheck).length==0, eligibilityCheck);
    _mint(to, quantity);
  }

  function reserveTokens(address to, uint256 quantity) external {  
    require(totalSupply() + quantity <= MAX_TOKEN_SUPPLY, 'Purchase exceeds max token supply.');    
    _mint(to, quantity);
  }
  
  function checkMintEligibilityMethod(address to, uint256 quantity, bytes32[] calldata proof, uint256 value) public view returns(string memory) {
    
    require(block.timestamp >= PRIVATE_SALE_TIMESTAMP || block.timestamp >= PUBLIC_SALE_TIMESTAMP, 'Sale is not active.');
    
    if(block.timestamp < PUBLIC_SALE_TIMESTAMP){
      require(verifyWhitelistMembership(proof, to), "Wallet is not on the whitelist.");
    }

    require(totalSupply() + quantity <= MAX_TOKEN_SUPPLY, 'Purchase exceeds max token supply.');  
    
    if(MAX_TXN_MINT_LIMIT > 0){
     require(quantity <= MAX_TXN_MINT_LIMIT, 'Purchase exceeds max number of mints per transaction.'); 
    }

    if(MAX_TOTAL_MINTS_BY_ADDRESS > 0){
     require(balanceOf(to) + quantity <= MAX_TOTAL_MINTS_BY_ADDRESS, 'Purchase exceeds max total mints by address.'); 
    }

    if(PRICE > 0){
      require(value >= PRICE * quantity , 'Payment is below mint price.');
    }
          
    return '';
  }

  function verifyWhitelistMembership(bytes32[] calldata proof, address _address) internal view returns (bool){        
    bytes32 leaf = keccak256(abi.encodePacked(_address));        
    return MerkleProof.verify(proof, MERKLEROOT, leaf);
  }

  function setMerkleroot(bytes32 merkleroot) external {
    MERKLEROOT = merkleroot;
  }

  function setTotalSupply(uint256 supply) external {
    require(supply >= totalSupply(), 'Cannot set supply to be lower than existing supply.');
    MAX_TOKEN_SUPPLY = supply;
  }

  function setMaxTotalMintsByAddrss(uint256 max) external {
    MAX_TOTAL_MINTS_BY_ADDRESS = max;
  }

  function setMaxMintsPerTxn(uint256 max) external {
    MAX_TXN_MINT_LIMIT = max;
  }

  function setPrice(uint256 price) external {
    require(price >= 0, 'Invalid price.');
    PRICE = price;
  }

  function setPrivateSaleTimestamp(uint256 timestamp) external {
    require(timestamp >= 0, 'Invalid timestamp.');
    PRIVATE_SALE_TIMESTAMP = timestamp;
  }

  function setPublicSaleTimestamp(uint256 timestamp) external {
    require(timestamp >= 0, 'Invalid timestamp.');
    PUBLIC_SALE_TIMESTAMP = timestamp;
  }

  function setProvenanceHash(string calldata provenanceHash) external {
    require(bytes(PROVENANCE_HASH).length==0, 'Provenance hash has already been set.');
    PROVENANCE_HASH = provenanceHash;
  }

  function _baseURI() internal view override returns (string memory) {
    return BASE_URI;
  }

  function setBaseURI(string calldata baseURI) external {
    BASE_URI = baseURI;
  }

}
