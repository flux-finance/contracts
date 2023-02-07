pragma solidity 0.8.16;

import "forge-tests/lending/Production/Proposals/baseDao.sol";
import "forge-tests/lending/helpers/interfaces/IUnitroller.sol";
import "contracts/lending/GovernerAlpha.sol";
import "forge-tests/lending/helpers/fTokenDeployment.t.sol";

contract Test_Prod_DAO_GenesisExecution is BaseDAO, fTokenDeploy {
  // Testing from Block: 16522210
  uint256 proposal1Id = 2;
  uint256 proposal2Id = 3;

  function test_proposal_vote() public {
    vm.startPrank(fluxMSig);
    dao.castVote(proposal1Id, 1);
    dao.castVote(proposal2Id, 1);
    vm.stopPrank();
  }

  function test_execution() public {
    // Vote and roll
    test_proposal_vote();
    vm.roll(block.number + dao.votingPeriod() + 100);

    // Queue
    vm.startPrank(fluxTeam);
    dao.queue(proposal1Id);
    dao.queue(proposal2Id);
    vm.stopPrank();

    // Warp and Execute
    vm.warp(block.timestamp + delay + 1);
    vm.startPrank(fluxTeam);
    dao.execute(proposal1Id);
    dao.execute(proposal2Id);
    vm.stopPrank();
  }
}
