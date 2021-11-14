// SPDX-License-Identifier: BSD-2-Clause
pragma solidity >=0.8.4;

import "./interfaces/ENS.sol";
import "./Resolver.sol";
import "./interfaces/IRegistrar.sol";

abstract contract AbstractSubdomainRegistrar is IRegistrar {

    // namehash('eth')
    bytes32 constant public TLD_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    bool public stopped = false;
    address public registrarOwner;
    address public migration;

    address public registrar;

    ENS ens_;

    function ens() override external view returns (address){
        return address(ens_);
    }

    modifier owner_only(bytes32 label) {
        require(owner(label) == msg.sender);
        _;
    }

    modifier not_stopped() {
        require(!stopped);
        _;
    }

    modifier registrar_owner_only() {
        require(msg.sender == registrarOwner);
        _;
    }

    event DomainTransferred(bytes32 indexed label, string name);

    constructor(ENS _ens) {
        ens_ = _ens;
        registrar = ens_.owner(TLD_NODE);
        registrarOwner = msg.sender;
    }

    function doRegistration(bytes32 node, bytes32 label, address subdomainOwner, Resolver resolver) internal {
        // Get the subdomain so we can configure it
        ens_.setSubnodeOwner(node, label, address(this));

        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        // Set the subdomain's resolver
        ens_.setResolver(subnode, address(resolver));

        // Set the address record on the resolver
        resolver.setAddr(subnode, subdomainOwner);

        // Pass ownership of the new subdomain to the registrant
        ens_.setOwner(subnode, subdomainOwner);
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return (
        (interfaceID == 0x01ffc9a7) // supportsInterface(bytes4)
        || (interfaceID == 0xc1b15f5a) // RegistrarInterface
        );
    }

    function rentDue(bytes32 /*label*/, string calldata /*subdomain*/) external override virtual view returns (uint timestamp) {
        return 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    /**
     * @dev Sets the resolver record for a name in ENS.
     * @param name The name to set the resolver for.
     * @param resolver The address of the resolver
     */
    function setResolver(string memory name, address resolver) public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        bytes32 node = keccak256(abi.encodePacked(TLD_NODE, label));
        ens_.setResolver(node, resolver);
    }

    /**
     * @dev Configures a domain for sale.
     * @param name The name to configure.
     * @param price The price in wei to charge for subdomain registrations
     * @param referralFeePPM The referral fee to offer, in parts per million
     */
    function configureDomain(string memory name, uint price, uint referralFeePPM) public {
        configureDomainFor(name, price, referralFeePPM, payable(msg.sender), address(0x0));
    }

    /**
     * @dev Stops the registrar, disabling configuring of new domains.
     */
    function stop() public not_stopped registrar_owner_only {
        stopped = true;
    }

    /**
     * @dev Sets the address where domains are migrated to.
     * @param _migration Address of the new registrar.
     */
    function setMigrationAddress(address _migration) public registrar_owner_only {
        require(stopped);
        migration = _migration;
    }

    function transferOwnership(address newOwner) public registrar_owner_only {
        registrarOwner = newOwner;
    }

    /**
     * @dev Returns information about a subdomain.
     * @param label The label hash for the domain.
     * @param subdomain The label for the subdomain.
     * @return domain The name of the domain, or an empty string if the subdomain
     *                is unavailable.
     * @return price The price to register a subdomain, in wei.
     * @return rent The rent to retain a subdomain, in wei per second.
     * @return referralFeePPM The referral fee for the dapp, in ppm.
     */
    function query(bytes32 label, string calldata subdomain) external view virtual override returns (string memory domain, uint price, uint rent, uint referralFeePPM);

    function owner(bytes32 label) public view virtual returns (address);

    function configureDomainFor(string memory name, uint price, uint referralFeePPM, address payable _owner, address _transfer) override public virtual;

    /// Harmony specific implementation: https://github.com/harmony-one/subdomain-registrar/blob/one-names-v4/contracts/EthRegistrarSubdomainRegistrar.sol#L139
    function configureDomainFor(string memory name, uint price, address payable referralAddress, address payable _owner, address _transfer) override virtual external {

    }

    /// Harmony specific implementation: https://github.com/harmony-one/subdomain-registrar/blob/one-names-v4/contracts/EthRegistrarSubdomainRegistrar.sol#L229
    function register(bytes32 label, string calldata subdomain, address _subdomainOwner, uint duration, string calldata url, address resolver) override virtual external payable {

    }

    /// Harmony specific: https://github.com/harmony-one/subdomain-registrar/blob/one-names-v4/contracts/EthRegistrarSubdomainRegistrar.sol#L59
    function rentPrice(string memory /*name*/, uint /*duration*/) override virtual external view returns (uint256) {
        return 0;
    }

    /// Harmony specific: https://github.com/harmony-one/subdomain-registrar/blob/one-names-v4/contracts/EthRegistrarSubdomainRegistrar.sol#L64
    function renew(bytes32 label, string calldata subdomain, uint duration) override external payable {

    }
}
