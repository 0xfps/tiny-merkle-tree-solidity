// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title   TinyMerkleTree.
 * @author  fps (@0xfps).
 * @dev     A small, simple MerkleTree peripheral contract.
 * @notice  The implementation in this contract was written solely because,
 *          I found it difficult to implement a merkle tree in pure Solidity
 *          and, sources I studied, Github solidity merkle tree repos I went
 *          through didn't have what I wanted.
 *
 *          Merkle trees consume a lot of gas during computation, as whenever
 *          leaves are added to the tree, a new root is generated. This isn't
 *          a big deal for small trees with depths of 2 to 4. However, for
 *          slightly larger or even large trees, it comes at a cost of gas.
 *
 *          My own merkle tree algorithm operates on a simple principle:
 *          Stay on the most recent leaf as possible at all times. On each
 *          tree depth, starting from depth 0, I either calculate the new leaf
 *          which is a hash of the current leaf and already stored leaf on that
 *          depth if the depth is even. If the depth is odd, I simply return the
 *          leaf. This is repeated until we have a depth with just two leaves in
 *          it, which in this case, when hashed, will give us the new root.
 *
 *          A depth is considered complete if the length of hashes on that depth
 *          multiplied by two is equal to the length of the depth below it. Of
 *          course, this doesn't apply to the zero depth.
 *
 *          Leafs on the zero depth are stored no matter what. But for other depths
 *          the calculated leafs (hashes) are stored once the depth is considered
 *          complete.
 *
 *          Careful note should be taken to ignore `levelLengths` and `levelHashes`.
 *          Their data as the tree progresses will become jumbled due to the
 *          computations, nevertheless, the root calculations will be accurate.
 *
 *          I still don't think I'm clear.
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
    mapping(uint8 depth => uint40 levelLength) public levelLengths;
    // Last stored hash for each depth.
    mapping(uint8 depth => bytes32 levelHash) public levelHashes;

    /**
     * @notice  I expect that for a start, a leaf should be set to
     *          make a root available.
     */
    constructor() {
        bytes32 leaf = keccak256(abi.encode("0"));
        root = keccak256(abi.encodePacked(leaf));

        length = 1;
        levelLengths[0] = 1;
        levelHashes[0] = leaf;
    }

    function _addLeaf(string memory _leaf) internal returns (bytes32 _root) {
        if (length++ == MAX_LEAVES_LENGTH) revert("Tree Full!");

        bytes32 leaf = keccak256(abi.encode(_leaf));

        levelLengths[0] = length;

        uint40 newLength = length;
        uint8 depth = 0;
        bytes32 currentHash = leaf;

        while(newLength >= 2) {
            currentHash = _getHashForLevel(newLength, depth, currentHash);
            newLength = (newLength + 1) / 2;
            depth++;
        }

        _root = currentHash;
        _storeRoot(_root);
        root = _root;
    }

    function _getHashForLevel(uint40 len, uint8 depth, bytes32 leaf) internal returns (bytes32 hash) {
        bytes32 hashLeft;
        bytes32 hashRight;

        // Last two leaves leading to root.
        if (len == 2) {
            (hashLeft, hashRight) = _sortHashes(levelHashes[depth], leaf);
            hash = keccak256(abi.encodePacked(hashLeft, hashRight));
            
            levelHashes[depth + 1] = hash; // New Root.
            levelLengths[depth + 1]++;
        } else {
            if (len % 2 == 1)
                hash = leaf;
            else {
                (hashLeft, hashRight) = _sortHashes(levelHashes[depth], leaf);
                hash = keccak256(abi.encodePacked(hashLeft, hashRight));
            }
        }

        if (depth == 0)
            levelHashes[depth] = leaf;
        else {
            uint40 curLevelLength = levelLengths[depth];
            uint40 prevLevelLength = levelLengths[depth - 1];

            // When leaf is added.
            // Prev depth handles itself via the iteration.
            if (((curLevelLength + 1) * 2 == prevLevelLength)) {
                levelLengths[depth]++;
                // Append latest leaf if this is last stage to root because leaf yielded root.
                // If not, append the last hash.
                // Note must be taken that, for lengths % 2 != 0, the hash is == the leaf (L54).
                levelHashes[depth] = len == 2 ? leaf : hash;
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