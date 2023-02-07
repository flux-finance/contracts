pragma solidity 0.8.16;

interface IUnitroller {
  function _setPendingImplementation(
    address newPendingImplementation
  ) external returns (uint);

  function _acceptImplementation() external returns (uint);

  function _setPendingAdmin(address newPendingAdmin) external returns (uint);

  function _acceptAdmin() external returns (uint);

  function pendingComptrollerImplementation() external returns (address);

  function comptrollerImplementation() external returns (address);
}
