// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IGoveranceBravoDelegator {
  function _setImplementation(address implementation_) external;

  function admin() external view returns (address);

  function pendingAdmin() external view returns (address);

  function implementation() external view returns (address);
}
