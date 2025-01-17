// SPDX-License-Identifier: BSD-2-Clause
pragma solidity >=0.8.4;

import "./interfaces/ENS.sol";
import "./Resolver.sol";

/**
 * @dev A test resolver implementation
 */
contract TestResolver is Resolver {
    ENS ens;

    mapping (bytes32 => address) addresses;

    constructor() {
    }

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == 0x01ffc9a7 || interfaceID == 0x3b3b57de;
    }

    function addr(bytes32 node) public view override returns (address) {
        return addresses[node];
    }

    function setAddr(bytes32 node, address addr_) public override {
        addresses[node] = addr_;
    }
}
