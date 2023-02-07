pragma solidity 0.8.16;

import "forge-tests/lending/Production/Proposals/baseDao.sol";
import "forge-tests/lending/helpers/interfaces/IUnitroller.sol";
import "contracts/lending/GovernerAlpha.sol";
import "forge-tests/lending/helpers/fTokenDeployment.t.sol";

contract Test_Prod_DAO_Genesis is BaseDAO, fTokenDeploy {
  // Testing from Block: 16486337
  CashKYCSenderReceiver ousg;
  uint256 proposal1Id;
  uint256 proposal2Id;
  address burnAddress = address(0x000000000000000000000000000000000000dEaD);

  // List of Actions:
  /**
    1. Accept ownership of Comptroller
    2. Set Pause Guardian to Flux MSig
    3. Set Close Factor
    4. Set Liquidation Incentive
    5. Set Price Oracle
    6. Support fOUSG Market
    7. Set Collateral Factor for fOUSG
    8. Set Borrow Paused for fOUSG
    9. Support USDC Market
    10. Set Collateral Factor for USDC
    11. Approve USDC to fUSDC
    12. Mint fUSDC
    13. Burn fUSDC
    14. Support DAI Market
    15. Set Collateral Factor for DAI
    16. Approve DAI to fDAI
    17. Mint fDAI
    18. Burn fDAI
  */
  function setUp() public override {
    super.setUp();
    kycRequirementGroup = 1;

    // Get KYCRegistry, OUSG
    registry = KYCRegistry(0x7cE91291846502D50D635163135B2d40a602dc70);
    ousg = CashKYCSenderReceiver(0x1B19C19393e2d034D8Ff31ff34c81252FcBbee92);

    // Deploy IR Model and Transfer Ownership to MSig
    deployIRmodel();
    interestRateModel.transferOwnership(fluxMSig);
    vm.prank(fluxMSig);
    interestRateModel.acceptOwnership();

    // Deploy unitroller and comptroller implementation
    address unitroller = deployCode(
      "Unitroller.sol:Unitroller",
      abi.encode(address(fluxMSig))
    );
    address implementation = deployCode(
      "Comptroller.sol:Comptroller",
      abi.encode(address(fluxMSig))
    );

    vm.startPrank(fluxMSig);
    IUnitroller(unitroller)._setPendingImplementation(implementation);
    IComptroller(implementation)._become(unitroller);
    vm.stopPrank();
    address oComp = unitroller;
    oComptroller = IComptroller(oComp);
    vm.label(address(oComptroller), "Comptroller");

    // Deploy Oracle and transfer ownership to MSig
    ondoOracle = IOndoOracle(deployCode("OndoPriceOracle.sol:OndoPriceOracle"));
    ondoOracle.transferOwnership(fluxMSig);
    vm.prank(fluxMSig);
    ondoOracle.acceptOwnership();

    /*//////////////////////////////////////////////////////////////
                                Deploy fOUSG
    //////////////////////////////////////////////////////////////*/

    address fOUSGImplementation = deployCode("CCashDelegate.sol:CCashDelegate");
    address fOUSGDelegate = deployCode(
      "cErc20ModifiedDelegator.sol:CErc20DelegatorKYC",
      abi.encode(
        address(ousg),
        address(oComptroller),
        address(interestRateModel),
        200000000000000000000000000,
        "Flux OUSG Token",
        "fOUSG",
        8,
        address(timelock),
        fOUSGImplementation,
        address(registry),
        kycRequirementGroup,
        implementationData
      )
    );
    fCASH = ICToken(fOUSGDelegate);
    vm.label(address(fCASH), "fCASH");

    // Set Oracle Price
    vm.prank(fluxMSig);
    ondoOracle.setPrice(address(fCASH), 100e18);

    /*//////////////////////////////////////////////////////////////
                              Deploy fUSDC
    //////////////////////////////////////////////////////////////*/

    address fUsdcImplementation = deployCode(
      "CTokenDelegate.sol:CTokenDelegate"
    );
    address fUsdcDelegate = deployCode(
      "cErc20ModifiedDelegator.sol:CErc20DelegatorKYC",
      abi.encode(
        address(USDC),
        address(oComptroller),
        address(interestRateModel),
        200000000000000,
        "Flux USDC Token",
        "fUSDC",
        8,
        address(timelock),
        fUsdcImplementation,
        address(registry),
        kycRequirementGroup,
        implementationData
      )
    );
    fUSDC = ICToken(fUsdcDelegate);

    // Label
    vm.label(address(fUSDC), "fUSDC");
    vm.label(address(USDC), "USDC");
    vm.label(USDC_WHALE, "USDC_WHALE");

    // Oracle fUSDC -> cUSDC
    vm.prank(fluxMSig);
    ondoOracle.setFTokenToCToken(
      address(fUSDC),
      address(0x39AA39c021dfbaE8faC545936693aC917d5E7563)
    );

    /*//////////////////////////////////////////////////////////////
                              Deploy fDAI
    //////////////////////////////////////////////////////////////*/

    address fDaiImplementation = deployCode(
      "CTokenDelegate.sol:CTokenDelegate"
    );
    address fDaiDelegate = deployCode(
      "cErc20ModifiedDelegator.sol:CErc20DelegatorKYC",
      abi.encode(
        address(DAI),
        address(oComptroller),
        address(interestRateModel),
        200000000000000000000000000,
        "Flux DAI Token",
        "fDAI",
        8,
        address(timelock),
        fDaiImplementation,
        address(registry),
        kycRequirementGroup,
        implementationData
      )
    );
    fDAI = ICToken(fDaiDelegate);

    // Label
    vm.label(address(fDAI), "fDAI");
    vm.label(address(DAI), "DAI");
    vm.label(DAI_WHALE, "DAI_WHALE");

    // Oracle fDAI -> cDAI
    vm.prank(fluxMSig);
    ondoOracle.setFTokenToCToken(address(fDAI), cDAI);

    // Transfer Ownership of Comptroller to DAO
    vm.prank(fluxMSig);
    IUnitroller(address(oComptroller))._setPendingAdmin(address(timelock));
    // Seed Timelock with USDC & DAI to mint fTokens
    vm.prank(USDC_WHALE);
    USDC.transfer(address(timelock), 10e6);
    vm.prank(DAI_WHALE);
    DAI.transfer(address(timelock), 10e18);
  }

  function test_genesis_queueProposal1() public {
    // 1. Accept Ownership of Comptroller
    targets.push(address(oComptroller));
    values.push(0);
    signatures.push("_acceptAdmin()");
    calldatas.push(abi.encode());

    // 2. Set Pause Guardian to Flux MSig
    targets.push(address(oComptroller));
    values.push(0);
    signatures.push("_setPauseGuardian(address)");
    calldatas.push(abi.encode(address(fluxMSig)));

    // 3. Set Close Factor
    targets.push(address(oComptroller));
    values.push(0);
    signatures.push("_setCloseFactor(uint256)");
    calldatas.push(abi.encode(5e17));

    // 4. Set Liquidation Incentive
    targets.push(address(oComptroller));
    values.push(0);
    signatures.push("_setLiquidationIncentive(uint256)");
    calldatas.push(abi.encode(1.05e18));

    // 5. Set Price Oracle
    targets.push(address(oComptroller));
    values.push(0);
    signatures.push("_setPriceOracle(address)");
    calldatas.push(abi.encode(address(ondoOracle)));

    // 6. Support OUSG Market
    targets.push(address(oComptroller));
    values.push(0);
    signatures.push("_supportMarket(address)");
    calldatas.push(abi.encode(address(fCASH)));

    // 7. Set Collateral Factor for OUSG
    targets.push(address(oComptroller));
    values.push(0);
    signatures.push("_setCollateralFactor(address,uint256)");
    calldatas.push(abi.encode(address(fCASH), 92 * 1e16));

    //8. Pause Borrow for OUSG
    targets.push(address(oComptroller));
    values.push(0);
    signatures.push("_setBorrowPaused(address,bool)");
    calldatas.push(abi.encode(address(fCASH), true));

    // Propose
    vm.prank(fluxMSig);
    proposal1Id = dao.propose(
      targets,
      values,
      signatures,
      calldatas,
      "Initialize Comptroller & OUSG Market"
    );

    delete targets;
    delete values;
    delete signatures;
    delete calldatas;
  }

  function test_genesis_queueProposal2() public {
    test_genesis_queueProposal1();

    //9. Support USDC Market
    targets.push(address(oComptroller));
    values.push(0);
    signatures.push("_supportMarket(address)");
    calldatas.push(abi.encode(address(fUSDC)));

    //10. Set Collateral Factor for USDC
    targets.push(address(oComptroller));
    values.push(0);
    signatures.push("_setCollateralFactor(address,uint256)");
    calldatas.push(abi.encode(address(fUSDC), 85 * 1e16));

    //11. Approve USDC
    targets.push(address(USDC));
    values.push(0);
    signatures.push("approve(address,uint256)");
    calldatas.push(abi.encode(address(fUSDC), 10e6));

    //12. Mint fUSDC
    targets.push(address(fUSDC));
    values.push(0);
    signatures.push("mint(uint256)");
    calldatas.push(abi.encode(10e6));

    //13. Burn fUSDC
    targets.push(address(fUSDC));
    values.push(0);
    signatures.push("transfer(address,uint256)");
    calldatas.push(abi.encode(burnAddress, 500e8));

    //14. Support DAI Market
    targets.push(address(oComptroller));
    values.push(0);
    signatures.push("_supportMarket(address)");
    calldatas.push(abi.encode(address(fDAI)));

    //15. Set Collateral Factor for DAI
    targets.push(address(oComptroller));
    values.push(0);
    signatures.push("_setCollateralFactor(address,uint256)");
    calldatas.push(abi.encode(address(fDAI), 83 * 1e16));

    //16. Approve DAI
    targets.push(address(DAI));
    values.push(0);
    signatures.push("approve(address,uint256)");
    calldatas.push(abi.encode(address(fDAI), 10e18));

    //17. Mint fDAI
    targets.push(address(fDAI));
    values.push(0);
    signatures.push("mint(uint256)");
    calldatas.push(abi.encode(10e18));

    //18. Burn fDAI
    targets.push(address(fDAI));
    values.push(0);
    signatures.push("transfer(address,uint256)");
    calldatas.push(abi.encode(burnAddress, 500e8));

    vm.prank(fluxTeam);
    proposal2Id = dao.propose(
      targets,
      values,
      signatures,
      calldatas,
      "Initialize Comptroller & OUSG Market"
    );
  }

  function test_genesis_vote() public {
    test_genesis_queueProposal2();
    vm.roll(block.number + 2);

    // Vote for Proposal1
    vm.prank(fluxMSig);
    dao.castVote(proposal1Id, 1);

    // Vote for Proposal2
    vm.prank(fluxTeam);
    dao.castVote(proposal2Id, 1);

    // Roll block past voting period and queue
    vm.roll(block.number + dao.votingPeriod() + 10);
    dao.queue(proposal1Id);
    dao.queue(proposal2Id);
  }

  function test_genesis_execute() public {
    test_genesis_vote();

    // Execute
    vm.warp(block.timestamp + timelock.delay() * 2);
    dao.execute(proposal1Id);
    dao.execute(proposal2Id);

    // 1. Assert that timelock owns comptroller
    assertEq(oComptroller.admin(), address(timelock));

    // 2. Assert that fluxMSig is pause guardian
    assertEq(oComptroller.pauseGuardian(), address(fluxMSig));

    // 3. Assert closeFactor
    assertEq(oComptroller.closeFactorMantissa(), 5e17);

    // 4. Assert liquidationIncentive
    assertEq(oComptroller.liquidationIncentiveMantissa(), 1.05e18);

    // 5. Assert price oracle
    assertEq(oComptroller.oracle(), address(ondoOracle));

    // 6. Assert that OUSG is supported
    (bool isListed, uint collateralFactorMantissa) = oComptroller.markets(
      address(fCASH)
    );
    assertEq(isListed, true);

    // 7. Assert collateral factor
    assertEq(collateralFactorMantissa, 92 * 1e16);

    // 8. Assert borrow paused
    assertEq(oComptroller.borrowGuardianPaused(address(fCASH)), true);

    // 9. Assert that USDC is supported
    (isListed, collateralFactorMantissa) = oComptroller.markets(address(fUSDC));
    assertEq(isListed, true);

    // 10. Assert fUSDC collateral factor
    assertEq(collateralFactorMantissa, 85 * 1e16);

    // 11-13 Assert fUSDC Balance
    assertEq(fUSDC.balanceOf(burnAddress), 500e8);

    // 14. Assert that DAI is supported
    (isListed, collateralFactorMantissa) = oComptroller.markets(address(fDAI));
    assertEq(isListed, true);

    // 15. Assert fDAI collateral factor
    assertEq(collateralFactorMantissa, 83 * 1e16);

    // 16-18 Assert fDAI Balance
    assertEq(fDAI.balanceOf(burnAddress), 500e8);
  }
}
