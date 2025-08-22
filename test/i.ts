import { AbiCoder, ethers } from "ethers";
import { getRoot } from "./mock-merkle-tree";
const coder = AbiCoder.defaultAbiCoder()

const encode = coder.encode(["string"], ["1"])
console.log(ethers.keccak256("0x1ac9120c3190758121a7ae65872e84a068eb0b5b9ec744758ad5c29ac96559ebc586dcbfc973643dc5f885bf1a38e054d2675b03fe283a5b7337d70dda9f7171"))

console.log(getRoot(2))