pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "contracts/lending/compound/governance/GovernorBravoDelegate.sol";

contract GovernorBravoDelegateHarness is GovernorBravoDelegate {
  // @notice Harness initiate the GovenorBravo contract
  // @dev This function bypasses the need to initiate the GovernorBravo contract from an existing GovernorAlpha for testing.
  // Actual use will only use the _initiate(address) function
  function _initiate() public {
    proposalCount = 1;
    initialProposalId = 1;
  }

  function initialize(
    address timelock_,
    address comp_,
    uint votingPeriod_,
    uint votingDelay_,
    uint proposalThreshold_
  ) public {
    require(msg.sender == admin, "GovernorBravo::initialize: admin only");
    require(
      address(timelock) == address(0),
      "GovernorBravo::initialize: can only initialize once"
    );

    timelock = TimelockInterface(timelock_);
    comp = CompInterface(comp_);
    votingPeriod = votingPeriod_;
    votingDelay = votingDelay_;
    proposalThreshold = proposalThreshold_;
  }

  function getForVotes(uint proposalId) external view returns (uint) {
    Proposal memory proposal = proposals[proposalId];
    return proposal.forVotes;
  }

  function getConVotes(uint proposalId) external view returns (uint) {
    Proposal memory proposal = proposals[proposalId];
    return proposal.againstVotes;
  }

  function getProposer(uint proposalId) external view returns (address) {
    Proposal memory proposal = proposals[proposalId];
    return proposal.proposer;
  }

  function getProposalStartBlock(uint proposalId) external view returns (uint) {
    Proposal memory proposal = proposals[proposalId];
    return proposal.startBlock;
  }

  function getProposalEndBlock(uint proposalId) external view returns (uint) {
    Proposal memory proposal = proposals[proposalId];
    return proposal.endBlock;
  }

  function getProposalExecuteFlag(
    uint proposalId
  ) external view returns (bool) {
    Proposal memory proposal = proposals[proposalId];
    return proposal.executed;
  }

  function getProposalCanceledFlag(
    uint proposalId
  ) external view returns (bool) {
    Proposal memory proposal = proposals[proposalId];
    return proposal.canceled;
  }

  function getProposalEta(uint proposalId) external view returns (uint) {
    Proposal memory proposal = proposals[proposalId];
    return proposal.eta;
  }
}
