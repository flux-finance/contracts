/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.6.12;

/// @notice Taken from contracts/lending/compound/PriceOracle.sol
interface PriceOracle {
  /**
   * @notice Get the underlying price of a fToken asset
   * @param fToken The fToken to get the underlying price of
   * @return The underlying asset price mantissa (scaled by 1e18).
   */
  function getUnderlyingPrice(address fToken) external view returns (uint);
}

interface IOndoPriceOracle is PriceOracle {
  function setPrice(address fToken, uint256 price) external;

  function setFTokenToCToken(address fToken, address cToken) external;

  function setOracle(address newOracle) external;

  /**
   * @dev Event for when a fToken to cToken association is set
   *
   * @param fToken    fToken address
   * @param oldCToken Old cToken association
   * @param newCToken New cToken association
   */
  event FTokenToCTokenSet(
    address indexed fToken,
    address oldCToken,
    address newCToken
  );

  /**
   * @dev Event for when a fToken's underlying asset's price is set
   *
   * @param fToken   fToken address
   * @param oldPrice Old underlying asset's price
   * @param newPrice New underlying asset's price
   */
  event UnderlyingPriceSet(
    address indexed fToken,
    uint256 oldPrice,
    uint256 newPrice
  );

  /**
   * @dev Event for when the cToken oracle is set
   *
   * @param oldOracle Old cToken oracle
   * @param newOracle New cToken oracle
   */
  event CTokenOracleSet(address oldOracle, address newOracle);
}
