import { ethers } from 'hardhat';
import { expect } from 'chai';
import { parseUnits } from 'ethers';

describe('ModernSimpleDex', function () {
  let deployer: any;
  let user: any;
  let token1: any;
  let token2: any;
  let dex: any;

  before(async () => {
    [deployer, user] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const ModernSimpleDex = await ethers.getContractFactory('ModernSimpleDex');
    const MockToken = await ethers.getContractFactory('MockERC20');
    token1 = await MockToken.deploy('Token1', 'TK1', parseUnits('1000', 18));
    token2 = await MockToken.deploy('Token2', 'TK2', parseUnits('1000', 18));
    dex = await ModernSimpleDex.deploy();
  });

  describe('Pool creation', () => {
    it('should create pool', async () => {
      const expectPoolId =
        '0x9a7f2391d65db6a93760246c4ae45f31cc1539e2a53fc27edc370e02825aa49f';

      const token1Address = await token1.getAddress();
      const token2Address = await token2.getAddress();
      await dex.createPool(token1Address, token2Address);

      // const poolId = await dex.tokensToPools(token1Address, token2Address);
      const tokenAddresses = await dex.idToTokens(expectPoolId);

      // expect(poolId).equal(expectPoolId);
      console.log(tokenAddresses);

      // expect(tokenAddresses).equal([token1Address, token2Address]);
    });
  });

  // creation pool
  // deposit liquidity
  // withdraw liquidity
  // swaper single pool
  // swaper multi hop
});
