//===-- llvm/GlobalObject.h - Class to represent global objects -*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This represents an independent object. That is, a function or a global
// variable, but not an alias.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_IR_GLOBALOBJECT_H
#define LLVM_IR_GLOBALOBJECT_H

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/Value.h"
#include "llvm/Support/Alignment.h"
#include "llvm/Support/Compiler.h"

namespace llvm {

class Comdat;
class Metadata;

class GlobalObject : public GlobalValue {
public:
  // VCallVisibility - values for visibility metadata attached to vtables. This
  // describes the scope in which a virtual call could end up being dispatched
  // through this vtable.
  enum VCallVisibility {
    // Type is potentially visible to external code.
    VCallVisibilityPublic = 0,
    // Type is only visible to code which will be in the current Module after
    // LTO internalization.
    VCallVisibilityLinkageUnit = 1,
    // Type is only visible to code in the current Module.
    VCallVisibilityTranslationUnit = 2,
  };

protected:
  GlobalObject(Type *Ty, ValueTy VTy, AllocInfo AllocInfo, LinkageTypes Linkage,
               const Twine &Name, unsigned AddressSpace = 0)
      : GlobalValue(Ty, VTy, AllocInfo, Linkage, Name, AddressSpace) {
    setGlobalValueSubClassData(0);
  }
  LLVM_ABI ~GlobalObject();

  Comdat *ObjComdat = nullptr;
  enum {
    LastAlignmentBit = 5,
    LastCodeModelBit = 8,
    HasSectionHashEntryBit,

    GlobalObjectBits,
  };
  static const unsigned GlobalObjectSubClassDataBits =
      GlobalValueSubClassDataBits - GlobalObjectBits;

private:
  static const unsigned AlignmentBits = LastAlignmentBit + 1;
  static const unsigned AlignmentMask = (1 << AlignmentBits) - 1;
  static const unsigned GlobalObjectMask = (1 << GlobalObjectBits) - 1;

public:
  GlobalObject(const GlobalObject &) = delete;

protected:
  /// Returns the alignment of the given variable or function.
  ///
  /// Note that for functions this is the alignment of the code, not the
  /// alignment of a function pointer.
  MaybeAlign getAlign() const {
    unsigned Data = getGlobalValueSubClassData();
    unsigned AlignmentData = Data & AlignmentMask;
    return decodeMaybeAlign(AlignmentData);
  }

  /// Sets the alignment attribute of the GlobalObject.
  LLVM_ABI void setAlignment(Align Align);

  /// Sets the alignment attribute of the GlobalObject.
  /// This method will be deprecated as the alignment property should always be
  /// defined.
  LLVM_ABI void setAlignment(MaybeAlign Align);

  unsigned getGlobalObjectSubClassData() const {
    unsigned ValueData = getGlobalValueSubClassData();
    return ValueData >> GlobalObjectBits;
  }

  void setGlobalObjectSubClassData(unsigned Val) {
    unsigned OldData = getGlobalValueSubClassData();
    setGlobalValueSubClassData((OldData & GlobalObjectMask) |
                               (Val << GlobalObjectBits));
    assert(getGlobalObjectSubClassData() == Val && "representation error");
  }

public:
  /// Check if this global has a custom object file section.
  ///
  /// This is more efficient than calling getSection() and checking for an empty
  /// string.
  bool hasSection() const {
    return getGlobalValueSubClassData() & (1 << HasSectionHashEntryBit);
  }

  /// Get the custom section of this global if it has one.
  ///
  /// If this global does not have a custom section, this will be empty and the
  /// default object file section (.text, .data, etc) will be used.
  StringRef getSection() const {
    return hasSection() ? getSectionImpl() : StringRef();
  }

  /// Change the section for this global.
  ///
  /// Setting the section to the empty string tells LLVM to choose an
  /// appropriate default object file section.
  LLVM_ABI void setSection(StringRef S);

  /// Set the section prefix for this global object.
  LLVM_ABI void setSectionPrefix(StringRef Prefix);

  /// Get the section prefix for this global object.
  LLVM_ABI std::optional<StringRef> getSectionPrefix() const;

  bool hasComdat() const { return getComdat() != nullptr; }
  const Comdat *getComdat() const { return ObjComdat; }
  Comdat *getComdat() { return ObjComdat; }
  LLVM_ABI void setComdat(Comdat *C);

  using Value::addMetadata;
  using Value::clearMetadata;
  using Value::eraseMetadata;
  using Value::eraseMetadataIf;
  using Value::getAllMetadata;
  using Value::getMetadata;
  using Value::hasMetadata;
  using Value::setMetadata;

  /// Copy metadata from Src, adjusting offsets by Offset.
  LLVM_ABI void copyMetadata(const GlobalObject *Src, unsigned Offset);

  LLVM_ABI void addTypeMetadata(unsigned Offset, Metadata *TypeID);
  LLVM_ABI void setVCallVisibilityMetadata(VCallVisibility Visibility);
  LLVM_ABI VCallVisibility getVCallVisibility() const;

  /// Returns true if the alignment of the value can be unilaterally
  /// increased.
  ///
  /// Note that for functions this is the alignment of the code, not the
  /// alignment of a function pointer.
  LLVM_ABI bool canIncreaseAlignment() const;

protected:
  LLVM_ABI void copyAttributesFrom(const GlobalObject *Src);

public:
  // Methods for support type inquiry through isa, cast, and dyn_cast:
  static bool classof(const Value *V) {
    return V->getValueID() == Value::FunctionVal ||
           V->getValueID() == Value::GlobalVariableVal ||
           V->getValueID() == Value::GlobalIFuncVal;
  }

private:
  void setGlobalObjectFlag(unsigned Bit, bool Val) {
    unsigned Mask = 1 << Bit;
    setGlobalValueSubClassData((~Mask & getGlobalValueSubClassData()) |
                               (Val ? Mask : 0u));
  }

  LLVM_ABI StringRef getSectionImpl() const;
};

} // end namespace llvm

#endif // LLVM_IR_GLOBALOBJECT_H
