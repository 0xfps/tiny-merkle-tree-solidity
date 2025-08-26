import MiniMerkleTree from "@fifteenfigures/mini-merkle-tree";
import { AbiCoder, sha256 } from "ethers";

export function getRoot(leafNo: number): string {
    const coder = AbiCoder.defaultAbiCoder()
    let leafs = [];
    for (let i = 0; i < leafNo; i++) {
        leafs.push(i)
    }

    let leaves = leafs.map(function (leaf) {
        const encode = coder.encode(["string"], [leaf.toString()])
        return sha256(encode)
    })

    const tree = new MiniMerkleTree(leaves)
    return tree.root
}