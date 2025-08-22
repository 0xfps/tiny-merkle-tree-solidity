import { AbiCoder } from "ethers";
import keccak256 from "keccak256";

export function getRoot(leafNo: number): string {
    const coder = AbiCoder.defaultAbiCoder()
    let leafs = [];
    for (let i = 0; i < leafNo; i++) {
        leafs.push(i)
    }

    let leaves = leafs.map(function (leaf) {
        const encode = coder.encode(["string"], [leaf.toString()])
        return hash(encode)
    })

    // Start tree with all the leaves.
    let tree = [leaves];
    let length = leaves.length;

    // All depths are stored in separate arrays.
    // [[depth(n+1) or root], [depth(n)], ..., [depth0]].
    // New leaves for new depths are recomputed based off of the
    // previous ones.
    while (length >= 2) {
        let concatLeaves;
        const hashedPairs = []

        // When length == 2, which will eventually be so given
        // the division applied at the end, it is the last two
        // leaves to yield the root.
        if (length == 2) {
            concatLeaves = concatenateArrangedLeaves(leaves[0], leaves[1]);
            hashedPairs.push(hash(concatLeaves));
            tree.unshift(hashedPairs);
            break;
        }

        // Iterate over the leaves in the array.
        // length will always match leaves [ at depth].length;
        // This loop runs in a way that if there's an extra leaf after
        // grouping, it's not touched here.
        for (let i = 0; i < length - 1; i += 2) {
            concatLeaves = concatenateArrangedLeaves(leaves[i], leaves[i + 1])
            hashedPairs.push(hash(concatLeaves));
        }

        // The leaf not touched in the loop as a result of the depth leaves being
        // odd is simply moved to the next one.
        if (length % 2 == 1) hashedPairs.push(leaves[length - 1])
        
            
        // New leaf depths are stored in front.
        tree.unshift(hashedPairs)
        leaves = hashedPairs

        length = Math.floor((length + 1) / 2)
    }

    const root = tree[0][0]
    return root
}

function hash(leaf: string): string {
    return `0x${keccak256(leaf).toString("hex")}`
}

function concatenateArrangedLeaves(leaf1: string, leaf2: string) {
    if (leaf1 < leaf2)
        return Buffer.concat([
            Buffer.from(leaf1),
            Buffer.from(leaf2.slice(2))
        ]).toString();

    return Buffer.concat([
        Buffer.from(leaf2),
        Buffer.from(leaf1.slice(2))
    ]).toString();
}