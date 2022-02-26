import {
    TestCAMA,
    TestCAMA__factory
  } from '../typechain';
  import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address';
  import { ethers } from 'hardhat';
  import { BigNumber } from 'ethers';
  import { expect } from 'chai';
//   import { mineBlocks, expandTo15Decimals, expandTo18Decimals, expandTo17Decimals, expandTo16Decimals, expandTo6Decimals } from './shared/utilities';
  import chai from 'chai';
  chai.use(require('chai-bignumber')(BigNumber));

  describe('CAMA', () => {
    let cama: TestCAMA;
    let owner: SignerWithAddress;
    let signers: SignerWithAddress[];

    beforeEach(async () => {
      signers = await ethers.getSigners();
      owner = signers[0];
      cama = await new TestCAMA__factory(owner).deploy();

      await cama.initialize(owner.address, 1000, "CAMA", "CAMA");
    });

    describe('CAMA: NFT', async () => {
      it('Transfer', async () => {
        expect(await cama.ownerOf((648*(10**12))-1)).to.be.eq(owner.address);
        await cama.connect(owner).batchTransfer(signers[1].address, 500);
        await cama.connect(signers[1]).transferFrom(signers[1].address, signers[2].address, 499);
        expect(await cama.ownerOf(499)).to.be.eq(signers[2].address);

        for (let i = 2; i <= 15; i++) {
          await cama.connect(signers[1]).transferFrom(signers[1].address, signers[i].address, i);
        }

        expect(await cama.ownerOf(15)).to.be.eq(signers[15].address);

      });

      it('BatchTransfer', async () => {
        await cama.connect(owner).batchTransfer(signers[1].address, 500);

        expect(await cama.ownerOf(499)).to.be.eq(signers[1].address);

        expect(await cama.ownerOf(999)).to.be.eq(owner.address);

        await cama.connect(owner).batchTransfer(signers[2].address, 798);

        expect(await cama.ownerOf(1797)).to.be.eq(signers[2].address);
        expect(await cama.ownerOf(1798)).to.be.eq(owner.address);

      });

      it('TransferFrom: Fail', async () => {
        await cama.connect(owner).batchTransfer(signers[1].address, 500);

        expect(await cama.ownerOf(499)).to.be.eq(signers[1].address);

        await expect(cama.connect(signers[1]).transferFrom(signers[1].address, signers[2].address, 500))
            .to.be.revertedWith("ERC2309: transfer caller is not owner nor approved");
      });

      it('BatchTransfer: Fail', async () => {

        await expect(cama.connect(signers[1]).batchTransfer(signers[2].address, 500))
            .to.be.revertedWith("ERC2309: transfer caller is not owner nor approved");
      });

      it('BatchTransferFrom', async () => {
        await cama.connect(owner).batchTransfer(signers[1].address, 500);
        let arr = [];

        for (let i = 0; i < 270; i++) {
            arr.push(i);
        }

        await cama.connect(signers[1]).batchTransferFrom(signers[1].address, signers[2].address, arr);

        expect(await cama.ownerOf(3)).to.be.eq(signers[2].address);

        await cama.connect(signers[2]).transferFrom(signers[2].address, signers[3].address, 199);

      });



      it('Approve and Transfer', async () => {
        await cama.connect(owner).batchTransfer(signers[1].address, 500);
        await cama.connect(owner).approve(signers[1].address, 999);
        expect(await cama.getApproved(999)).to.be.eq(signers[1].address);

        await cama.connect(signers[1]).transferFrom(owner.address, signers[1].address, 999);
        expect(await cama.ownerOf(999)).to.be.eq(signers[1].address);

        await cama.connect(signers[1]).approve(signers[2].address, 999);
        await cama.connect(signers[2]).transferFrom(signers[1].address, signers[2].address, 999);
        expect(await cama.ownerOf(999)).to.be.eq(signers[2].address);

      });

      it('Batch Transfer After Random Transfer', async () => {

        await cama.batchTransferFrom(owner.address, signers[1].address, [1,99,117,46,63,712]);

        expect(await cama.balanceOf(signers[1].address)).to.be.eq(6);
        expect(await cama.balanceOf(owner.address)).to.be.eq(647999999999994);

        await cama.connect(owner).batchTransfer(signers[2].address, 700);

        expect(await cama.balanceOf(signers[2].address)).to.be.eq(700);
        expect(await cama.balanceOf(owner.address)).to.be.eq(647999999999294);

        expect(await cama.ownerOf(117)).to.be.eq(signers[1].address);
        expect(await cama.ownerOf(712)).to.be.eq(signers[1].address);
        expect(await cama.ownerOf(699)).to.be.eq(signers[2].address);

      });
    });
  });