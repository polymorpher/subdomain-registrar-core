// SPDX-License-Identifier: BSD-2-Clause
pragma solidity >=0.8.4;

import "./AbstractSubdomainRegistrar.sol";
import "@ensdomains/ens/contracts/Deed.sol";
import "@ensdomains/ens/contracts/Registrar.sol";

/**
 * @dev Implements an ENS registrar that sells subdomains on behalf of their owners.
 *
 * Users may register a subdomain by calling `register` with the name of the domain
 * they wish to register under, and the label hash of the subdomain they want to
 * register. They must also specify the new owner of the domain, and the referrer,
 * who is paid an optional finder's fee. The registrar then configures a simple
 * default resolver, which resolves `addr` lookups to the new owner, and sets
 * the `owner` account as the owner of the subdomain in ENS.
 *
 * New domains may be added by calling `configureDomain`, then transferring
 * ownership in the ENS registry to this contract. Ownership in the contract
 * may be transferred using `transfer`, and a domain may be unlisted for sale
 * using `unlistDomain`. There is (deliberately) no way to recover ownership
 * in ENS once the name is transferred to this registrar.
 *
 * Critically, this contract does not check one key property of a listed domain:
 *
 * - Is the name UTS46 normalised?
 *
 * User applications MUST check these two elements for each domain before
 * offering them to users for registration.
 *
 * Applications should additionally check that the domains they are offering to
 * register are controlled by this registrar, since calls to `register` will
 * fail if this is not the case.
 */
