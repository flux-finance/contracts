// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "contracts/lending/IOndoPriceOracleV2.sol";

/// @dev This files exists for solidity compatibility within forge tests.
interface IOndoOracle {
  function owner() external view returns (address);

  function transferOwnership(address) external;

  function acceptOwnership() external;

  function getUnderlyingPrice(address) external returns (uint256);

  function setPrice(address, uint256) external;

  function setFTokenToCToken(address fToken, address cToken) external;

  function setOracle(address newOracle) external;

  function fTokenToCToken(address) external returns (address);

  function fTokenToUnderlyingPrice(address) external returns (uint256);
}

contract TestOndoOracleEvents {
  event FTokenToCTokenSet(
    address indexed fToken,
    address oldCToken,
    address newCToken
  );

  event UnderlyingPriceSet(
    address indexed fToken,
    uint256 oldPrice,
    uint256 newPrice
  );

  event CTokenOracleSet(address oldOracle, address newOracle);

  event PriceCapSet(
    address indexed fToken,
    uint256 oldPriceCap,
    uint256 newPriceCap
  );

  event ChainlinkOracleSet(
    address indexed fToken,
    address oldOracle,
    address newOracle,
    uint256 maxChainlinkOracleTimeDelay
  );

  event FTokenToOracleTypeSet(
    address indexed fToken,
    IOndoPriceOracleV2.OracleType oracleType
  );
}
