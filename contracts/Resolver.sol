// SPDX-License-Identifier: BSD-2-Clause
pragma solidity >=0.8.4;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

/**
 * @dev A basic interface for ENS resolvers.
 */
abstract contract Resolver {
    function supportsInterface(bytes4 interfaceID) public virtual pure returns (bool);
    function addr(bytes32 node) public virtual view returns (address);
    function setAddr(bytes32 node, address addr) public virtual;
}
