// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

// Derived from contracts/lending/compound/Ownable.sol
// for solidity version compatibility with forge tests
interface IOwnable {
  function owner() external view returns (address);

  function acceptOwnership() external;

  function transferOwnership(address to) external;
}
