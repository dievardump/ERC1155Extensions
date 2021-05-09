# ERC1155Extensions

This repository add some extensions to ERC1155:

## ERC1155AfterTransfer

This extension adds a `_afterTokenTransfer` hook to all transfer functions, including _mint/Batch and _burn/Batch


## ERC1155Enumerable

This extensions makes use of `ERC1155AfterTransfer` and allows to track an account holdings, in order to be able to enumerate all tokens of an account

It adds three getters:

```solidity
function getAccountTokensCount(address account) returns (uint256 count)
```

returns the number of different tokens `account`holds

```solidity
function getAccountTokensByIndex(address account, uint256 index) returns (uint256 tokenId)
```

returns the tokenId at `index` in the holdings of `account`

```solidity
function getAccountTokensPaginated(address account, uint256 cursor, uint256 limit) returns (uint256[] ids, uint256[] balances, uint256 nextCursor)
```

returns a paginated list of ids and balance of tokens held by an account

- `ids`: the list of tokenId held by `account` for this page
- `balances`: the balance held for each token in `ids`
- `nextCursor`: the cursor the next page starts at