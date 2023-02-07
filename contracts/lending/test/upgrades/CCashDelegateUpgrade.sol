// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "../../tokens/cCash/CCash.sol";
import "./IMulticall.sol";

/// @notice Test only contract for testing a hypothetical upgrade to add multicall
///         functionality
contract CCashDelegateUpgrade is CCash, CDelegateInterface, IMulticall {
  /**
   * @notice Construct an empty delegate
   */
  constructor() {}

  /**
   * @notice Called by the delegator on a delegate to initialize it for duty
   * @param data The encoded bytes data for any initialization
   */
  function _becomeImplementation(bytes memory data) public virtual override {
    // Shh -- currently unused
    data;

    // Shh -- we don't ever want this hook to be marked pure
    if (false) {
      implementation = address(0);
    }

    require(
      msg.sender == admin,
      "only the admin may call _becomeImplementation"
    );
  }

  /**
   * @notice Called by the delegator on a delegate to forfeit its responsibility
   */
  function _resignImplementation() public virtual override {
    // Shh -- we don't ever want this hook to be marked pure
    if (false) {
      implementation = address(0);
    }

    require(
      msg.sender == admin,
      "only the admin may call _resignImplementation"
    );
  }

  /**
   * @notice Allows for arbitrary batched calls
   *
   * @dev All external calls made through this function will
   *      msg.sender == contract address
   *
   * @param exCallData Struct consisting of
   *       1) target - contract to call
   *       2) data - data to call target with
   *       3) value - eth value to call target with
   */
  function multiexcall(
    ExCallData[] calldata exCallData
  ) external payable override returns (bytes[] memory results) {
    require(msg.sender == admin, "You are not the admin!");
    results = new bytes[](exCallData.length);
    for (uint256 i = 0; i < exCallData.length; ++i) {
      (bool success, bytes memory ret) = address(exCallData[i].target).call{
        value: exCallData[i].value
      }(exCallData[i].data);
      require(success, "Call Failed");
      results[i] = ret;
    }
  }
}
