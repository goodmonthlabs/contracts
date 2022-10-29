// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CAKE721A is ERC721A, ERC721AQueryable {

  uint256 public MAX_TOKEN_SUPPLY;
  uint256 public MAX_TOTAL_MINTS_BY_ADDRESS;
  uint256 public MAX_TXN_MINT_LIMIT;
  uint256 public PRIVATE_SALE_TIMESTAMP;
  uint256 public PUBLIC_SALE_TIMESTAMP;  
  bytes32 public MERKLEROOT;

  constructor(
    string memory name, 
    string memory symbol, 
    uint256 supply,
    uint256 maxTotalMints,
    uint256 maxTxnMints,
    uint256 privateSaleTimestamp,
    uint256 publicSaleTimestamp   
    ) ERC721A(name, symbol) {
      MAX_TOKEN_SUPPLY = supply;
      MAX_TOTAL_MINTS_BY_ADDRESS = maxTotalMints;
      MAX_TXN_MINT_LIMIT = maxTxnMints;
      PRIVATE_SALE_TIMESTAMP = privateSaleTimestamp;
      PUBLIC_SALE_TIMESTAMP = publicSaleTimestamp;      
  }

  function mint(address to, uint256 quantity, bytes32[] calldata proof) external payable {
    string memory eligibilityCheck = checkMintEligibilityMethod(to, quantity, proof); 
    require(bytes(eligibilityCheck).length==0, eligibilityCheck);
    _mint(to, quantity);
  }

  function checkMintEligibilityMethod(address to, uint256 quantity, bytes32[] calldata proof) public view returns(string memory) {
    
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
          
    return '';
  }

  function verifyWhitelistMembership(bytes32[] calldata proof, address _address) internal view returns (bool){        
      bytes32 leaf = keccak256(abi.encodePacked(_address));        
      return MerkleProof.verify(proof, MERKLEROOT, leaf);
  }

  function setMerkleroot(bytes32 merkleroot) external {
      MERKLEROOT = merkleroot;
  }
}
