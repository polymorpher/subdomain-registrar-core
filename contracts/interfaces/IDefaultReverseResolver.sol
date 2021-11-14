import "./ENS.sol";

interface IDefaultReverseResolver {
    function name(bytes32) external view returns (string memory);

    function ens() external view returns (ENS);

    function setName(bytes32 node, string memory _name) external;
}
