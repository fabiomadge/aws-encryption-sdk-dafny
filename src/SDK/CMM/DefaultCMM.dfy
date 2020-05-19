// Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

include "../../StandardLibrary/StandardLibrary.dfy"
include "../../StandardLibrary/UInt.dfy"
include "../../StandardLibrary/Base64.dfy"
include "../Materials.dfy"
include "../EncryptionContext.dfy"
include "Defs.dfy"
include "../Keyring/Defs.dfy"
include "../MessageHeader.dfy"
include "../../Util/UTF8.dfy"
include "../Deserialize.dfy"

module {:extern "DefaultCMMDef"} DefaultCMMDef {
  import opened StandardLibrary
  import opened UInt = StandardLibrary.UInt
  import Materials
  import EncryptionContext
  import CMMDefs
  import KeyringDefs
  import AlgorithmSuite
  import Signature
  import Base64
  import MessageHeader
  import UTF8
  import Deserialize

  class DefaultCMM extends CMMDefs.CMM {
    const keyring: KeyringDefs.Keyring

    predicate Valid()
      reads this, Repr
      ensures Valid() ==> this in Repr
    {
      this in Repr &&
      keyring in Repr && keyring.Repr <= Repr && this !in keyring.Repr && keyring.Valid()
    }

    constructor OfKeyring(k: KeyringDefs.Keyring)
      requires k.Valid()
      ensures keyring == k
      ensures Valid() && fresh(Repr - k.Repr)
    {
      keyring := k;
      Repr := {this} + k.Repr;
    }

    method GetEncryptionMaterials(materialsRequest: Materials.EncryptionMaterialsRequest)
                                  returns (res: Result<Materials.ValidEncryptionMaterials>)
      requires Valid()
      ensures Valid()
      ensures Materials.EC_PUBLIC_KEY_FIELD in materialsRequest.encryptionContext ==> res.Failure?
      ensures res.Success? && (materialsRequest.algorithmSuiteID.None? || materialsRequest.algorithmSuiteID.get.SignatureType().Some?) ==>
        Materials.EC_PUBLIC_KEY_FIELD in res.value.encryptionContext
      ensures res.Success? ==> res.value.Serializable()
      ensures res.Success? ==>
        match materialsRequest.algorithmSuiteID
        case Some(id) => res.value.algorithmSuiteID == id
        case None => res.value.algorithmSuiteID == 0x0378
    {
      var reservedField := Materials.EC_PUBLIC_KEY_FIELD;
      assert reservedField in Materials.RESERVED_KEY_VALUES;
      if reservedField in materialsRequest.encryptionContext.Keys {
        return Failure("Reserved Field found in EncryptionContext keys.");
      }
      var id := materialsRequest.algorithmSuiteID.GetOrElse(AlgorithmSuite.AES_256_GCM_IV12_TAG16_HKDF_SHA384_ECDSA_P384);
      var enc_sk := None;
      var enc_ctx := materialsRequest.encryptionContext;

      match id.SignatureType() {
        case None =>
        case Some(param) =>
          var signatureKeys :- Signature.KeyGen(param);
          enc_sk := Some(signatureKeys.signingKey);
          var enc_vk :- UTF8.Encode(Base64.Encode(signatureKeys.verificationKey));
          enc_ctx := enc_ctx[reservedField := enc_vk];
      }

      // Check validity of the encryption context at runtime.
      var validAAD := EncryptionContext.CheckSerializable(enc_ctx);
      if !validAAD {
        //TODO: Provide a more specific error message here, depending on how the EncCtx spec was violated.
        return Failure("Invalid Encryption Context");
      }
      assert EncryptionContext.Serializable(enc_ctx);

      var materials := Materials.EncryptionMaterials.WithoutDataKeys(enc_ctx, id, enc_sk);
      assert materials.encryptionContext == enc_ctx;
      materials :- keyring.OnEncrypt(materials);
      if materials.plaintextDataKey.None? || |materials.encryptedDataKeys| == 0 {
        return Failure("Could not retrieve materials required for encryption");
      }
      assert materials.Valid();
      return Success(materials);
    }

    method DecryptMaterials(materialsRequest: Materials.ValidDecryptionMaterialsRequest)
                            returns (res: Result<Materials.ValidDecryptionMaterials>)
      requires Valid()
      ensures Valid()
      ensures res.Success? ==> res.value.plaintextDataKey.Some?
    {
      // Retrieve and decode verification key from encryption context if using signing algorithm
      var vkey := None;
      var algID := materialsRequest.algorithmSuiteID;
      var encCtx := materialsRequest.encryptionContext;

      if algID.SignatureType().Some? {
        var reservedField := Materials.EC_PUBLIC_KEY_FIELD;
        if reservedField !in encCtx {
          return Failure("Could not get materials required for decryption.");
        }
        var encodedVKey := encCtx[reservedField];
        var utf8Decoded :- UTF8.Decode(encodedVKey);
        var base64Decoded :- Base64.Decode(utf8Decoded);
        vkey := Some(base64Decoded);
      }

      var materials := Materials.DecryptionMaterials.WithoutPlaintextDataKey(encCtx, algID, vkey);
      materials :- keyring.OnDecrypt(materials, materialsRequest.encryptedDataKeys);
      if materials.plaintextDataKey.None? {
        return Failure("Keyring.OnDecrypt failed to decrypt the plaintext data key.");
      }

      return Success(materials);
    }
  }
}
