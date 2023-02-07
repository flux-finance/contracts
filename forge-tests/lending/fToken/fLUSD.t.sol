pragma solidity 0.8.16;

import "forge-tests/lending/fToken/fToken.base.noCollateral.t.sol";

contract Test_fToken_fLUSD is Test_fTokenNonCollateral {
  function setUp() public override {
    super.setUp();
    _setfToken(address(fLUSD));

    // Deploy New Oracle, LUSD is only supported with OndoPriceOracleV2
    setUp_V2_Oracle();

    // Set Comptroller params for asset
    oComptroller._setPriceOracle(address(oracleV2));
    // @ block 15958078 lUSD has price > peg
    oracleV2.setPriceCap(address(fLUSD), 1e18);
  }

  function test_oracle() public {
    // @ block 15958078 lUSD has price > peg
    uint256 result = oracleV2.getUnderlyingPrice(address(fLUSD));
    assertEq(result, 1e18);
  }

  function test_name() public {
    string memory name = fLUSD.name();
    assertEq(name, "Flux LUSD Token");
  }

  function test_symbol() public {
    string memory symbol = fLUSD.symbol();
    assertEq(symbol, "fLUSD");
  }
}
