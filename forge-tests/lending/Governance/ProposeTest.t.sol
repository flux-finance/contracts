pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";
import "contracts/lending/ondo/ondo-token/IOndo.sol";

/*//////////////////////////////////////////////////////////////
  Compound Tests: tests/Governance/GovernorBravo/ProposeTest.js
//////////////////////////////////////////////////////////////*/

contract Test_Lending_Market_Governance is BasicLendingMarket {
  address[] targets;
  uint[] values;
  string[] signatures;
  bytes[] calldatas;
  string[] description;

  uint256 blockProposed;

  function test_createProposal() public {
    createSimpleProposal();
  }

  function createSimpleProposal() public {
    targets.push(address(0));
    values.push(0);
    signatures.push("getBalanceOf(address)");
    calldatas.push(abi.encode(signatures[0], targets[0]));
    vm.startPrank(ONDO_WHALE);
    ONDO_TOKEN.delegate(address(this));
    vm.stopPrank();
    vm.roll(block.number + 10);

    governorProxied.propose(
      targets,
      values,
      signatures,
      calldatas,
      "do nothing"
    );
    blockProposed = block.number;
  }

  function test_proposer_is_set_to_sender() public {
    createSimpleProposal();
    address result = governorProxied.getProposer(2);
    assertEq(result, address(this));
  }

  function test_StartBlock_is_current_plus_vote_delay() public {
    createSimpleProposal();
    uint256 startBlock = governorProxied.getProposalStartBlock(2);
    assertEq(startBlock, blockProposed + 1);
  }

  function test_EndBlock_is_current_plus_delay_plus_voting_period() public {
    createSimpleProposal();
    uint256 endBlock = governorProxied.getProposalEndBlock(2);
    console.log(endBlock);
    assertEq(endBlock, blockProposed + 1 + 17280);
  }

  function test_executed_proposal_flags_initialized_to_false() public {
    createSimpleProposal();
    bool executedFlag = governorProxied.getProposalExecuteFlag(2);
    assertFalse(executedFlag);
  }

  function test_canceled_proposal_flags_initialized_to_false() public {
    createSimpleProposal();
    bool canceledFlag = governorProxied.getProposalCanceledFlag(2);
    assertFalse(canceledFlag);
  }

  function test_eta_initialized_to_zero() public {
    createSimpleProposal();
    uint256 proposalEta = governorProxied.getProposalEta(2);
    assertEq(proposalEta, 0);
  }
}