contract SubdomainRegistrar is AbstractSubdomainRegistrar {

    struct Domain {
        string name;
        address payable owner;
        address transferAddress;
        uint price;
        uint referralFeePPM;
    }

    modifier new_registrar() {
        require(ens_.owner(TLD_NODE) != address(registrar));
        _;
    }

    mapping (bytes32 => Domain) domains;

    event TransferAddressSet(bytes32 indexed label, address addr);

    constructor(ENS ens) AbstractSubdomainRegistrar(ens_) { }

    /**
     * @dev owner returns the address of the account that controls a domain.
     *      Initially this is a null address. If the name has been
     *      transferred to this contract, then the internal mapping is consulted
     *      to determine who controls it. If the owner is not set,
     *      the previous owner of the deed is returned.
     * @param label The label hash of the deed to check.
     * @return The address owning the deed.
     */
    function owner(bytes32 label) public view override returns (address) {
        if (domains[label].owner != address(0x0)) {
            return domains[label].owner;
        }

        Deed domainDeed = deed(label);
        if (domainDeed.owner() != address(this)) {
            return address(0x0);
        }

        return domainDeed.previousOwner();
    }

    /**
     * @dev Transfers internal control of a name to a new account. Does not update
     *      ENS.
     * @param name The name to transfer.
     * @param newOwner The address of the new owner.
     */
    function transfer(string memory name, address payable newOwner) override public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        emit OwnerChanged(label, domains[label].owner, newOwner);
        domains[label].owner = newOwner;
    }

    /**
     * @dev Configures a domain, optionally transferring it to a new owner.
     * @param name The name to configure.
     * @param price The price in wei to charge for subdomain registrations.
     * @param referralFeePPM The referral fee to offer, in parts per million.
     * @param _owner The address to assign ownership of this domain to.
     * @param _transfer The address to set as the transfer address for the name
     *        when the permanent registrar is replaced. Can only be set to a non-zero
     *        value once.
     */
    function configureDomainFor(string memory name, uint price, uint referralFeePPM, address payable _owner, address _transfer) public override owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        Domain storage domain = domains[label];

        // Don't allow changing the transfer address once set. Treat 0 as "don't change" for convenience.
        require(domain.transferAddress == address(0x0) || _transfer == address(0x0) || domain.transferAddress == _transfer);

        if (domain.owner != _owner) {
            domain.owner = _owner;
        }

        if (keccak256(abi.encodePacked(domain.name)) != label) {
            // New listing
            domain.name = name;
        }

        domain.price = price;
        domain.referralFeePPM = referralFeePPM;

        if (domain.transferAddress != _transfer && _transfer != address(0x0)) {
            domain.transferAddress = _transfer;
            emit TransferAddressSet(label, _transfer);
        }

        emit DomainConfigured(label);
    }

    /**
     * @dev Sets the transfer address of a domain for after an ENS update.
     * @param name The name for which to set the transfer address.
     * @param transfer_ The address to transfer to.
     */
    function setTransferAddress(string memory name, address transfer_) public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        Domain storage domain = domains[label];

        require(domain.transferAddress == address(0x0));

        domain.transferAddress = transfer_;
        emit TransferAddressSet(label, transfer_);
    }

    /**
     * @dev Unlists a domain
     * May only be called by the owner.
     * @param name The name of the domain to unlist.
     */
    function unlistDomain(string memory name) public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        Domain storage domain = domains[label];
        emit DomainUnlisted(label);

        domain.name = '';
        domain.price = 0;
        domain.referralFeePPM = 0;
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
    function query(bytes32 label, string calldata subdomain) external view override returns (string memory domain, uint price, uint rent, uint referralFeePPM) {
        bytes32 node = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subnode = keccak256(abi.encodePacked(node, keccak256(bytes(subdomain))));

        if (ens_.owner(subnode) != address(0x0)) {
            return ('', 0, 0, 0);
        }

        Domain storage data = domains[label];
        return (data.name, data.price, 0, data.referralFeePPM);
    }

    /**
     * @dev Registers a subdomain.
     * @param label The label hash of the domain to register a subdomain of.
     * @param subdomain The desired subdomain label.
     * @param _subdomainOwner The account that should own the newly configured subdomain.
     * @param referrer The address of the account to receive the referral fee.
     */
    function register(bytes32 label, string calldata subdomain, address _subdomainOwner, address payable referrer, address resolver) external override not_stopped payable {
        address subdomainOwner = _subdomainOwner;
        bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subdomainLabel = keccak256(bytes(subdomain));

        // Subdomain must not be registered already.
        require(ens_.owner(keccak256(abi.encodePacked(domainNode, subdomainLabel))) == address(0));

        Domain storage domain = domains[label];

        // Domain must be available for registration
        require(keccak256(abi.encodePacked(domain.name)) == label);

        // User must have paid enough
        require(msg.value >= domain.price);

        // Send any extra back
        if (msg.value > domain.price) {
            payable(msg.sender).transfer(msg.value - domain.price);
        }

        // Send any referral fee
        uint256 total = domain.price;
        if (domain.referralFeePPM * domain.price > 0 && referrer != address(0x0) && referrer != domain.owner) {
            uint256 referralFee = (domain.price * domain.referralFeePPM) / 1000000;
            referrer.transfer(referralFee);
            total -= referralFee;
        }

        // Send the registration fee
        if (total > 0) {
            domain.owner.transfer(total);
        }

        // Register the domain
        if (subdomainOwner == address(0x0)) {
            subdomainOwner = msg.sender;
        }
        doRegistration(domainNode, subdomainLabel, subdomainOwner, Resolver(resolver));

        emit NewRegistration(label, subdomain, subdomainOwner, referrer, domain.price);
    }

    /**
     * @dev Upgrades the domain to a new registrar.
     * @param name The name of the domain to transfer.
     */
    function upgrade(string memory name) public owner_only(keccak256(bytes(name))) new_registrar {
        bytes32 label = keccak256(bytes(name));
        address transfer_ = domains[label].transferAddress;

        require(transfer_ != address(0x0));

        delete domains[label];

        Registrar(registrar).transfer(label, payable(address(uint160((transfer_)))));
        emit DomainTransferred(label, name);
    }

    /**
     * @dev Migrates the domain to a new registrar.
     * @param name The name of the domain to migrate.
     */
    function migrate(string memory name) public owner_only(keccak256(bytes(name))) {
        require(stopped);
        require(migration != address(0x0));

        bytes32 label = keccak256(bytes(name));
        Domain storage domain = domains[label];

        Registrar(registrar).transfer(label, payable(address(uint160((migration)))));

        SubdomainRegistrar(migration).configureDomainFor(
            domain.name,
            domain.price,
            domain.referralFeePPM,
            domain.owner,
            domain.transferAddress
        );

        delete domains[label];

        emit DomainTransferred(label, name);
    }

    function payRent(bytes32 /*label*/, string calldata /*subdomain*/) external override payable {
        revert();
    }

    function deed(bytes32 label) internal view returns (Deed) {
        (, address deedAddress,,,) = Registrar(registrar).entries(label);
        return Deed(deedAddress);
    }
}
