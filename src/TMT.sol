// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { TinyMerkleTree } from "./TinyMerkleTree.sol";

contract TMT is TinyMerkleTree {

    constructor(bytes32 initLeaf) TinyMerkleTree(initLeaf){}
    
    function addLeaf(bytes32 s) public {
        _addLeaf(s);
    }
}