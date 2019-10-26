include "../Materials.dfy"
include "../../StandardLibrary/StandardLibrary.dfy"
include "../../StandardLibrary/UInt.dfy"

module CMMDefs {
  import opened StandardLibrary
  import opened UInt = StandardLibrary.UInt
  import Materials
  import AlgorithmSuite

  trait {:termination false} CMM {
    ghost var Repr : set<object>
    predicate Valid() reads this, Repr

    method GetEncryptionMaterials(encCtx: Materials.EncryptionContext,
                                  algSuiteID: Option<AlgorithmSuite.ID>,
                                  plaintextLen: Option<nat>)
                                  returns (res: Result<Materials.ValidEncryptionMaterialsOutput>)
      requires Valid()
      ensures Valid()
      ensures res.Success? && algSuiteID.Some? ==> res.value.dataKey.algorithmSuiteID == algSuiteID.get

    method DecryptMaterials(algSuiteID: AlgorithmSuite.ID,
                            edks: seq<Materials.EncryptedDataKey>,
                            encCtx: Materials.EncryptionContext)
                            returns (res: Result<Materials.ValidEncryptionMaterialsOutput>)
      requires |edks| > 0
      requires Valid()
      ensures Valid()
  }
}
