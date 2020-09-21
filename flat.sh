#/bin/bash -f

truffle-flattener contracts/MockERC20.sol >  build/contracts/FlatMockERC20.sol
truffle-flattener contracts/ProviderVault.sol > build/contracts/FlatProviderVault.sol
truffle-flattener contracts/UserStakingPool.sol > build/contracts/FlatUserStakingPool.sol
