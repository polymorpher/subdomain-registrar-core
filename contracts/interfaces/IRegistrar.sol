// SPDX-License-Identifier: BSD-2-Clause
pragma solidity >=0.8.4;

interface IRegistrar {
    event OwnerChanged(bytes32 indexed label, address indexed oldOwner, address indexed newOwner);
    event DomainConfigured(bytes32 indexed label);
    event DomainUnlisted(bytes32 indexed label);
    event NewRegistration(bytes32 indexed label, string subdomain, address indexed owner, address indexed referrer, uint price);
    event RentPaid(bytes32 indexed label, string subdomain, uint amount, uint expirationDate);

    // InterfaceID of these four methods is 0xc1b15f5a
    function query(bytes32 label, string calldata subdomain) external view returns (string memory domain, uint signupFee, uint rent, uint referralFeePPM);

    function register(bytes32 label, string calldata subdomain, address owner, address payable referrer, address resolver) external payable;

    function rentDue(bytes32 label, string calldata subdomain) external view returns (uint timestamp);

    function payRent(bytes32 label, string calldata subdomain) external payable;

    function configureDomainFor(string memory name, uint price, uint referralFeePPM, address payable _owner, address _transfer) external;

    /// Harmony specific implementation: https://github.com/harmony-one/subdomain-registrar/blob/one-names-v4/contracts/EthRegistrarSubdomainRegistrar.sol#L139
    function configureDomainFor(string memory name, uint price, address payable referralAddress, address payable _owner, address _transfer) external;

    /// Harmony specific implementation: https://github.com/harmony-one/subdomain-registrar/blob/one-names-v4/contracts/EthRegistrarSubdomainRegistrar.sol#L229
    function register(bytes32 label, string calldata subdomain, address _subdomainOwner, uint duration, string calldata url, address resolver) external payable;

    /// Harmony specific: https://github.com/harmony-one/subdomain-registrar/blob/one-names-v4/contracts/EthRegistrarSubdomainRegistrar.sol#L59
    function rentPrice(string memory name, uint duration) external view returns (uint256);

    function transfer(string memory name, address payable newOwner) external;

    /// Harmony specific: https://github.com/harmony-one/subdomain-registrar/blob/one-names-v4/contracts/EthRegistrarSubdomainRegistrar.sol#L64
    function renew(bytes32 label, string calldata subdomain, uint duration) external payable;
}
