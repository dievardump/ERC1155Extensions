const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ERC1155EnumerableTest", function() {
  let erc1155Test;
  let accounts = [];
  let addresses = [];

  before(async () => {
    // get accounts
    accounts = await ethers.getSigners();

    // get addresses
    for(let account of accounts) {
      addresses.push(await account.getAddress());
    }

    const ERC1155EnumerableTest = await ethers.getContractFactory("ERC1155EnumerableTest");
    erc1155Test = await ERC1155EnumerableTest.deploy("ipfs://");

  });

  async function getAccountTokensCount(account) {
    return (await erc1155Test.getAccountTokensCount(account)).toNumber();
  }

  async function getAccountTokensByIndex(account, index) {
    return (await erc1155Test.getAccountTokensByIndex(account, index)).toNumber();
  }


  it("Should increment account's getAccountTokensCount() after a mint of a token it did not already hold", async function() {

    const address = addresses[0];
    await erc1155Test.mint(
      address,
      1,
      10,
      []
    );

    expect(await getAccountTokensCount(address)).to.equal(1);

    await erc1155Test.mint(
      address,
      2,
      10,
      []
    );

    expect(await getAccountTokensCount(address)).to.equal(2);

    await erc1155Test.mint(
      address,
      3,
      10,
      []
    );

    expect(await getAccountTokensCount(address)).to.equal(3);

    await erc1155Test.mint(
      address,
      4,
      10,
      []
    );

    expect(await getAccountTokensCount(address)).to.equal(4);
  });

  it("Should not increment account's getAccountTokensCount() after a mint of a token it already hold", async function() {
    const address = addresses[0];

    const beforeCount = await getAccountTokensCount(address);
    await erc1155Test.mint(
      address,
      1,
      10,
      []
    );

    expect(await getAccountTokensCount(address)).to.equal(beforeCount);
  });

  it("Should increment account's getAccountTokensCount() after a transfer of a token it did not hold", async function() {
    const TOKEN_ID = 1;

    const address = addresses[0];
    const address2 = addresses[1];

    const beforeCount = await getAccountTokensCount(address2);
    await erc1155Test.safeTransferFrom(
      address,
      address2,
      TOKEN_ID,
      1,
      []
    );

    expect(await getAccountTokensCount(address2)).to.equal(beforeCount + 1);
    expect(await getAccountTokensByIndex(address2, 0)).to.equal(TOKEN_ID);
  });

  it("Should not increment account's getAccountTokensCount() after a transfer of a token it already holds", async function() {
    const TOKEN_ID = 1;

    const address = addresses[0];
    const address2 = addresses[1];

    const beforeCount = await getAccountTokensCount(address2);
    await erc1155Test.safeTransferFrom(
      address,
      address2,
      TOKEN_ID,
      1,
      []
    );

    expect(await getAccountTokensCount(address2)).to.equal(beforeCount);
  });

  it("Should decrement account's getAccountTokensCount() after the transfer of the whole remaining balance of a token", async function() {
    const TOKEN_ID = 1;

    const address = addresses[0];
    const address2 = addresses[1];

    // get remaining balance for address, token id 1
    const balance = await erc1155Test.balanceOf(address, TOKEN_ID);
    const beforeCount = await getAccountTokensCount(address);

    // send all remaining balance
    await erc1155Test.safeTransferFrom(
      address,
      address2,
      TOKEN_ID,
      balance,
      []
    );

    // should decrement
    expect(await getAccountTokensCount(address)).to.equal(beforeCount - 1);
  });

  it("Should not decrement account's getAccountTokensCount() after burning only part of a token", async function() {
    const TOKEN_ID = 1;

    const address2 = addresses[1];

    const beforeCount = await getAccountTokensCount(address2);

    await erc1155Test.burn(
      address2,
      TOKEN_ID,
      1
    );

    expect(await getAccountTokensCount(address2)).to.equal(beforeCount);
  });

  it("Should decrement account's getAccountTokensCount() after burning all the balance for a token", async function() {
    const TOKEN_ID = 1;

    const address2 = addresses[1];

    const balance = await erc1155Test.balanceOf(address2, TOKEN_ID);
    const beforeCount = await getAccountTokensCount(address2);

    await erc1155Test.burn(
      address2,
      TOKEN_ID,
      balance
    );

    expect(await getAccountTokensCount(address2)).to.equal(beforeCount - 1);
  });

  it("Should increment account's getAccountTokensCount() after a batch transfer they didn't have", async function() {
    const address = addresses[0];
    const address2 = addresses[1];

    const beforeCount = await getAccountTokensCount(address2);

    await erc1155Test.safeBatchTransferFrom(
      address,
      address2,
      [2, 3], // address2 has no token 2 nor token 3
      [1, 1],
      []
      );

      expect(await getAccountTokensCount(address2)).to.equal(beforeCount + 2);
    });

  it("Should increment account's getAccountTokensCount() only of the token they didn't have", async function() {
    const address = addresses[0];
    const address2 = addresses[1];

    const beforeCount = await getAccountTokensCount(address2);

    await erc1155Test.safeBatchTransferFrom(
      address,
      address2,
      [2, 4], // address2 has 2 already, but no 4
      [1, 1],
      []
    );

    expect(await getAccountTokensCount(address2)).to.equal(beforeCount + 1);
  });

  it("Should decrement account's getAccountTokensCount() if transfering all balance", async function() {
    const address = addresses[0];
    const address2 = addresses[1];

    const beforeCount = await getAccountTokensCount(address);

    await erc1155Test.safeBatchTransferFrom(
      address,
      address2,
      [2, 4], // address1 has transfered all tokens 2 and 4 from now on
      [8, 9],
      []
    );

    expect(await getAccountTokensCount(address)).to.equal(beforeCount - 2);
  });

  it("Should only decrement account's getAccountTokensCount() of one in a safe batch with twice a token they didn't have", async function() {
    const address = addresses[0];
    const address2 = addresses[1];

    const beforeCount = await getAccountTokensCount(address);

    await erc1155Test.safeBatchTransferFrom(
      address2,
      address,
      [2, 2], // address1 had no more 2. We transfer it twice from it, but it should only increment of 1
      [5, 2],
      []
    );

    expect(await getAccountTokensCount(address)).to.equal(beforeCount + 1);
  });

  it("Should return a paginated list of token ids", async function() {
    const address2 = addresses[1];

    const count = await getAccountTokensCount(address2);
    const perPage = 2;
    const pages = Math.ceil(count / perPage);

    let pageFromPaginated = 0;
    let countFromPaginated = 0;
    let nextCursor = 0;
    let ids;
    for(let i = 0; i < pages; i++) {
      [ids, balances, nextCursor] = await erc1155Test.getAccountTokensPaginated(
        address2,
        nextCursor, 2
      );
      pageFromPaginated++;
      countFromPaginated += ids.length;
    }

    expect(pages).to.equal(pageFromPaginated);
    expect(count).to.equal(countFromPaginated);
  });
});
