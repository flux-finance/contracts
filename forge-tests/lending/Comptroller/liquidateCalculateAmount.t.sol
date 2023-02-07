// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

/*//////////////////////////////////////////////////////////////
  Compound Tests: tests/Comptroller/liquidateCalculateAmountSeizeTest.js
//////////////////////////////////////////////////////////////*/

contract Test_Liquidate_Seize_Token_Amount is BasicLendingMarket {
  function test_liquidateCalculateAmountSeize_fail_price_zero() public {
    IOndoOracle mockOracle = IOndoOracle(
      deployCode(
        "MockPriceOracle.sol:MockPriceOracle",
        abi.encode(address(fCASH))
      )
    );
    mockOracle.setPrice(address(fCASH), 0);
    mockOracle.setPrice(address(fDAI), 1000027000000000000);
    oComptroller._setPriceOracle(address(mockOracle));

    (uint256 err, uint256 seizeAmt) = oComptroller
      .liquidateCalculateSeizeTokens(address(fDAI), address(fCASH), 0);
    assertEq(err, 13); // Assert that the error given is PRICE_ERROR
    assertEq(seizeAmt, 0); // Assert that the seizeAmt is 0
  }

  function test_liquidateCalculateAmountSeize_fail_repay_overflow() public {
    vm.expectRevert(bytes("multiplication overflow"));
    oComptroller.liquidateCalculateSeizeTokens(
      address(fDAI),
      address(fUSDC),
      type(uint256).max
    );
  }

  function test_liquidateCalculateAmountSeize_fail_price_overflow() public {
    ondoOracle.setPrice(address(fUSDC), type(uint256).max);
    vm.expectRevert(bytes("multiplication overflow"));
    oComptroller.liquidateCalculateSeizeTokens(
      address(fDAI),
      address(fUSDC),
      1e18
    );
  }
}
