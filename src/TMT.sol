// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { TinyMerkleTree } from "./TinyMerkleTree.sol";

contract TMT is TinyMerkleTree {
    function addLeaf(string memory s) public {
        _addLeaf(s);
    }
}