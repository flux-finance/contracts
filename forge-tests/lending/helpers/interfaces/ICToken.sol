// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "contracts/lending/tokens/cErc20Delegate/CTokenInterfaces.sol";

/// @dev This contract imports cTokenInterface where protocolSeizeShare
///      is set to 2.8% (original value)
abstract contract ICToken is
  CDelegateInterface,
  CDelegatorInterface,
  CErc20Interface,
  CTokenInterface
{
  /// KYC ///
  address public kycRegistry;

  uint256 public kycRequirementGroup;

  function getKYCStatus(
    uint256 kycRequirementGroup,
    address account
  ) external view virtual returns (bool);

  function setKYCRegistry(address _kycRegistry) external virtual;

  function setKYCRequirementGroup(
    uint256 _kycRequirementGroup
  ) external virtual;
}
