# Tiny Merkle Tree

An incremental, append-only Merkle tree implemented entirely in Solidity with `O(log N)` insertion time and O(depth) storage.

`TinyMerkleTree` is designed to efficiently compute Merkle roots for very large trees, up to billions of leaves, without storing the full tree or recomputing historical branches. It is optimized for on-chain usage and zero-knowledge–friendly applications.

The core design goal is `O(log N)` root computation per insertion, even for extremely large trees, e.g. depth 32 ≈ 4.29 billion leaves, while minimizing on-chain storage.

This is achieved by:

- Storing only the most recent unresolved hash at each depth.
- Incrementally propagating hashes upward only when sibling pairs exist.
- Never recomputing or iterating over historical leaves.

## Features
- Incremental append-only Merkle tree.
- `O(log N)` time complexity per insertion.
- Constant storage growth proportional only to tree depth.
- Fully on-chain and deterministic.
- Uses Poseidon hash (ZK-friendly).
- Tracks the last 64 Merkle roots.
- Scales to extremely large trees (e.g. depth 32 ≈ 4.29B leaves).

## Motivation
Standard Merkle tree implementations in Solidity are either:

- Too expensive (recompute large parts of the tree), or
- Too storage-heavy (store all intermediate nodes).<br>

TinyMerkleTree avoids both problems by storing only the most recent unresolved hash at each depth, allowing the tree to grow indefinitely while keeping gas usage predictable and low.

## Tree Model

- Fixed depth set at deployment.
- Maximum number of leaves: `2^DEPTH`.
- Leaves are appended sequentially.
- No leaf updates or deletions.

## Depth Indexing

- Depth `0` → base leaves.
- Depth `DEPTH` → root.

## Core Idea

When a new leaf is added:

- The leaf is inserted at depth 0.
- The algorithm propagates upward, depth by depth.

At each depth:

- If a sibling exists, the two hashes are combined.
- If no sibling exists, the hash is propagated upward unchanged.
- This continues until the root is produced.

At most **one operation per depth** is performed.

## Complexity Guarantees
| Operation      | Complexity   |
| -------------- | ------------ |
| Insert leaf    | `O(log N)`.  |
| Storage growth | `O(depth)`   |
| Root retrieval | `O(1)`       |

For a depth-32 tree, insertion always completes in **≤ 32 iterations**, regardless of how many leaves already exist.

## Storage Layout

Instead of storing all nodes, the contract maintains:

### Per Depth

`depthLengths[depth]`<br>
Number of nodes created at that depth.

`depthHashes[depth]`<br>
The most recent hash at that depth.

### Global

`length`<br>
Total number of leaves.

`root`<br>
Current Merkle root.

`last64Roots`<br>
Circular buffer containing the last 64 roots.

This ensures storage usage does not grow with the number of leaves.

## Pairing Logic

At each depth:

- If the number of nodes is odd, the incoming hash has no sibling and is propagated upward.
- If the number of nodes is even, the incoming hash is paired with the stored sibling and hashed.
- Hashes are sorted before hashing to ensure deterministic ordering.

This behaves similarly to binary carry propagation.

## Root History

The contract stores the **last 64 Merkle roots** using a circular buffer.<br>
This is useful for:

- Verifying membership proofs against recent states.
- Supporting delayed withdrawals or finality windows.
- Preventing reliance on a single mutable root.

## Hash Function

- Uses `Poseidon` hash from the `PoseidonT2` and `PosiedonT3` libraries.
- Optimized for zero-knowledge circuits.
- Suitable for privacy protocols and ZK rollups.

## Limitations

- Append-only (no updates or deletions).
- Fixed depth (cannot be resized).
- No built-in proof generation.
- Sequential insertion only (no batch inserts).

## Example Use Cases

- Privacy mixers.
- Incremental commitment trees.
- ZK membership sets.
- Rollup state roots.
- On-chain registries with large cardinality.

## Security Notes

- Tree capacity is strictly capped at `2^DEPTH`.
- Deterministic hash ordering prevents ambiguity.
- Root history is bounded to avoid unbounded storage growth.

## License
MIT

## Author
**0xfps**<br>
[GitHub](https://github.com/0xfps), [X](https://x.com/0xfps).

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```