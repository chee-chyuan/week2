//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[2**8] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root
    uint256 constant public noOfLeaf = 8;
    uint256 immutable public totalHashSize;

    uint256 constant public layer1Zero = 0;
    uint256 public layer2Zero;
    uint256 public layer3Zero;
    // leaf => default 0 values at the respective level
    mapping(uint256 => uint256) defaultZeros;

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves

        totalHashSize = 2 ** 8;

        defaultZeros[noOfLeaf] = 0;
        for (uint256 leaves = noOfLeaf; leaves > 1; leaves = leaves / 2) {
            uint256 defaultZeroBefore = defaultZeros[leaves];
            defaultZeros[leaves / 2] = PoseidonT3.poseidon([defaultZeroBefore,defaultZeroBefore]);
        }
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree

        hashes[index] = hashedLeaf;
        uint256 tempIndex = index;

        for(uint256 n = noOfLeaf; n > 1; n = n/2) {
            if (tempIndex % 2 == 0) {
                uint256 hash = PoseidonT3.poseidon([hashedLeaf, defaultZeros[n]]);
                tempIndex = tempIndex + n;
                hashes[tempIndex] = hash;
            } else {
                uint256 hash = PoseidonT3.poseidon([hashes[tempIndex - 1], hashedLeaf]);
                tempIndex = tempIndex - 1 + n;
                hashes[tempIndex] = hash;
            }
        }

        index++;
        return hashes[totalHashSize - 1];
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        return verifyProof(a, b, c, input);
    }
}
