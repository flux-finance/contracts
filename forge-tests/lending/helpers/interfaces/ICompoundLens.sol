// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "./ICToken.sol";
import "./IOndoOracle.sol";

/// @dev File modified from source of truth at contracts/lending/compoundLens.sol
///      so that it can be used with forge

interface ComptrollerLensInterface {
  function markets(address) external view returns (bool, uint);

  function oracle() external view returns (IOndoOracle);

  function getAccountLiquidity(
    address
  ) external view returns (uint, uint, uint);

  function getAssetsIn(address) external view returns (ICToken[] memory);
}

interface ICompoundLens {
  struct CTokenMetadata {
    address cToken;
    uint exchangeRateCurrent;
    uint supplyRatePerBlock;
    uint borrowRatePerBlock;
    uint reserveFactorMantissa;
    uint totalBorrows;
    uint totalReserves;
    uint totalSupply;
    uint totalCash;
    bool isListed;
    uint collateralFactorMantissa;
    address underlyingAssetAddress;
    uint cTokenDecimals;
    uint underlyingDecimals;
  }

  struct CTokenBalances {
    address cToken;
    uint balanceOf;
    uint borrowBalanceCurrent;
    uint balanceOfUnderlying;
    uint tokenBalance;
    uint tokenAllowance;
  }

  struct CTokenUnderlyingPrice {
    address cToken;
    uint underlyingPrice;
  }

  struct AccountLimits {
    ICToken[] markets;
    uint liquidity;
    uint shortfall;
  }

  function cTokenMetadata(
    ICToken cToken
  ) external returns (CTokenMetadata memory);

  function cTokenMetadataAll(
    ICToken[] calldata cTokens
  ) external returns (CTokenMetadata[] memory);

  function cTokenBalances(
    ICToken cToken,
    address payable account
  ) external returns (CTokenBalances memory);

  function cTokenBalancesAll(
    ICToken[] calldata cTokens,
    address payable account
  ) external returns (CTokenBalances[] memory);

  function cTokenUnderlyingPrice(
    ICToken cToken
  ) external returns (CTokenUnderlyingPrice memory);

  function cTokenUnderlyingPriceAll(
    ICToken[] calldata cTokens
  ) external returns (CTokenUnderlyingPrice[] memory);

  function getAccountLimits(
    ComptrollerLensInterface comptroller,
    address account
  ) external returns (AccountLimits memory);
}
