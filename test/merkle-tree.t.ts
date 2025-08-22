import { ethers } from "hardhat";
import { getRoot } from "./mock-merkle-tree";
const assert = require("node:assert/strict")

// Quite a stress test, but no issues.
const LIMITS = [10, 100, 1000, 10000, 100000, 1000000];

describe("Test root", function () {
    it("Adds a range of leaves", async function () {
        for (const LIMIT of LIMITS) {
            const TMT = await ethers.getContractFactory("TMT")
            const tmt = await TMT.deploy()

            console.log("Testing for limit", LIMIT)

            for (let i = 1; i < LIMIT + 1; i++) {
                console.log("Added leaf", i)
                await tmt.addLeaf(i.toString())
                const root = await tmt.root()
                const jsRoot = getRoot(i + 1)

                assert(jsRoot == root)
            }

            console.log("Finished testing for limit", LIMIT)
            console.log("All roots match")
            console.log("\n")
        }
    })
})