// SPDX-License-Identifier: BSD-2-Clause
pragma solidity >=0.8.4;

// Required so that tests can find it
import "@ensdomains/ens-contracts/contracts/registry/ENSRegistryWithFallback.sol";
//import "@ensdomains/ethregistrar/contracts/OldBaseRegistrarImplementation.sol";
import "@ensdomains/ens-contracts/contracts/ethregistrar/BaseRegistrarImplementation.sol";

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}
