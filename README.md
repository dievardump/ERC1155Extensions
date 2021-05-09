# ERC1155Extensions

This repository add some extensions to ERC1155:

- **ERC1155AfterTransfer** adds a `_afterTokenTransfer` hook to all transfer functions, including _mint/Batch and _burn/Batch
- **ERC1155Enumerable** makes use of `ERC1155AfterTransfer` and allows to Track an account holdings, in order to be able to enumerate all tokens of an account