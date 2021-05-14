// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev ERC721 token with editions extension.
 */
abstract contract TokenWalkDomain is ERC721URIStorage {

    // eip-712
    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }
    
    // Contents of message to be signed
    struct Signature {
        address verificationAddress; // ensure the artists signs only address(this) for each piece
        string artist;
        address wallet;
        string contents;
    }

    //
    struct SpaceOwner {
        uint startIndex;
        uint length;
        address owner;
    }

    // type hashes
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant SIGNATURE_TYPEHASH = keccak256(
        "Signature(address verifyAddress,string artist,address wallet, string contents)"
    );

    bytes32 public DOMAIN_SEPARATOR;
    
    // Optional mapping for signatures
    mapping (uint256 => bytes) private _signatures;

    // the last nft minted
    uint public topId;
    
    // 
    mapping (uint => SpaceOwner) public editionSpaces;
    
    // A view to display an array of IDs that mark the original copy
    uint[] public originalIds;
    
    // A signed token event
    event Signed(address indexed from, uint256 indexed tokenId);
    
    function _designateEditionSpace(uint _editionSupply) internal virtual {
        editionSpaces[topId+1].startIndex = topId+1;
        editionSpaces[topId+1].length = _editionSupply;
        editionSpaces[topId+1].owner = msg.sender;
    }

    /**
     * @dev Creates `tokenIds` representing the printed editions.
     * @param _tokenURI the metadata attached to each nft
     */
    function _createEditions(string memory _tokenURI, uint256 _editionSupply) internal virtual {
        require(_editionSupply > 0, "ERC721Extensions: the edition supply is not set to more than 0");

        originalIds.push(topId+1);

        for(uint i=1; i < _editionSupply+1; i++) {
            _mint(msg.sender, topId+i);
            _setTokenURI(topId+i, _tokenURI);
            topId++;
        }
    }

    /**
     * @dev internal hashing utility 
     * @param _message the signature message struct to be signed
     * the address of this contract is enforced in the hashing
     */
    function _hash(Signature memory _message) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                SIGNATURE_TYPEHASH,
                address(this),
                _message.artist,
                _message.wallet,
                _message.contents
            ))
        ));
    }

    /**
     * @dev Signs a `tokenId` representing a print.
     * @param _tokenId id of the NFT being signed
     * @param _message the signed message
     * @param _signature signature bytes created off-chain
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Signed} event.
     */
    function _signEdition(uint256 _originalId, uint256 _tokenId, Signature memory _message, bytes memory _signature) internal virtual {
        require(msg.sender == editionSpaces[_originalId].owner, "ERC721Extensions: only the artist may sign their work");
        uint endIndex = editionSpaces[_originalId].startIndex + editionSpaces[_originalId].length;
        require(_tokenId <= endIndex && _tokenId >= editionSpaces[_originalId].startIndex, "ERC721Extensions: tokenId is not within owners range");
        require(_signatures[_tokenId].length == 0, "ERC721Extensions: this token is already signed");
        bytes32 digest = _hash(_message);
        address recovered = ECDSA.recover(digest, _signature);
        require(recovered == editionSpaces[_originalId].owner, "ERC721Extensions: artist signature mismatch");
        _signatures[_tokenId] = _signature;
        emit Signed(msg.sender, _tokenId);
    }

    
    /**
     * @dev displays a signature from the artist.
     * @param _tokenId NFT id to verify isSigned
     * @return bytes gets the signature stored on the token
     */
    function getSignature(uint256 _tokenId) external view virtual returns (bytes memory) {
        require(_signatures[_tokenId].length != 0, "ERC721Extensions: no signature exists for this Id");
        return _signatures[_tokenId];
    }
    
    /**
     * @dev returns `true` if the message is signed by the artist.
     * @param _message the message signed by an artist and published elsewhere
     * @param _signature the signature on the message
     * @param _tokenId id of the token to be verified as being signed
     * @return bool true if signed by artist
     * The artist may broadcast signature out of band that will verify on the nft
     */
    function isSigned(uint256 _originalId, Signature memory _message, bytes memory _signature, uint _tokenId) external view virtual returns (bool) {
        bytes32 messageHash = _hash(_message);
        address _artist = ECDSA.recover(messageHash, _signature);
        return (_artist == editionSpaces[_originalId].owner && _equals(_signatures[_tokenId], _signature));
    }

    /**
    * @dev Utility function that checks if two `bytes memory` variables are equal. This is done using hashing,
    * which is much more gas efficient then comparing each byte individually.
    * Equality means that:
    *  - 'self.length == other.length'
    *  - For 'n' in '[0, self.length)', 'self[n] == other[n]'
    */
    function _equals(bytes memory _self, bytes memory _other) internal pure returns (bool equal) {
        if (_self.length != _other.length) {
            return false;
        }
        uint addr;
        uint addr2;
        uint len = _self.length;
        assembly {
            addr := add(_self, /*BYTES_HEADER_SIZE*/32)
            addr2 := add(_other, /*BYTES_HEADER_SIZE*/32)
        }
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }
}