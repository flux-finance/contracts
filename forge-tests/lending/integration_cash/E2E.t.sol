pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

contract Test_Lending_Market_E2E is BasicLendingMarket {
  function testSeed() public {
    seedUserDAI(charlie, 100000e18);
    console.log(DAI.balanceOf(charlie));
  }

  function test_e2e_request_mint_cash() public {
    _addAddressToKYC(kycRequirementGroup, charlie);
    seedUserUSDC(charlie, 900e6);

    uint256 prevBal = USDC.balanceOf(charlie);

    vm.startPrank(charlie);
    USDC.approve(address(cashManager), 900e6);
    cashManager.requestMint(900e6);

    uint256 currentBal = USDC.balanceOf(charlie);
    assertEq(prevBal - currentBal, 900e6);
    vm.stopPrank();
  }

  function test_e2e_set_rate() public {
    vm.warp(block.timestamp + 1 days); // E0 -> E1
    vm.prank(managerAdmin);
    cashManager.grantRole(keccak256("SETTER_ADMIN"), address(this));
    _addAddressToKYC(kycRequirementGroup, address(cashManager));
    vm.prank(guardian);
    cashKYCSenderReceiverProxied.grantRole(
      keccak256("MINTER_ROLE"),
      address(cashManager)
    );
    cashManager.setMintExchangeRate(100e6, 0);
  }

  function test_e2e_claim() public {
    test_e2e_request_mint_cash();
    test_e2e_set_rate();

    vm.prank(charlie);
    cashManager.claimMint(charlie, 0);

    uint256 cashGiven = cashKYCSenderReceiverProxied.balanceOf(charlie);
    assertEq(cashGiven, 9e18);
  }

  function test_e2e_deposit_cash_to_lending_market() public {
    test_e2e_claim();

    vm.startPrank(charlie);
    cashKYCSenderReceiverProxied.approve(address(fCASH), 9e18);
    fCASH.mint(9e18);
    vm.stopPrank();
    assertEq(fCASH.balanceOfUnderlying(charlie), 9e18);
  }

  function test_e2e_borrow_dai_against_cash() public {
    test_e2e_deposit_cash_to_lending_market();
    seedDAILendingPool();
    vm.startPrank(charlie);
    markets.push(address(fCASH));
    oComptroller.enterMarkets(markets);

    fDAI.borrow(50e18);
    vm.stopPrank();
    uint256 daiBorrowed = DAI.balanceOf(charlie);
    assertEq(daiBorrowed, 50e18);
  }

  function test_e2e_can_borrow_up_to_75_tvl() public {
    test_e2e_deposit_cash_to_lending_market();
    seedDAILendingPool();
    vm.startPrank(charlie);
    markets.push(address(fCASH));
    oComptroller.enterMarkets(markets);
    fDAI.borrow(675e18);
    uint256 daiBorrowed = DAI.balanceOf(charlie);
    assertEq(daiBorrowed, 675e18);
  }
}
