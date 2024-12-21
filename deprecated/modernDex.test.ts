import { ethers } from 'hardhat';
import { expect } from 'chai';
import { parseUnits, formatUnits, toBigInt, keccak256, Signer } from 'ethers';

import { MockERC20 } from '../typechain-types';
import { ModernDex } from '../typechain-types';

describe('ModernDex', function () {
  let deployer: Signer;
  let user: Signer;
  let token1: MockERC20;
  let token2: MockERC20;
  let dex: ModernDex;
  let token1Address: string;
  let token2Address: string;
  let dexAddress: string;

  const token1Liquidity = parseUnits('100', 18);
  const token2Liquidity = parseUnits('30', 18);

  const abiCoder = ethers.AbiCoder.defaultAbiCoder();

  before(async () => {
    [deployer, user] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const ModernDex = await ethers.getContractFactory('ModernDex');
    const MockToken = await ethers.getContractFactory('MockERC20');

    token1 = await MockToken.deploy('Token1', 'TK1', parseUnits('1000', 18));
    token2 = await MockToken.deploy('Token2', 'TK2', parseUnits('1000', 18));
    dex = await ModernDex.deploy();

    token1Address = await token1.getAddress();
    token2Address = await token2.getAddress();
    dexAddress = await dex.getAddress();
  });

  describe('Pool creation', () => {
    const { tokenAaddress, tokenAamount, tokenBaddress, tokenBamount } =
      toBigInt(token1Address) < toBigInt(token2Address)
        ? {
            tokenAaddress: token1Address,
            tokenAamount: token1Liquidity,
            tokenBaddress: token2Address,
            tokenBamount: token2Liquidity,
          }
        : {
            tokenAaddress: token2Address,
            tokenAamount: token2Liquidity,
            tokenBaddress: token1Address,
            tokenBamount: token1Liquidity,
          };
    const expectPoolId = keccak256(
      abiCoder.encode(['address', 'address'], [tokenAaddress, tokenBaddress]),
    );

    beforeEach(async () => {
      await token1.approve(dexAddress, token1Liquidity);
      await token2.approve(dexAddress, token2Liquidity);
    });

    it('should create pool', async () => {
      await dex
        .connect(deployer)
        .createPool(
          token1Address,
          token1Liquidity,
          token2Address,
          token2Liquidity,
        );

      const poolId = await dex.tokensToPools(token1Address, token2Address);
      const poolData = await dex.idToPoolData(expectPoolId);

      expect(poolId).equal(expectPoolId);
      expect(poolData.tokenA).equal(tokenAaddress);
      expect(poolData.tokenB).equal(tokenBaddress);
    });

    it('should provider liquidity with pool creation', async () => {
      await dex
        .connect(deployer)
        .createPool(
          token1Address,
          token1Liquidity,
          token2Address,
          token2Liquidity,
        );

      const token1Amount = await token1.balanceOf(await dex.getAddress());
      const token2Amount = await token2.balanceOf(await dex.getAddress());

      expect(token1Amount).equal(token1Liquidity);
      expect(token2Amount).equal(token2Liquidity);
    });

    it('should account for liquidity with pool creation', async () => {
      await dex
        .connect(deployer)
        .createPool(
          token1Address,
          token1Liquidity,
          token2Address,
          token2Liquidity,
        );

      const poolData = await dex.idToPoolData(expectPoolId);

      expect(poolData.liquidityA).equal(tokenAamount);
      expect(poolData.liquidityB).equal(tokenBamount);
    });
  });

  describe('Swap', () => {
    beforeEach(async () => {
      await token1.approve(dexAddress, token1Liquidity);
      await token2.approve(dexAddress, token2Liquidity);
      await dex
        .connect(deployer)
        .createPool(
          token1Address,
          token1Liquidity,
          token2Address,
          token2Liquidity,
        );
    });

    it('should swap one way', async () => {
      const amountIn = parseUnits('10', 18);
      const expectedAmountOut = (amountIn * token2Liquidity) / token1Liquidity;

      const initialToken2Amount = await token2.balanceOf(
        await deployer.getAddress(),
      );

      await token1.approve(dexAddress, token1Liquidity);
      await dex.swap(token1Address, amountIn, token2Address);

      const finalToken2Amount = await token2.balanceOf(
        await deployer.getAddress(),
      );

      expect(finalToken2Amount - initialToken2Amount).equal(expectedAmountOut);
    });

    it('should swap the other way', async () => {
      const amountIn = parseUnits('10', 18);
      const expectedAmountOut = (amountIn * token1Liquidity) / token2Liquidity;

      const initialToken1Amount = await token1.balanceOf(
        await deployer.getAddress(),
      );

      await token2.approve(dexAddress, token1Liquidity);
      await dex.swap(token2Address, amountIn, token1Address);

      const finalToken1Amount = await token1.balanceOf(
        await deployer.getAddress(),
      );

      expect(finalToken1Amount - initialToken1Amount).equal(expectedAmountOut);
    });
  });

  // creation pool
  // deposit liquidity
  // withdraw liquidity
  // swaper single pool
  // swaper multi hop
});
