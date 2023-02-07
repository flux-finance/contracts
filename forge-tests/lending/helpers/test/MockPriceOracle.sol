// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../interfaces/IOndoOracle.sol";

contract MockPriceOracle is IOndoOracle {
  /// @notice contract storage for fToken's underlying asset prices
  mapping(address => uint256) public fTokenToUnderlyingPrice;

  constructor(address fCashAddress) {
    fTokenToUnderlyingPrice[fCashAddress] = 1000000000000000000;
  }

  function getUnderlyingPrice(
    address fToken
  ) external view override returns (uint256) {
    return fTokenToUnderlyingPrice[fToken];
  }

  function setPrice(address fToken, uint256 price) external override {
    fTokenToUnderlyingPrice[fToken] = price;
  }

  // Unused.
  function owner() external view returns (address) {
    return msg.sender;
  }

  function transferOwnership(address) external {}

  function acceptOwnership() external {}

  function setFTokenToCToken(address, address) external {}

  function setOracle(address) external {}

  function fTokenToCToken(address) external returns (address) {}
}
