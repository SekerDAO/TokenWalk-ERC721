// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TokenWalkDomain.sol";

/**
 * @dev ERC721 token with editions extension.
 */
contract MultiWalkToken is TokenWalkDomain {

    /**
     * @dev Sets `address artist` as the original artist to the account deploying the NFT.
     */
     constructor (
        string memory _name, 
        string memory _symbol
    ) ERC721(_name, _symbol) {

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes("Token Walk")),
            keccak256(bytes("1")),
            1,
            address(this)
        ));
    }
    
     /**
     * @dev OVERRIDE Base URI for computing {tokenURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://tokenwalk.com/nfts/";
    }

    /**
     * @dev Signs a `tokenId` representing a print.
     */
    function sign(uint256 _tokenId, Signature memory _message, bytes memory _signature) public {
        _signEdition(_tokenId, _message, _signature);
    }

    /**
     * @dev Signs a `tokenId` representing a print.
     */
    function mintEdition(uint _editionNumbers, string memory _tokenURI) public {
        _createEditions(_tokenURI, _editionNumbers);
    }
}