// Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
// Do not modify this file. This file is machine generated, and any changes to it will be overwritten.
package software.amazon.cryptography.materialProviders.model;

import java.util.Objects;

public class EntryAlreadyExists extends NativeError {
  protected EntryAlreadyExists(BuilderImpl builder) {
    super(builder);
  }

  @Override
  public Builder toBuilder() {
    return new BuilderImpl(this);
  }

  public static Builder builder() {
    return new BuilderImpl();
  }

  public interface Builder extends NativeError.Builder {
    Builder message(String message);

    Builder cause(Throwable cause);

    EntryAlreadyExists build();
  }

  static class BuilderImpl extends NativeError.BuilderImpl implements Builder {
    protected BuilderImpl() {
    }

    protected BuilderImpl(EntryAlreadyExists model) {
      super(model);
    }

    @Override
    public Builder message(String message) {
      super.message(message);
      return this;
    }

    @Override
    public Builder cause(Throwable cause) {
      super.cause(cause);
      return this;
    }

    @Override
    public EntryAlreadyExists build() {
      if (Objects.isNull(this.message()))  {
        throw new IllegalArgumentException("Missing value for required field `message`");
      }
      return new EntryAlreadyExists(this);
    }
  }
}
