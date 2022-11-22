// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract MurkyBase {
  constructor() {}

  function hashLeafPairs(bytes32 left, bytes32 right) public pure virtual returns (bytes32 _hash);
    
  function verifyProof(bytes32 root, bytes32[] memory proof, bytes32 valueToProve) external pure returns (bool) {
    // proof length must be less than max array size
    bytes32 rollingHash = valueToProve;
    uint256 length = proof.length;
    unchecked {
      for(uint i = 0; i < length; ++i){
        rollingHash = hashLeafPairs(rollingHash, proof[i]);
      }
    }
    return root == rollingHash;
  }

  function getRoot(bytes32[] memory data) public pure returns (bytes32) {
    require(data.length > 1, "won't generate root for single leaf");
    while(data.length > 1) {
      data = hashLevel(data);
    }
    return data[0];
  }

  function getProof(bytes32[] memory data, uint256 node) public pure returns (bytes32[] memory) {
    require(data.length > 1, "won't generate proof for single leaf");
    bytes32[] memory result = new bytes32[](log2ceilBitMagic(data.length));
    uint256 pos = 0;

    while(data.length > 1) {
      unchecked {
        if(node & 0x1 == 1) {
            result[pos] = data[node - 1];
        } 
        else if (node + 1 == data.length) {
            result[pos] = bytes32(0);  
        } 
        else {
            result[pos] = data[node + 1];
        }
        ++pos;
        node /= 2;
      }
      data = hashLevel(data);
    }
    return result;
  }

  function hashLevel(bytes32[] memory data) private pure returns (bytes32[] memory) {
    bytes32[] memory result;

    unchecked {
      uint256 length = data.length;
      if (length & 0x1 == 1){
        result = new bytes32[](length / 2 + 1);
        result[result.length - 1] = hashLeafPairs(data[length - 1], bytes32(0));
      } else {
        result = new bytes32[](length / 2);
    }
      uint256 pos = 0;
      for (uint256 i = 0; i < length-1; i+=2){
        result[pos] = hashLeafPairs(data[i], data[i+1]);
        ++pos;
      }
    }
    return result;
  }

  function log2ceil(uint256 x) public pure returns (uint256) {
    uint256 ceil = 0;
    uint pOf2;
    assembly {
      pOf2 := eq(and(add(not(x), 1), x), x)
    }
    
    unchecked {
      while( x > 0) {
        x >>= 1;
        ceil++;
      }
      ceil -= pOf2; // see above
    }
    return ceil;
  }

  function log2ceilBitMagic(uint256 x) public pure returns (uint256){
    if (x <= 1) {
      return 0;
    }
    uint256 msb = 0;
    uint256 _x = x;
    if (x >= 2**128) {
      x >>= 128;
      msb += 128;
    }
    if (x >= 2**64) {
      x >>= 64;
      msb += 64;
    }
    if (x >= 2**32) {
      x >>= 32;
      msb += 32;
    }
    if (x >= 2**16) {
      x >>= 16;
      msb += 16;
    }
    if (x >= 2**8) {
      x >>= 8;
      msb += 8;
    }
    if (x >= 2**4) {
      x >>= 4;
      msb += 4;
    }
    if (x >= 2**2) {
      x >>= 2;
      msb += 2;
    }
    if (x >= 2**1) {
      msb += 1;
    }

    uint256 lsb = (~_x + 1) & _x;
    if ((lsb == _x) && (msb > 0)) {
      return msb;
    } else {
      return msb + 1;
    }
  }
}