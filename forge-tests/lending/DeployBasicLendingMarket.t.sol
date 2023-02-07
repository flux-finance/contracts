// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-tests/lending/helpers/interfaces/IUnitroller.sol";
import "forge-tests/lending/helpers/interfaces/ICompoundLens.sol";
import "contracts/lending/ondo/ondo-token/IOndo.sol";
import "contracts/external/openzeppelin/contracts/token/SafeERC20.sol";
import "forge-tests/lending/helpers/fTokenDeployment.t.sol";
import "forge-tests/common/constants.sol";
import "forge-tests/helpers/IKYCRegistry.sol";

// Governance stuff
import "forge-tests/lending/helpers/interfaces/IGovernorBravoHarness.sol";
import "forge-tests/lending/helpers/interfaces/IGovernanceBravoDelegator.sol";
import "forge-tests/lending/helpers/interfaces/IOndoOracle.sol";
import "forge-tests/lending/helpers/interfaces/ITimelock.sol";

contract BasicLendingMarket is fTokenDeploy {
  using SafeERC20 for IERC20;

  address constant guardian = address(0x9999990);
  address constant alice = address(0x9999991);
  address constant bob = address(0x9999992);
  address constant charlie = address(0x9999993);
  address constant registryAdmin = address(0x9999994);
  address constant managerAdmin = address(0x9999995);
  address constant pauser = address(0x9999996);
  address constant assetSender = address(0x9999997);
  address constant assetRecipient = 0xF67416a2C49f6A46FEe1c47681C5a3832cf8856c;
  address constant feeRecipient = address(0x9999999);

  IGovernorBravoDelegate governorProxied;
  address[] markets;
  ICompoundLens lens;

  function setUp() public virtual {
    // deployBasic_nonUpgradable_LendingMarket();
    deploy_upgradable_Comptroller_LendingMarket();
    deployGovernance_Harness();
    lens = ICompoundLens(deployCode("CompoundLens.sol:CompoundLens"));
  }

  function deploy_upgradable_Comptroller_LendingMarket() public {
    // Deploy the interest rate model
    deployIRmodel();

    // Deploy unitroller and comptroller implementation
    address unitroller = deployCode(
      "Unitroller.sol:Unitroller",
      abi.encode(address(this))
    );
    address implementation = deployCode(
      "Comptroller.sol:Comptroller",
      abi.encode(address(this))
    );

    IUnitroller(unitroller)._setPendingImplementation(implementation);
    IComptroller(implementation)._become(unitroller);
    address oComp = unitroller;
    oComptroller = IComptroller(oComp);
    vm.label(address(oComptroller), "Comptroller");

    // Deploy Oracle
    ondoOracle = IOndoOracle(deployCode("OndoPriceOracle.sol:OndoPriceOracle"));
    vm.label(address(ondoOracle), "OndoOracleV1");

    // Deploy fTokens
    deployfDai();
    deployfCash();
    deployfUsdc();
    deployfFrax();
    deployfLusd();
    deployfUsdt();

    // _addAddressToKYC(kycRequirementGroup, address(fCASH));
    _addAddressToKYC(kycRequirementGroup, guardian);
    _addAddressToKYC(kycRequirementGroup, bob);
    _addAddressToKYC(kycRequirementGroup, address(this));

    // Admin functions for comptroller contract

    // https://docs.compound.finance/v2/comptroller/#close-factor
    oComptroller._setCloseFactor(5e17);
    // https://docs.compound.finance/v2/comptroller/#liquidation-incentive
    oComptroller._setLiquidationIncentive(1.05e18);
    oComptroller._setPriceOracle(address(ondoOracle));
    // https://docs.compound.finance/v2/comptroller/#collateral-factor
    oComptroller._setCollateralFactor(address(fCASH), 92 * 1e16);
    oComptroller._setCollateralFactor(address(fUSDC), 85 * 1e16);
    oComptroller._setCollateralFactor(address(fDAI), 83 * 1e16);
    // Pause borrow for fCASH
    // oComptroller._setBorrowPaused(address(fCASH), true);

    // Add labels
    vm.label(alice, "alice");
    vm.label(bob, "bob");
    vm.label(charlie, "charlie");
  }

  function enterMarkets(
    address user,
    address marketToEnter,
    uint256 amount
  ) public {
    if (marketToEnter == address(fCASH)) {
      _addAddressToKYC(kycRequirementGroup, user);
      mockCash.mint(user, amount);
      vm.startPrank(user);
      mockCash.approve(address(fCASH), amount);
      fCASH.mint(amount);
      markets.push(address(fCASH));
      oComptroller.enterMarkets(markets);
      vm.stopPrank();
    } else if (marketToEnter == address(fDAI)) {
      vm.prank(DAI_WHALE);
      DAI.transfer(user, amount);
      vm.startPrank(user);
      DAI.approve(address(fDAI), amount);
      fDAI.mint(amount);
      markets.push(address(fDAI));
      oComptroller.enterMarkets(markets);
      vm.stopPrank();
    } else if (marketToEnter == address(fUSDC)) {
      vm.prank(USDC_WHALE);
      USDC.transfer(user, amount);
      vm.startPrank(user);
      USDC.approve(address(fUSDC), amount);
      fUSDC.mint(amount);
      markets.push(address(fUSDC));
      oComptroller.enterMarkets(markets);
      vm.stopPrank();
    } else if (marketToEnter == address(fFRAX)) {
      vm.prank(FRAX_WHALE);
      FRAX.transfer(user, amount);
      vm.startPrank(user);
      FRAX.approve(address(fFRAX), amount);
      fFRAX.mint(amount);
      markets.push(address(fFRAX));
      oComptroller.enterMarkets(markets);
      vm.stopPrank();
    } else if (marketToEnter == address(fLUSD)) {
      vm.prank(LUSD_WHALE);
      LUSD.transfer(user, amount);
      vm.startPrank(user);
      LUSD.approve(address(fLUSD), amount);
      fLUSD.mint(amount);
      markets.push(address(fLUSD));
      oComptroller.enterMarkets(markets);
      vm.stopPrank();
    } else if (marketToEnter == address(fUSDT)) {
      vm.prank(USDT_WHALE);
      USDT.safeTransfer(user, amount);
      vm.startPrank(user);
      USDT.safeApprove(address(fUSDT), amount);
      fUSDT.mint(amount);
      markets.push(address(fUSDT));
      oComptroller.enterMarkets(markets);
      vm.stopPrank();
    }
  }

  function deployGovernance_Harness() public {
    address delegate = deployCode(
      "GovernorBravoHarness.sol:GovernorBravoDelegateHarness"
    );
    address timelock = deployCode(
      "TimelockHarness.sol:TimelockHarness",
      abi.encode(address(this), 86400 * 2)
    );
    ITimelock time = ITimelock(timelock);
    address delegator = deployCode(
      "GovernanceBravoDelegator.sol:GovernorBravoDelegator",
      abi.encode(
        timelock, // timelock
        address(0xfAbA6f8e4a5E8Ab82F62fe7C39859FA577269BE3), // votingToken
        address(this), // Admin
        delegate, // impl
        17280, // voting period
        1, // voting delay
        100000000000000000000000 // proposal thre
      )
    );

    governorProxied = IGovernorBravoDelegate(delegator);
    assertEq(IGoveranceBravoDelegator(delegator).implementation(), delegate);
    assertEq(IGoveranceBravoDelegator(delegator).admin(), address(this));
    governorProxied._initiate();
    time.harnessSetAdmin(address(governorProxied));
  }

  function getSupplyRateCheck(
    uint256 util,
    uint256 borrowRate,
    uint256 reserveFactor
  ) public returns (uint256) {
    uint256 oneMinusReserve = 1e18 - reserveFactor;
    uint256 result = (util * ((borrowRate * oneMinusReserve) / 1e18)) / 1e18;
    return result;
  }

  function seedUserDAI(address to, uint256 amount) public {
    vm.prank(DAI_WHALE);
    DAI.transfer(to, amount);
  }

  function seedUserUSDC(address to, uint256 amount) public {
    vm.prank(USDC_WHALE);
    USDC.transfer(to, amount);
  }

  // Whale Util
  function getWhale(address fToken) public returns (address) {
    if (fToken == address(fDAI)) {
      return DAI_WHALE;
    } else if (fToken == address(fUSDC)) {
      return USDC_WHALE;
    } else if (fToken == address(fFRAX)) {
      return FRAX_WHALE;
    } else if (fToken == address(fLUSD)) {
      return LUSD_WHALE;
    } else if (fToken == address(fUSDT)) {
      return USDT_WHALE;
    }
  }

  // Seed Lending Pool Utils
  function seedLendingPool(address fToken) public {
    if (fToken == address(fDAI)) {
      seedDAILendingPool();
    } else if (fToken == address(fUSDC)) {
      seedUSDCLendingPool();
    } else if (fToken == address(fFRAX)) {
      seedFRAXLendingPool();
    } else if (fToken == address(fLUSD)) {
      seedLUSDLendingPool();
    } else if (fToken == address(fUSDT)) {
      seedUSDTLendingPool();
    }
  }

  function seedUSDTLendingPool() public {
    vm.startPrank(USDT_WHALE);
    USDT.safeApprove(address(fUSDT), 10000e6);
    fUSDT.mint(10000e6);
    vm.stopPrank();
  }

  function seedDAILendingPool() public {
    vm.startPrank(DAI_WHALE);
    DAI.approve(address(fDAI), 10000e18);
    fDAI.mint(10000e18);
    vm.stopPrank();
  }

  function seedUSDCLendingPool() public {
    vm.startPrank(USDC_WHALE);
    USDC.approve(address(fUSDC), 10000e6);
    fUSDC.mint(10000e6);
    vm.stopPrank();
  }

  function seedFRAXLendingPool() public {
    vm.startPrank(FRAX_WHALE);
    FRAX.approve(address(fFRAX), 10000e18);
    fFRAX.mint(10000e18);
    vm.stopPrank();
  }

  function seedLUSDLendingPool() public {
    vm.startPrank(LUSD_WHALE);
    LUSD.approve(address(fLUSD), 10000e18);
    fLUSD.mint(10000e18);
    vm.stopPrank();
  }

  // Lending Market Utils
  function getExpectedUtilizationRate(
    uint256 borrows,
    uint256 cash,
    uint256 reserves
  ) public pure returns (uint256) {
    return (borrows * 1e18) / (cash + borrows - reserves);
  }

  function getExpectedBorrowRate(
    uint256 util,
    uint256 kink,
    uint256 blockMultiplier,
    uint256 jumpBlockMultiplier,
    uint256 baseRatePerBlock
  ) public pure returns (uint256 result) {
    if (util <= kink) {
      result = ((util * blockMultiplier) / 1e18) + baseRatePerBlock;
    } else if (util > kink) {
      result =
        (((util - kink) * jumpBlockMultiplier) / 1e18) +
        ((util * blockMultiplier) / 1e18) +
        baseRatePerBlock;
    }
  }

  function getBorrowedAmount(
    uint256 initial,
    uint256 rate,
    uint256 blocksPassed
  ) public pure returns (uint256) {
    return initial + (((rate * blocksPassed) * initial) / 1e18);
  }

  function getSupplyAmount(
    uint256 initial,
    uint256 rate,
    uint256 blocksPassed
  ) public pure returns (uint256) {
    return initial + ((initial * (rate * blocksPassed)) / 1e18);
  }

  function _expectFail(
    ComptrollerErrorReporter.Error err,
    ComptrollerErrorReporter.FailureInfo info
  ) internal {
    vm.expectEmit(true, true, true, true);
    emit Failure(uint256(err), uint256(info), 0);
  }

  function _addAddressToKYC(uint256 level, address account) internal {
    address[] memory addressesToKYC = new address[](1);
    addressesToKYC[0] = account;
    vm.prank(0xAEd4caF2E535D964165B4392342F71bac77e8367);
    IKYCRegistry(registry).addKYCAddresses(level, addressesToKYC);
  }

  function _addAddressToSanctionsList(address sanctionedAccount) internal {
    address[] memory newSanctions = new address[](1);
    newSanctions[0] = sanctionedAccount;
    vm.prank(SANCTIONS_ORACLE.owner());
    SANCTIONS_ORACLE.addToSanctionsList(newSanctions);
  }

  function _removeAddressFromKYC(uint256 level, address account) internal {
    address[] memory addressesToRemoveKYC = new address[](1);
    addressesToRemoveKYC[0] = account;
    vm.prank(0xAEd4caF2E535D964165B4392342F71bac77e8367);
    IKYCRegistry(registry).removeKYCAddresses(level, addressesToRemoveKYC);
  }

  event Failure(uint error, uint info, uint detail);
}
