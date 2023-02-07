pragma solidity >=0.5.0;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

contract TestRewards is BasicLendingMarket {
  function test_rewards_initial() public {
    assertEq(oComptroller.compRate(), 0);
    assertEq(oComptroller.compSpeeds(address(fCASH)), 0); //deprecated, but still checking
    assertEq(oComptroller.compSpeeds(address(fDAI)), 0); //deprecated, but still checking
    assertEq(oComptroller.compBorrowSpeeds(address(fCASH)), 0);
    assertEq(oComptroller.compBorrowSpeeds(address(fDAI)), 0);
    assertEq(oComptroller.compSupplySpeeds(address(fCASH)), 0);
    assertEq(oComptroller.compSupplySpeeds(address(fDAI)), 0);
    assertEq(oComptroller.compSupplyState(address(fCASH)).index, 1e36);
    assertEq(oComptroller.compSupplyState(address(fDAI)).index, 1e36);
    assertEq(oComptroller.compBorrowState(address(fCASH)).index, 1e36);
    assertEq(oComptroller.compBorrowState(address(fDAI)).index, 1e36);
    // Supply/borrow states for blocks should be the same -> whenever they were initialized
    assertEq(
      oComptroller.compSupplyState(address(fCASH)).block,
      oComptroller.compBorrowState(address(fCASH)).block
    );
    assertEq(
      oComptroller.compSupplyState(address(fDAI)).block,
      oComptroller.compBorrowState(address(fDAI)).block
    );
  }

  function test_rewards_noAccrual() public {
    // Do all actions that will update borrow/supply index & distribute borrow/supply comp

    // Get last supply/borrow block numbers for checks later on
    uint256 supplyBlockfDAI = oComptroller.compSupplyState(address(fDAI)).block;
    uint256 borrowBlockfDAI = oComptroller.compBorrowState(address(fDAI)).block;
    uint256 supplyBlockfCASH = oComptroller
      .compSupplyState(address(fCASH))
      .block;
    uint256 borrowBlockfCASH = oComptroller
      .compBorrowState(address(fCASH))
      .block;

    // Mint & Transfer
    enterMarkets(alice, address(fCASH), 1e18);
    enterMarkets(charlie, address(fDAI), 1000e18);
    vm.prank(charlie);
    fDAI.transfer(bob, 100e8);

    // Borrow
    vm.prank(alice);
    fDAI.borrow(75e18);

    // Liquidate after becoming underwater
    vm.roll(block.number + 1e9);
    vm.prank(DAI_WHALE);
    DAI.transfer(address(this), 30e18);
    DAI.approve(address(fDAI), 30e18);
    fDAI.liquidateBorrow(alice, 30e18, CTokenInterface(address(fCASH)));

    // Claim Comp
    oComptroller.claimComp(alice);
    oComptroller.claimComp(bob);
    oComptroller.claimComp(charlie);

    // Redeem
    vm.prank(bob);
    fDAI.redeem(100e8);

    // State change checks
    assertGt(
      oComptroller.compSupplyState(address(fDAI)).block,
      supplyBlockfDAI
    );
    assertGt(
      oComptroller.compBorrowState(address(fDAI)).block,
      borrowBlockfDAI
    );
    assertGt(
      oComptroller.compSupplyState(address(fCASH)).block,
      supplyBlockfCASH
    );
    assertGt(
      oComptroller.compBorrowState(address(fCASH)).block,
      borrowBlockfCASH
    );
    test_rewards_initial();
  }

  function test_rewards_accrueSupply() public {
    _seedComptrollerWithOndo(1_000_000e18); //1M Ondo
    _setSupplySpeed(address(fDAI), 1e17); // 0.1 Ondo/Block == 715 Ondo/DAY
    enterMarkets(alice, address(fDAI), 1000e18);
    vm.roll(block.number + 10000);
    oComptroller.claimComp(alice);
    assertEq(ONDO_TOKEN.balanceOf(alice), 10000 * 1e17);
    // assertGt(ONDO_TOKEN.balanceOf(alice), 0);
  }

  function test_rewards_accrueBorrow() public {
    _seedComptrollerWithOndo(1_000_000e18); //1M Ondo
    _setBorrowSpeed(address(fDAI), 1e17); // 0.1 Ondo/Block == 715 Ondo/DAY
    enterMarkets(alice, address(fCASH), 100e18);
    seedDAILendingPool();
    vm.prank(alice);
    fDAI.borrow(50e18);
    vm.roll(block.number + 10000);
    oComptroller.claimComp(alice);
    assertEq(ONDO_TOKEN.balanceOf(alice), 10000 * 1e17);
  }

  function test_rewards_accrue_supplyBorrow() public {
    _seedComptrollerWithOndo(1_000_000e18); //1M Ondo
    // Supply: 0.1 Ondo/Block == 715 Ondo/DAY
    // Borrow: 1 Ondo/Block == 7150 Ondo/DAY
    _setSupplyAndBorrowSpeed(address(fDAI), 1e17, 1e18);
    enterMarkets(alice, address(fDAI), 1000e18);
    enterMarkets(charlie, address(fCASH), 100e18);
    vm.prank(charlie);
    fDAI.borrow(50e18);
    vm.roll(block.number + 10000);
    oComptroller.claimComp(alice);
    oComptroller.claimComp(charlie);
    assertEq(ONDO_TOKEN.balanceOf(alice), 10000 * 1e17);
    assertEq(ONDO_TOKEN.balanceOf(charlie), 10000 * 1e18);
  }

  function test_rewards_accrue_NoOndo() public {
    // Set speeds + supply + borrow
    _setSupplyAndBorrowSpeed(address(fDAI), 1e17, 1e18);
    enterMarkets(alice, address(fDAI), 1000e18);
    enterMarkets(charlie, address(fCASH), 100e18);
    vm.prank(charlie);
    fDAI.borrow(50e18);
    vm.roll(block.number + 10000);
    oComptroller.claimComp(alice);
    assertEq(ONDO_TOKEN.balanceOf(alice), 0);

    // Seed and claim
    _seedComptrollerWithOndo(1_000_000e18); //1M Ondo
    oComptroller.claimComp(alice);
    assertEq(ONDO_TOKEN.balanceOf(alice), 10000 * 1e17);
  }

  function _seedComptrollerWithOndo(uint256 amount) internal {
    vm.startPrank(ONDO_WHALE);
    ONDO_TOKEN.grantRole(keccak256("TRANSFER_ROLE"), address(oComptroller));
    ONDO_TOKEN.transfer(address(oComptroller), amount);
    vm.stopPrank();
  }

  function _setSupplySpeed(address market, uint256 speed) internal {
    address[] memory markets = new address[](1);
    markets[0] = market;
    uint256[] memory supplySpeeds = new uint256[](1);
    supplySpeeds[0] = speed;
    uint256[] memory borrowSpeeds = new uint256[](1);
    borrowSpeeds[0] = 0;
    oComptroller._setCompSpeeds(markets, supplySpeeds, borrowSpeeds);
  }

  function _setBorrowSpeed(address market, uint256 speed) internal {
    address[] memory markets = new address[](1);
    markets[0] = market;
    uint256[] memory supplySpeeds = new uint256[](1);
    supplySpeeds[0] = 0;
    uint256[] memory borrowSpeeds = new uint256[](1);
    borrowSpeeds[0] = speed;
    oComptroller._setCompSpeeds(markets, supplySpeeds, borrowSpeeds);
  }

  function _setSupplyAndBorrowSpeed(
    address market,
    uint256 supplySpeed,
    uint256 borrowSpeed
  ) internal {
    address[] memory markets = new address[](1);
    markets[0] = market;
    uint256[] memory supplySpeeds = new uint256[](1);
    supplySpeeds[0] = supplySpeed;
    uint256[] memory borrowSpeeds = new uint256[](1);
    borrowSpeeds[0] = borrowSpeed;
    oComptroller._setCompSpeeds(markets, supplySpeeds, borrowSpeeds);
  }
}
