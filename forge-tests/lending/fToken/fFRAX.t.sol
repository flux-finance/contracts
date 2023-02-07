pragma solidity 0.8.16;

import "forge-tests/lending/fToken/fToken.base.noCollateral.t.sol";

contract Test_fToken_fFRAX is Test_fTokenNonCollateral {
  function setUp() public override {
    super.setUp();
    _setfToken(address(fFRAX));

    // Deploy New Oracle, Frax is only supported with OndoPriceOracleV2
    setUp_V2_Oracle();

    // Set Comptroller Params for asset
    oComptroller._setPriceOracle(address(oracleV2));
  }

  function test_oracle_getUnderlyingPrice() public {
    uint256 result = oracleV2.getUnderlyingPrice(address(fFRAX));
    assertAlmostEqBps(1e18, result, 100);
  }

  function test_name() public {
    string memory name = fFRAX.name();
    assertEq(name, "Flux FRAX Token");
  }

  function test_symbol() public {
    string memory symbol = fFRAX.symbol();
    assertEq(symbol, "fFRAX");
  }
}
