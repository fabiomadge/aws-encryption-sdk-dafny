using System;
using System.IO;
using System.Text;
using STL;

using byteseq = Dafny.Sequence<byte>;
using charseq = Dafny.Sequence<char>;

// General-purpose utilities for invoking Dafny from C#,
// including converting between common Dafny and C# datatypes. 
public class DafnyFFI {
  
    public static MemoryStream MemoryStreamFromSequence(byteseq seq) {
        // TODO: Find a way to safely avoid copying 
        byte[] copy = new byte[seq.Elements.Length];
        Array.Copy(seq.Elements, 0, copy, 0, seq.Elements.Length);
        return new MemoryStream(copy);
    }
  
    public static byteseq SequenceFromMemoryStream(MemoryStream bytes) {
        // TODO: Find a way to safely avoid copying 
        return byteseq.FromArray(bytes.ToArray());
    }

    public static byteseq SequenceFromByteArray(byte[] bytearray) {
        return byteseq.FromArray(bytearray);
    }
  
    public static string StringFromDafnyString(charseq dafnyString) {
        // TODO: Find a way to safely avoid copying.
        // The contents of a Dafny.Sequence should never change, but since a Dafny.ArraySequence
        // currently allows direct access to its array we can't assume that's true.
        return new string(dafnyString.Elements);
    }
    
    public static charseq DafnyStringFromString(string s) {
        // This is safe since string#ToCharArray() creates a fresh array
        return charseq.FromArray(s.ToCharArray());
    }
    
    public static byteseq DafnyUTF8BytesFromString(string s) {
        return byteseq.FromArray(Encoding.UTF8.GetBytes(s));
    }
  
    public static T ExtractResult<T>(Result<T> result) {
        if (result is Result_Success<T> s) {
            return s.value;
        } else if (result is Result_Failure<T> f) {
            // TODO-RS: Need to refine the wrapped value in a Failure so we
            // can throw specific exception types.
            throw new DafnyException(StringFromDafnyString(f.error));
        } else {
            throw new ArgumentException(message: "Unrecognized STL.Result constructor");
        }
    }

    public static Option<T> NullableToOption<T>(T t)
    {
        return t == null ? Option<T>.create_None() : Option<T>.create_Some(t);
    }

    public enum RSAPaddingModes {
        PKCS1, OAEP_SHA1, OAEP_SHA256, OAEP_SHA384, OAEP_SHA512
    }

    public static RSAEncryption.PaddingMode RSAPaddingModesToDafnyPaddingMode(RSAPaddingModes paddingModes)
    {
        RSAEncryption.PaddingMode paddingModeDafny = paddingModes switch {
            DafnyFFI.RSAPaddingModes.PKCS1 => RSAEncryption.PaddingMode.create_PKCS1(),
            DafnyFFI.RSAPaddingModes.OAEP_SHA1 => RSAEncryption.PaddingMode.create_OAEP__SHA1(),
            DafnyFFI.RSAPaddingModes.OAEP_SHA256 => RSAEncryption.PaddingMode.create_OAEP__SHA256(),
            DafnyFFI.RSAPaddingModes.OAEP_SHA384 => RSAEncryption.PaddingMode.create_OAEP__SHA384(),
            DafnyFFI.RSAPaddingModes.OAEP_SHA512 => RSAEncryption.PaddingMode.create_OAEP__SHA512(),
            _ => throw new ArgumentException("Unsupported RSA Padding Mode")
        };
        return paddingModeDafny;
    }

    public enum AESWrappingAlgorithm {
        AES_GCM_128, AES_GCM_192, AES_GCM_256
    }
}

public class DafnyException : Exception {
    public DafnyException(string message) : base(message) {
    }
}
