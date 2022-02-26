import {
    TestCAMA,
    TestCAMA__factory,
    OwnedUpgradeabilityProxy,
    OwnedUpgradeabilityProxy__factory
  } from '../typechain';
  import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address';
  import { ethers } from 'hardhat';
  import { BigNumber } from 'ethers';
  import { expect } from 'chai';
  import chai from 'chai';
  chai.use(require('chai-bignumber')(BigNumber));

  describe('CAMA', () => {
    let cama: TestCAMA;
    let impl: TestCAMA;
    let proxy: OwnedUpgradeabilityProxy;
    let owner: SignerWithAddress;
    let signers: SignerWithAddress[];

    beforeEach(async () => {
      signers = await ethers.getSigners();
      owner = signers[0];
      impl = await new TestCAMA__factory(owner).deploy();
      proxy = await new OwnedUpgradeabilityProxy__factory(owner).deploy();
      cama = await new TestCAMA__factory(owner).attach(proxy.address);

      const initializeData = impl.interface.encodeFunctionData('initialize', [
        owner.address, 1000, "CAMA", "CAMA"
      ]);

      await proxy.upgradeToAndCall(impl.address, initializeData);

      expect(await cama.owner()).to.be.eq(owner.address);
      expect(await proxy.implementation()).to.be.eq(impl.address);

      await cama.connect(owner).transferOwnership(signers[1].address);
      expect(await cama.owner()).to.be.eq(signers[1].address);

      await cama.connect(signers[1]).transferOwnership(owner.address);
      expect(await cama.owner()).to.be.eq(owner.address);
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
            .to.be.revertedWith("CAMA: transfer caller is not owner nor approved");
      });

      it('BatchTransfer: Fail', async () => {

        await expect(cama.connect(signers[1]).batchTransfer(signers[2].address, 500))
            .to.be.revertedWith("CAMA: transfer caller is not owner nor approved");
      });

      it('BatchTransferFrom: Fail', async () => {
        await cama.transferFrom(owner.address, signers[1].address, 5);
        await cama.batchTransferFrom(owner.address, signers[2].address, [100,199,798,1005,1008,1009,1111,199999]);
        await cama.batchTransfer(signers[2].address, 765);

        await expect((cama.connect(signers[2]).batchTransferFrom(signers[2].address, signers[3].address, [1,11,17,191,177,100,777]))).to.be.revertedWith("CAMA: Invalid Owner");

      });

      it('BatchTransferFrom', async () => {
        await cama.connect(owner).batchTransfer(signers[1].address, 500);
        let arr = [];

        for (let i = 0; i < 210; i++) {
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

      it('Approve and BatchTransfer', async () => {
        await cama.connect(owner).setApprovalForAll(signers[1].address, true);

        await cama.connect(signers[1]).batchTransfer(signers[2].address, 500);
        expect(await cama.nextBatch()).to.be.eq(1000);
        expect(await cama.ownerOf(499)).to.be.eq(signers[2].address);

        await cama.connect(signers[2]).batchTransferFrom(signers[2].address, signers[3].address, [1,5,113,199,297]);
        expect(await cama.ownerOf(299)).to.be.eq(signers[2].address);
        expect(await cama.ownerOf(297)).to.be.eq(signers[3].address);
      });

      it('Approve and BatchTransferFrom', async () => {
        await cama.connect(owner).setApprovalForAll(signers[1].address, true);

        await cama.connect(signers[1]).batchTransferFrom(owner.address, signers[2].address, [7,99,379,817]);
        expect(await cama.nextBatch()).to.be.eq(0);
        expect(await cama.ownerOf(817)).to.be.eq(signers[2].address);

        await cama.connect(signers[1]).batchTransfer(signers[2].address, 999);
        expect(await cama.ownerOf(299)).to.be.eq(signers[2].address);
        expect(await cama.ownerOf(297)).to.be.eq(signers[2].address);

        // await expect(cama.balanceOf(signers[2].address)).to.be.revertedWith('CAMA: This feature is not available yet');
        // await expect(cama.balanceOf(owner.address)).to.be.revertedWith("CAMA: This feature is not available yet");
      });

      it('Batch Transfer After Random Transfer', async () => {

        await cama.batchTransferFrom(owner.address, signers[1].address, [1,99,117,46,63,712]);

        // await expect(cama.balanceOf(signers[1].address)).to.be.revertedWith("CAMA: This feature is not available yet");
        // await expect(cama.balanceOf(owner.address)).to.be.revertedWith("CAMA: This feature is not available yet");

        await cama.connect(owner).batchTransfer(signers[2].address, 700);

        // await expect(cama.balanceOf(signers[2].address)).to.be.revertedWith("CAMA: This feature is not available yet");
        // await expect(cama.balanceOf(owner.address)).to.be.revertedWith("CAMA: This feature is not available yet");

        expect(await cama.ownerOf(117)).to.be.eq(signers[1].address);
        expect(await cama.ownerOf(712)).to.be.eq(signers[1].address);
        expect(await cama.ownerOf(699)).to.be.eq(signers[2].address);
      });

      it('Set BaseURI', async () => {
        await cama.setBaseURI('abcd');

        expect(await cama.baseURI()).to.be.eq('abcd');
      });

      it('Set BaseURI: Fail', async () => {
        await expect(cama.connect(signers[1]).setBaseURI('abcd')).to.be.revertedWith('CustomOwnable: FORBIDDEN');
      });
    });
  });