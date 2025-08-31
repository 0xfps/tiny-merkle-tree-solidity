import MiniMerkleTree, { smolPadding } from "@fifteenfigures/mini-merkle-tree";
import { AbiCoder, keccak256 } from "ethers";
import { poseidon } from "poseidon-hash";

export function getRoot(leafNo: number): { leaves: string [], tree: MiniMerkleTree} {
    const coder = AbiCoder.defaultAbiCoder()
    let leafs = [];
    for (let i = 0; i < leafNo; i++) {
        leafs.push(i)
    }

    let leaves = leafs.map(function (leaf) {
        const encode = coder.encode(["string"], [leaf.toString()])
        return smolPadding(`0x${poseidon([keccak256(encode)]).toString(16)}`)
    })

    const tree = new MiniMerkleTree(leaves)
    return { leaves, tree }
}