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

import "./IOndoPriceOracle.sol";
import "contracts/lending/compound/Ownable.sol";

/// @notice Interface for generalizing different cToken oracles
interface CTokenOracle {
  function getUnderlyingPrice(address cToken) external view returns (uint256);
}

/// @notice Helper interface for standardizing common calls to
///         fTokens and cTokens
interface CTokenLike {
  function underlying() external view returns (address);
}

/**
 * @title OndoPriceOracle
 * @author Ondo Finance
 * @notice This contract acts as a custom price oracle for the flux finance
 *         lending market. It allows for the owner to set the underlying price
 *         directly in contract storage or set an fToken-to-cToken
 *         association for piggy backing on an existing cToken's oracle.
 */
contract OndoPriceOracle is IOndoPriceOracle, Ownable {
  /// @notice Initially set to contracts/lending/compound/uniswap/UniswapAnchoredView.sol
  CTokenOracle public cTokenOracle =
    CTokenOracle(0x50ce56A3239671Ab62f185704Caedf626352741e);

  /// @notice Contract storage for fToken's underlying asset prices
  mapping(address => uint256) public fTokenToUnderlyingPrice;

  /// @notice fToken to cToken associations for piggy backing off
  ///         of cToken oracles
  mapping(address => address) public fTokenToCToken;

  /**
   * @notice Retrieve the price of the provided fToken
   *         contract's underlying asset
   *
   * @param fToken fToken contract address
   *
   * @dev This function first attempts to check if the price has been set directly
          in contract storage. If not set, we check if there is a corresponding cToken
   *      set within `fTokenToCToken` and piggy back on an external price oracle.
   */
  function getUnderlyingPrice(
    address fToken
  ) external view override returns (uint256) {
    if (fTokenToUnderlyingPrice[fToken] != 0) {
      return fTokenToUnderlyingPrice[fToken];
    } else {
      // Price is not manually set, attempt to retrieve price from Compound's
      // oracle
      address cTokenAddress = fTokenToCToken[fToken];
      return cTokenOracle.getUnderlyingPrice(cTokenAddress);
    }
  }

  /**
   * @notice Sets the price of an fToken contract's underlying asset
   *
   * @param fToken fToken contract address
   * @param price  New price of underlying asset
   */
  function setPrice(address fToken, uint256 price) external override onlyOwner {
    uint256 oldPrice = fTokenToUnderlyingPrice[fToken];
    fTokenToUnderlyingPrice[fToken] = price;
    emit UnderlyingPriceSet(fToken, oldPrice, price);
  }

  /**
   * @notice Associates a custom fToken with an external cToken
   *
   * @param fToken fToken contract address
   * @param cToken cToken contract address
   */
  function setFTokenToCToken(
    address fToken,
    address cToken
  ) external override onlyOwner {
    address oldCToken = fTokenToCToken[fToken];
    _setFTokenToCToken(fToken, cToken);
    emit FTokenToCTokenSet(fToken, oldCToken, cToken);
  }

  /**
   * @notice Sets the external oracle address
   *
   * @param newOracle cToken oracle contract address
   */
  function setOracle(address newOracle) external override onlyOwner {
    address oldOracle = address(cTokenOracle);
    cTokenOracle = CTokenOracle(newOracle);
    emit CTokenOracleSet(oldOracle, newOracle);
  }

  /**
   * @notice Private implementation function for setting fToken
   *         to cToken implementation
   *
   * @param fToken fToken contract address
   * @param cToken cToken contract address
   */
  function _setFTokenToCToken(address fToken, address cToken) internal {
    require(
      CTokenLike(fToken).underlying() == CTokenLike(cToken).underlying(),
      "cToken and fToken must have the same underlying asset if cToken nonzero"
    );
    fTokenToCToken[fToken] = cToken;
  }
}
