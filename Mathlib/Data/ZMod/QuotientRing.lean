/-
Copyright (c) 2021 Anne Baanen. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Anne Baanen
-/
import Mathlib.RingTheory.Ideal.Quotient.Operations
import Mathlib.RingTheory.Int.Basic
import Mathlib.RingTheory.ZMod

/-!
# `ZMod n` and quotient groups / rings

This file relates `ZMod n` to the quotient ring `ℤ ⧸ Ideal.span {(n : ℤ)}`.

## Main definitions

- `ZMod.quotient_span_nat_equiv_zmod` and `ZMod.quotientSpanEquivZMod `:
  `ZMod n` is the ring quotient of `ℤ` by `n ℤ : Ideal.span {n}`
  (where `n : ℕ` and `n : ℤ` respectively)

## Tags

zmod, quotient ring, ideal quotient
-/

open QuotientAddGroup Set ZMod

variable (n : ℕ) {A R : Type*} [AddGroup A] [Ring R]

namespace Int

/-- `ℤ` modulo the ideal generated by `n : ℕ` is `ZMod n`. -/
def quotientSpanNatEquivZMod : ℤ ⧸ Ideal.span {(n : ℤ)} ≃+* ZMod n :=
  (Ideal.quotEquivOfEq (ZMod.ker_intCastRingHom _)).symm.trans <|
    RingHom.quotientKerEquivOfRightInverse <|
      show Function.RightInverse ZMod.cast (Int.castRingHom (ZMod n)) from intCast_zmod_cast

/-- `ℤ` modulo the ideal generated by `a : ℤ` is `ZMod a.natAbs`. -/
def quotientSpanEquivZMod (a : ℤ) : ℤ ⧸ Ideal.span ({a} : Set ℤ) ≃+* ZMod a.natAbs :=
  (Ideal.quotEquivOfEq (span_natAbs a)).symm.trans (quotientSpanNatEquivZMod a.natAbs)

@[simp]
theorem quotientSpanNatEquivZMod_comp_Quotient_mk (n : ℕ) :
    (Int.quotientSpanNatEquivZMod n : _ →+* _).comp (Ideal.Quotient.mk (Ideal.span {(n : ℤ)})) =
      Int.castRingHom (ZMod n) := rfl

@[simp]
theorem quotientSpanNatEquivZMod_comp_castRingHom (n : ℕ) :
    ((Int.quotientSpanNatEquivZMod n).symm : _ →+* _).comp (Int.castRingHom (ZMod n)) =
      Ideal.Quotient.mk (Ideal.span {(n : ℤ)}) := by ext; simp

@[simp]
theorem quotientSpanEquivZMod_comp_Quotient_mk (n : ℤ) :
    (Int.quotientSpanEquivZMod n : _ →+* _).comp (Ideal.Quotient.mk (Ideal.span {(n : ℤ)})) =
      Int.castRingHom (ZMod n.natAbs) := rfl

@[simp]
theorem quotientSpanEquivZMod_comp_castRingHom (n : ℤ) :
    ((Int.quotientSpanEquivZMod n).symm : _ →+* _).comp (Int.castRingHom (ZMod n.natAbs)) =
      Ideal.Quotient.mk (Ideal.span {(n : ℤ)}) := by ext; simp

end Int

noncomputable section ChineseRemainder
open Ideal

open scoped Function in -- required for scoped `on` notation
/-- The **Chinese remainder theorem**, elementary version for `ZMod`. See also
`Mathlib/Data/ZMod/Basic.lean` for versions involving only two numbers. -/
def ZMod.prodEquivPi {ι : Type*} [Fintype ι] (a : ι → ℕ)
    (coprime : Pairwise (Nat.Coprime on a)) : ZMod (∏ i, a i) ≃+* Π i, ZMod (a i) :=
  have : Pairwise fun i j => IsCoprime (span {(a i : ℤ)}) (span {(a j : ℤ)}) :=
    fun _i _j h ↦ (isCoprime_span_singleton_iff _ _).mpr ((coprime h).cast (R := ℤ))
  Int.quotientSpanNatEquivZMod _ |>.symm.trans <|
  quotEquivOfEq (iInf_span_singleton_natCast (R := ℤ) coprime) |>.symm.trans <|
  quotientInfRingEquivPiQuotient _ this |>.trans <|
  RingEquiv.piCongrRight fun i ↦ Int.quotientSpanNatEquivZMod (a i)

end ChineseRemainder
