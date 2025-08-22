import { ethers } from "hardhat";
import { getRoot } from "./mock-merkle-tree";
import { AbiCoder, keccak256 } from "ethers";
import Tree from "@0xfps/tiny-merkle-tree";
const assert = require("node:assert/strict")

// Quite a stress test, but no issues.
const LIMITS = [10, 100, 1000, 10000, 100000, 1000000];
let leaves: string[] = []

describe("Test root", function () {
    it("Adds a range of leaves", async function () {
        for (const LIMIT of LIMITS) {
            const TMT = await ethers.getContractFactory("TMT")
            const tmt = await TMT.deploy()

            console.log("Testing for limit", LIMIT)

            for (let i = 1; i < LIMIT + 1; i++) {
                await tmt.addLeaf(i.toString())
                const root = await tmt.root()

                for (let j = 0; j <= i; j++) {
                    const encode = new AbiCoder().encode(["string"], [j.toString()])
                    leaves.push(keccak256(encode))
                }

                const tree = new Tree(leaves)
                assert(tree.root == root)

                for (let k = 0; k <= i; k++) {
                    const encode = keccak256(new AbiCoder().encode(["string"], [k.toString()]))
                    const mProof = tree.generateMerkleProof(encode)
                    assert(tree.verifyProof(encode, mProof), true)
                }

                leaves = []
            }

            console.log("Finished testing for limit", LIMIT)
            console.log("All roots match")
            console.log("\n")
        }
    })
})