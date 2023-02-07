// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IComptroller {
  struct CompMarketState {
    /// @notice The market's last updated compBorrowIndex or compSupplyIndex
    uint224 index;
    /// @notice The block number the index was last updated at
    uint32 block;
  }

  function _setCompSpeeds(
    address[] memory oTokens,
    uint[] memory supplySpeeds,
    uint[] memory borrowSpeeds
  ) external;

  function borrowGuardianPaused(address) external view returns (bool);

  function allMarkets() external view returns (address[] memory);

  /// @notice The rate at which the flywheel distributes COMP, per block
  function compRate() external view returns (uint);

  /// @notice The portion of compRate that each market currently receives
  function compSpeeds(address) external view returns (uint);

  /// @notice The COMP market supply state for each market
  function compSupplyState(
    address
  ) external view returns (CompMarketState memory);

  /// @notice The COMP market borrow state for each market
  function compBorrowState(
    address
  ) external view returns (CompMarketState memory);

  /// @notice The COMP borrow index for each market for each supplier as of the last time they accrued COMP
  function compSupplierIndex(address, address) external view returns (uint);

  /// @notice The COMP borrow index for each market for each borrower as of the last time they accrued COMP
  function compBorrowerIndex(address, address) external view returns (uint);

  /// @notice The COMP accrued but not yet transferred to each user
  function compAccrued(address) external view returns (uint);

  /// @notice The rate at which comp is distributed to the corresponding borrow market (per block)
  function compBorrowSpeeds(address) external view returns (uint);

  /// @notice The rate at which comp is distributed to the corresponding supply market (per block)
  function compSupplySpeeds(address) external view returns (uint);

  function claimComp(address holder) external;

  function enterMarkets(
    address[] memory cTokens
  ) external returns (uint256[] memory);

  function _supportMarket(address) external returns (uint256);

  function borrowAllowed(address, address, uint) external returns (uint);

  function _setPriceOracle(address) external returns (uint);

  function _setCollateralFactor(address, uint) external returns (uint);

  function getAccountLiquidity(
    address account
  ) external view returns (uint, uint, uint);

  function getHypotheticalAccountLiquidity(
    address,
    address,
    uint,
    uint
  ) external view returns (uint, uint, uint);

  function liquidationIncentiveMantissa() external view returns (uint);

  function liquidateBorrowAllowed(
    address cTokenBorrowed,
    address cTokenCollateral,
    address liquidator,
    address borrower,
    uint repayAmount
  ) external returns (uint);

  function _setCloseFactor(uint) external returns (uint);

  function _setLiquidationIncentive(
    uint newLiquidationIncentiveMantissa
  ) external returns (uint);

  function _setBorrowPaused(address cToken, bool state) external returns (bool);

  function _become(address unitroller) external;

  function markets(address) external view returns (bool, uint);

  function admin() external view returns (address);

  function pendingAdmin() external view returns (address);

  function _setPendingAdmin(address) external returns (uint);

  function _acceptAdmin() external returns (uint);

  function closeFactorMantissa() external view returns (uint);

  function oracle() external view returns (address);

  function liquidateCalculateSeizeTokens(
    address cTokenBorrowed,
    address cTokenCollateral,
    uint repayAmount
  ) external view returns (uint, uint);

  function _setPauseGuardian(address) external returns (uint);

  function pauseGuardian() external view returns (address);

  function _setTransferPaused(bool) external returns (bool);

  function _setSeizePaused(bool) external returns (bool);

  function seizeAllowed(
    address oTokenCollateral,
    address oTokenBorrowed,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external returns (uint);

  function _setMintPaused(address oToken, bool state) external returns (bool);

  function mintAllowed(
    address oToken,
    address minter,
    uint mintAmount
  ) external returns (uint);
}
