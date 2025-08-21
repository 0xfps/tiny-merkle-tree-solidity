// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title   TinyMerkleTree.
 * @author  fps (@0xfps).
 * @dev     A small, simple MerkleTree peripheral contract.
 */

abstract contract TinyMerkleTree {
    uint40 public immutable MAX_LEAVES_LENGTH = 2 ** 32;
    uint8 public constant STORED_ROOT_LENGTH = 32;

    /**
     * @notice  This number is used to determine which element to update in the
     *          last32Roots. If the index equals the `STORED_ROOT_LENGTH`, the
     *          rootIndex is reset to 0. This ensures that the contents of the
     *          last32Roots array are indeed the last 32 roots.
     */
    uint8 public rootIndex;
    bytes32[STORED_ROOT_LENGTH] public last32Roots;

    uint40 public length;
    bytes32 public root;

    // Number of hashes stored on each depth.
    mapping(uint8 depth => uint40 depthLength) public depthLengths;
    // Last stored hash for each depth.
    mapping(uint8 depth => bytes32 depthHash) public depthHashes;

    /**
     * @notice  I expect that for a start, a leaf should be set to
     *          make a root available.
     */
    constructor() {
        bytes32 leaf = keccak256(abi.encode("0"));
        root = keccak256(abi.encodePacked(leaf));

        length = 1;
        depthLengths[0] = 1;
        depthHashes[0] = leaf;
    }

    function _addLeaf(string memory _leaf) internal returns (bytes32 _root) {
        if (length++ == MAX_LEAVES_LENGTH) revert("Tree Full!");

        bytes32 leaf = keccak256(abi.encode(_leaf));

        depthLengths[0] = length;

        uint40 newLength = length;
        uint8 depth = 0;
        bytes32 currentHash = leaf;

        while(newLength >= 2) {
            currentHash = _getHashForDepth(newLength, depth, currentHash);
            newLength = (newLength + 1) / 2;
            depth++;
        }

        _root = currentHash;
        _storeRoot(_root);
        root = _root;
    }

    function _getHashForDepth(uint40 len, uint8 depth, bytes32 leaf) internal returns (bytes32 hash) {
        bytes32 hashLeft;
        bytes32 hashRight;

        // Last two leaves leading to root.
        if (len == 2) {
            (hashLeft, hashRight) = _sortHashes(depthHashes[depth], leaf);
            hash = keccak256(abi.encodePacked(hashLeft, hashRight));
            
            depthHashes[depth + 1] = hash; // New Root.
            // If a new root is computed, only increment the next depth if it's still 0.
            // Subsequent root computations to be stored at that depth doesn't need a
            // new increment.
            if (depthLengths[depth + 1] == 0) depthLengths[depth + 1]++;
        } else {
            if (len % 2 == 1)
                hash = leaf;
            else {
                (hashLeft, hashRight) = _sortHashes(depthHashes[depth], leaf);
                hash = keccak256(abi.encodePacked(hashLeft, hashRight));
            }
        }

        if (depth == 0)
            depthHashes[depth] = leaf;
        else {
            uint40 curDepthLength = depthLengths[depth];
            uint40 prevDepthLength = depthLengths[depth - 1];

            // When leaf is added.
            // Prev depth handles itself via the iteration.
            if (((curDepthLength + 1) * 2 == prevDepthLength)) {
                depthLengths[depth]++;
                // Append latest leaf if this is last stage to root because leaf yielded root.
                // If not, append the last hash.
                // Note must be taken that, for lengths % 2 != 0, the hash is == the leaf (L54).
                depthHashes[depth] = len == 2 ? leaf : hash;
            }
        }
    }

    function _sortHashes(bytes32 hashLeft, bytes32 hashRight) private pure returns (bytes32, bytes32) {
        return hashLeft < hashRight ? (hashLeft, hashRight) : (hashRight, hashLeft);
    }

    function _storeRoot(bytes32 _root) internal {
        if (rootIndex == STORED_ROOT_LENGTH) rootIndex = 0;
        last32Roots[rootIndex] = _root;
        rootIndex++;
    }
}