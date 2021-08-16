// SPDX-License-Identifier: BSD-2-Clause
pragma solidity >=0.8.4;

interface ReverseRegistrarInterface {
    function claim(address owner) external returns (bytes32);

    function node(address addr) external returns (bytes32);

    function setName(string memory name) external returns (bytes32);

    function claimWithResolver(address owner, address resolver) external returns (bytes32);
    // DOES NOT EXIST in vanilla ens/ReverseRegistrar.sol. Added in ens-contracts/contracts/registry/ReverseRegistrar
    function claimForAddr(address addr, address owner) external;
    // DOES NOT EXIST in vanilla ens/ReverseRegistrar.sol. Added in ens-contracts/contracts/registry/ReverseRegistrar
    function claimWithResolverForAddr(
        address addr,
        address owner,
        address resolver
    ) external returns (bytes32);
}
