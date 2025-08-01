/-
Copyright (c) 2018 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Kenny Lau, Johan Commelin, Mario Carneiro, Kevin Buzzard,
Amelia Livingston, Yury Kudryashov
-/
import Mathlib.Algebra.BigOperators.Group.Multiset.Defs
import Mathlib.Algebra.FreeMonoid.Basic
import Mathlib.Algebra.Group.Idempotent
import Mathlib.Algebra.Group.Nat.Hom
import Mathlib.Algebra.Group.Submonoid.MulOpposite
import Mathlib.Algebra.Group.Submonoid.Operations
import Mathlib.Data.Fintype.EquivFin
import Mathlib.Data.Int.Basic

/-!
# Submonoids: membership criteria

In this file we prove various facts about membership in a submonoid:

* `pow_mem`, `nsmul_mem`: if `x ∈ S` where `S` is a multiplicative (resp., additive) submonoid and
  `n` is a natural number, then `x^n` (resp., `n • x`) belongs to `S`;
* `mem_iSup_of_directed`, `coe_iSup_of_directed`, `mem_sSup_of_directedOn`,
  `coe_sSup_of_directedOn`: the supremum of a directed collection of submonoid is their union.
* `sup_eq_range`, `mem_sup`: supremum of two submonoids `S`, `T` of a commutative monoid is the set
  of products;
* `closure_singleton_eq`, `mem_closure_singleton`, `mem_closure_pair`: the multiplicative (resp.,
  additive) closure of `{x}` consists of powers (resp., natural multiples) of `x`, and a similar
  result holds for the closure of `{x, y}`.

## Tags
submonoid, submonoids
-/

assert_not_exists MonoidWithZero

variable {M A B : Type*}

section Assoc

variable [Monoid M] [SetLike B M] [SubmonoidClass B M] {S : B}

end Assoc

section NonAssoc

variable [MulOneClass M]

open Set

namespace Submonoid

-- TODO: this section can be generalized to `[SubmonoidClass B M] [CompleteLattice B]`
-- such that `CompleteLattice.LE` coincides with `SetLike.LE`
@[to_additive]
theorem mem_iSup_of_directed {ι} [hι : Nonempty ι] {S : ι → Submonoid M} (hS : Directed (· ≤ ·) S)
    {x : M} : (x ∈ ⨆ i, S i) ↔ ∃ i, x ∈ S i := by
  refine ⟨?_, fun ⟨i, hi⟩ ↦ le_iSup S i hi⟩
  suffices x ∈ closure (⋃ i, (S i : Set M)) → ∃ i, x ∈ S i by
    simpa only [closure_iUnion, closure_eq (S _)] using this
  refine closure_induction (fun _ ↦ mem_iUnion.1) ?_ ?_
  · exact hι.elim fun i ↦ ⟨i, (S i).one_mem⟩
  · rintro x y - - ⟨i, hi⟩ ⟨j, hj⟩
    rcases hS i j with ⟨k, hki, hkj⟩
    exact ⟨k, (S k).mul_mem (hki hi) (hkj hj)⟩

@[to_additive]
theorem coe_iSup_of_directed {ι} [Nonempty ι] {S : ι → Submonoid M} (hS : Directed (· ≤ ·) S) :
    ((⨆ i, S i : Submonoid M) : Set M) = ⋃ i, S i :=
  Set.ext fun x ↦ by simp [mem_iSup_of_directed hS]

@[to_additive]
theorem mem_sSup_of_directedOn {S : Set (Submonoid M)} (Sne : S.Nonempty)
    (hS : DirectedOn (· ≤ ·) S) {x : M} : x ∈ sSup S ↔ ∃ s ∈ S, x ∈ s := by
  haveI : Nonempty S := Sne.to_subtype
  simp [sSup_eq_iSup', mem_iSup_of_directed hS.directed_val]

@[to_additive]
theorem coe_sSup_of_directedOn {S : Set (Submonoid M)} (Sne : S.Nonempty)
    (hS : DirectedOn (· ≤ ·) S) : (↑(sSup S) : Set M) = ⋃ s ∈ S, ↑s :=
  Set.ext fun x => by simp [mem_sSup_of_directedOn Sne hS]

@[to_additive]
theorem mem_sup_left {S T : Submonoid M} : ∀ {x : M}, x ∈ S → x ∈ S ⊔ T := by
  rw [← SetLike.le_def]
  exact le_sup_left

@[to_additive]
theorem mem_sup_right {S T : Submonoid M} : ∀ {x : M}, x ∈ T → x ∈ S ⊔ T := by
  rw [← SetLike.le_def]
  exact le_sup_right

@[to_additive]
theorem mul_mem_sup {S T : Submonoid M} {x y : M} (hx : x ∈ S) (hy : y ∈ T) : x * y ∈ S ⊔ T :=
  (S ⊔ T).mul_mem (mem_sup_left hx) (mem_sup_right hy)

@[to_additive]
theorem mem_iSup_of_mem {ι : Sort*} {S : ι → Submonoid M} (i : ι) :
    ∀ {x : M}, x ∈ S i → x ∈ iSup S := by
  rw [← SetLike.le_def]
  exact le_iSup _ _

@[to_additive]
theorem mem_sSup_of_mem {S : Set (Submonoid M)} {s : Submonoid M} (hs : s ∈ S) :
    ∀ {x : M}, x ∈ s → x ∈ sSup S := by
  rw [← SetLike.le_def]
  exact le_sSup hs

/-- An induction principle for elements of `⨆ i, S i`.
If `C` holds for `1` and all elements of `S i` for all `i`, and is preserved under multiplication,
then it holds for all elements of the supremum of `S`. -/
@[to_additive (attr := elab_as_elim)
      " An induction principle for elements of `⨆ i, S i`.
      If `C` holds for `0` and all elements of `S i` for all `i`, and is preserved under addition,
      then it holds for all elements of the supremum of `S`. "]
theorem iSup_induction {ι : Sort*} (S : ι → Submonoid M) {motive : M → Prop} {x : M}
    (hx : x ∈ ⨆ i, S i) (mem : ∀ (i), ∀ x ∈ S i, motive x) (one : motive 1)
    (mul : ∀ x y, motive x → motive y → motive (x * y)) : motive x := by
  rw [iSup_eq_closure] at hx
  refine closure_induction (fun x hx => ?_) one (fun _ _ _ _ ↦ mul _ _) hx
  obtain ⟨i, hi⟩ := Set.mem_iUnion.mp hx
  exact mem _ _ hi

/-- A dependent version of `Submonoid.iSup_induction`. -/
@[to_additive (attr := elab_as_elim) "A dependent version of `AddSubmonoid.iSup_induction`. "]
theorem iSup_induction' {ι : Sort*} (S : ι → Submonoid M) {motive : ∀ x, (x ∈ ⨆ i, S i) → Prop}
    (mem : ∀ (i), ∀ (x) (hxS : x ∈ S i), motive x (mem_iSup_of_mem i hxS))
    (one : motive 1 (one_mem _))
    (mul : ∀ x y hx hy, motive x hx → motive y hy → motive (x * y) (mul_mem ‹_› ‹_›)) {x : M}
    (hx : x ∈ ⨆ i, S i) : motive x hx := by
  refine Exists.elim (?_ : ∃ Hx, motive x Hx) fun (hx : x ∈ ⨆ i, S i) (hc : motive x hx) => hc
  refine @iSup_induction _ _ ι S (fun m => ∃ hm, motive m hm) _ hx (fun i x hx => ?_) ?_
      fun x y => ?_
  · exact ⟨_, mem _ _ hx⟩
  · exact ⟨_, one⟩
  · rintro ⟨_, Cx⟩ ⟨_, Cy⟩
    exact ⟨_, mul _ _ _ _ Cx Cy⟩

end Submonoid

end NonAssoc

namespace FreeMonoid

variable {α : Type*}

open Submonoid

@[to_additive]
theorem closure_range_of : closure (Set.range <| @of α) = ⊤ :=
  eq_top_iff.2 fun x _ =>
    FreeMonoid.recOn x (one_mem _) fun _x _xs hxs =>
      mul_mem (subset_closure <| Set.mem_range_self _) hxs

end FreeMonoid

namespace Submonoid
variable [Monoid M] {a : M}

open MonoidHom

theorem closure_singleton_eq (x : M) : closure ({x} : Set M) = mrange (powersHom M x) :=
  closure_eq_of_le (Set.singleton_subset_iff.2 ⟨Multiplicative.ofAdd 1, pow_one x⟩) fun _ ⟨_, hn⟩ =>
    hn ▸ pow_mem (subset_closure <| Set.mem_singleton _) _

/-- The submonoid generated by an element of a monoid equals the set of natural number powers of
    the element. -/
theorem mem_closure_singleton {x y : M} : y ∈ closure ({x} : Set M) ↔ ∃ n : ℕ, x ^ n = y := by
  rw [closure_singleton_eq, mem_mrange]; rfl

theorem mem_closure_singleton_self {y : M} : y ∈ closure ({y} : Set M) :=
  mem_closure_singleton.2 ⟨1, pow_one y⟩

theorem closure_singleton_one : closure ({1} : Set M) = ⊥ := by
  simp [eq_bot_iff_forall, mem_closure_singleton]

section Submonoid
variable {S : Submonoid M} [Fintype S]
open Fintype

/- curly brackets `{}` are used here instead of instance brackets `[]` because
  the instance in a goal is often not the same as the one inferred by type class inference. -/
@[to_additive]
theorem card_bot {_ : Fintype (⊥ : Submonoid M)} : card (⊥ : Submonoid M) = 1 :=
  card_eq_one_iff.2
    ⟨⟨(1 : M), Set.mem_singleton 1⟩, fun ⟨_y, hy⟩ => Subtype.eq <| mem_bot.1 hy⟩

@[to_additive]
theorem eq_bot_of_card_le (h : card S ≤ 1) : S = ⊥ :=
  let _ := card_le_one_iff_subsingleton.mp h
  eq_bot_of_subsingleton S

@[to_additive]
theorem eq_bot_of_card_eq (h : card S = 1) : S = ⊥ :=
  S.eq_bot_of_card_le (le_of_eq h)

@[to_additive card_le_one_iff_eq_bot]
theorem card_le_one_iff_eq_bot : card S ≤ 1 ↔ S = ⊥ :=
  ⟨fun h =>
    (eq_bot_iff_forall _).2 fun x hx => by
      simpa [Subtype.ext_iff] using card_le_one_iff.1 h ⟨x, hx⟩ 1,
    fun h => by simp [h]⟩

@[to_additive]
lemma eq_bot_iff_card : S = ⊥ ↔ card S = 1 :=
  ⟨by rintro rfl; exact card_bot, eq_bot_of_card_eq⟩

end Submonoid

@[to_additive]
theorem _root_.FreeMonoid.mrange_lift {α} (f : α → M) :
    mrange (FreeMonoid.lift f) = closure (Set.range f) := by
  rw [mrange_eq_map, ← FreeMonoid.closure_range_of, map_mclosure, ← Set.range_comp,
    FreeMonoid.lift_comp_of]

@[to_additive]
theorem closure_eq_mrange (s : Set M) : closure s = mrange (FreeMonoid.lift ((↑) : s → M)) := by
  rw [FreeMonoid.mrange_lift, Subtype.range_coe]

@[to_additive]
theorem closure_eq_image_prod (s : Set M) :
    (closure s : Set M) = List.prod '' { l : List M | ∀ x ∈ l, x ∈ s } := by
  rw [closure_eq_mrange, coe_mrange, ← Set.range_list_map_coe, ← Set.range_comp]
  exact congrArg _ (funext <| FreeMonoid.lift_apply _)

@[to_additive]
theorem exists_list_of_mem_closure {s : Set M} {x : M} (hx : x ∈ closure s) :
    ∃ l : List M, (∀ y ∈ l, y ∈ s) ∧ l.prod = x := by
  rwa [← SetLike.mem_coe, closure_eq_image_prod, Set.mem_image] at hx

@[to_additive]
theorem exists_multiset_of_mem_closure {M : Type*} [CommMonoid M] {s : Set M} {x : M}
    (hx : x ∈ closure s) : ∃ l : Multiset M, (∀ y ∈ l, y ∈ s) ∧ l.prod = x := by
  obtain ⟨l, h1, h2⟩ := exists_list_of_mem_closure hx
  exact ⟨l, h1, (Multiset.prod_coe l).trans h2⟩

@[to_additive (attr := elab_as_elim)]
theorem closure_induction_left
    {s : Set M} {motive : (m : M) → m ∈ closure s → Prop} (one : motive 1 (one_mem _))
    (mul_left : ∀ x (hx : x ∈ s), ∀ y hy,
      motive y hy → motive (x * y) (mul_mem (subset_closure hx) hy))
    {x : M} (h : x ∈ closure s) : motive x h := by
  simp_rw [closure_eq_mrange] at h
  obtain ⟨l, rfl⟩ := h
  induction l using FreeMonoid.inductionOn' with
  | one => exact one
  | mul_of x y ih =>
    simp only [map_mul, FreeMonoid.lift_eval_of]
    refine mul_left _ x.prop (FreeMonoid.lift Subtype.val y) _ (ih ?_)
    simp only [closure_eq_mrange, mem_mrange, exists_apply_eq_apply]

@[to_additive (attr := elab_as_elim)]
theorem induction_of_closure_eq_top_left {s : Set M} {motive : M → Prop} (hs : closure s = ⊤)
    (x : M) (one : motive 1) (mul_left : ∀ x ∈ s, ∀ y, motive y → motive (x * y)) : motive x := by
  have : x ∈ closure s := by simp [hs]
  induction this using closure_induction_left with
  | one => exact one
  | mul_left x hx y _ ih => exact mul_left x hx y ih

@[to_additive (attr := elab_as_elim)]
theorem closure_induction_right
    {s : Set M} {motive : (m : M) → m ∈ closure s → Prop} (one : motive 1 (one_mem _))
    (mul_right : ∀ x hx, ∀ y (hy : y ∈ s),
      motive x hx → motive (x * y) (mul_mem hx (subset_closure hy)))
    {x : M} (h : x ∈ closure s) : motive x h :=
  closure_induction_left (s := MulOpposite.unop ⁻¹' s)
    (motive := fun m hm => motive m.unop <| by rwa [← op_closure] at hm)
    one (fun _x hx _y _ => mul_right _ _ _ hx) (by rwa [← op_closure])

@[to_additive (attr := elab_as_elim)]
theorem induction_of_closure_eq_top_right {s : Set M} {motive : M → Prop} (hs : closure s = ⊤)
    (x : M) (one : motive 1) (mul_right : ∀ x, ∀ y ∈ s, motive x → motive (x * y)) : motive x := by
  have : x ∈ closure s := by simp [hs]
  induction this using closure_induction_right with
  | one => exact one
  | mul_right x _ y hy ih => exact mul_right x y hy ih

/-- The submonoid generated by an element. -/
def powers (n : M) : Submonoid M :=
  Submonoid.copy (mrange (powersHom M n)) (Set.range (n ^ · : ℕ → M)) <|
    Set.ext fun n => exists_congr fun i => by simp; rfl

theorem mem_powers (n : M) : n ∈ powers n :=
  ⟨1, pow_one _⟩

theorem coe_powers (x : M) : ↑(powers x) = Set.range fun n : ℕ => x ^ n :=
  rfl

theorem mem_powers_iff (x z : M) : x ∈ powers z ↔ ∃ n : ℕ, z ^ n = x :=
  Iff.rfl

noncomputable instance decidableMemPowers : DecidablePred (· ∈ Submonoid.powers a) :=
  Classical.decPred _

-- Porting note (https://github.com/leanprover-community/mathlib4/issues/11215): TODO the following instance should follow from a more general principle
-- See also https://github.com/leanprover-community/mathlib4/issues/2417
noncomputable instance fintypePowers [Fintype M] : Fintype (powers a) :=
  inferInstanceAs <| Fintype {y // y ∈ powers a}

theorem powers_eq_closure (n : M) : powers n = closure {n} := by
  ext
  exact mem_closure_singleton.symm

lemma powers_le {n : M} {P : Submonoid M} : powers n ≤ P ↔ n ∈ P := by simp [powers_eq_closure]

lemma powers_one : powers (1 : M) = ⊥ := bot_unique <| powers_le.2 <| one_mem _

theorem _root_.IsIdempotentElem.coe_powers {a : M} (ha : IsIdempotentElem a) :
    (Submonoid.powers a : Set M) = {1, a} :=
  let S : Submonoid M :=
  { carrier := {1, a},
    mul_mem' := by
      rintro _ _ (rfl | rfl) (rfl | rfl)
      · rw [one_mul]; exact .inl rfl
      · rw [one_mul]; exact .inr rfl
      · rw [mul_one]; exact .inr rfl
      · rw [ha]; exact .inr rfl
    one_mem' := .inl rfl }
  suffices Submonoid.powers a = S from congr_arg _ this
  le_antisymm (Submonoid.powers_le.mpr <| .inr rfl)
    (by rintro _ (rfl | rfl); exacts [one_mem _, Submonoid.mem_powers _])

/-- The submonoid generated by an element is a group if that element has finite order. -/
abbrev groupPowers {x : M} {n : ℕ} (hpos : 0 < n) (hx : x ^ n = 1) : Group (powers x) where
  inv x := x ^ (n - 1)
  inv_mul_cancel y := Subtype.ext <| by
    obtain ⟨_, k, rfl⟩ := y
    simp only [coe_one, coe_mul, SubmonoidClass.coe_pow]
    rw [← pow_succ, Nat.sub_add_cancel hpos, ← pow_mul, mul_comm, pow_mul, hx, one_pow]
  zpow z x := x ^ z.natMod n
  zpow_zero' z := by simp only [Int.natMod, Int.zero_emod, Int.toNat_zero, pow_zero]
  zpow_neg' m x := Subtype.ext <| by
    obtain ⟨_, k, rfl⟩ := x
    simp only [← pow_mul, Int.natMod, SubmonoidClass.coe_pow]
    rw [Int.negSucc_eq, ← Int.natCast_succ, ← Int.add_mul_emod_self_right (b := (m + 1 : ℕ))]
    nth_rw 1 [← mul_one ((m + 1 : ℕ) : ℤ)]
    rw [← sub_eq_neg_add, ← Int.mul_sub, ← Int.natCast_pred_of_pos hpos]; norm_cast
    simp only [Int.toNat_natCast]
    rw [mul_comm, pow_mul, ← pow_eq_pow_mod _ hx, mul_comm k, mul_assoc, pow_mul _ (_ % _),
      ← pow_eq_pow_mod _ hx, pow_mul, pow_mul]
  zpow_succ' m x := Subtype.ext <| by
    obtain ⟨_, k, rfl⟩ := x
    simp only [← pow_mul, Int.natMod, SubmonoidClass.coe_pow, coe_mul]
    norm_cast
    iterate 2 rw [Int.toNat_natCast, mul_comm, pow_mul, ← pow_eq_pow_mod _ hx]
    rw [← pow_mul _ m, mul_comm, pow_mul, ← pow_succ, ← pow_mul, mul_comm, pow_mul]

/-- Exponentiation map from natural numbers to powers. -/
@[simps!]
def pow (n : M) (m : ℕ) : powers n :=
  (powersHom M n).mrangeRestrict (Multiplicative.ofAdd m)

theorem pow_apply (n : M) (m : ℕ) : Submonoid.pow n m = ⟨n ^ m, m, rfl⟩ :=
  rfl

/-- Logarithms from powers to natural numbers. -/
def log [DecidableEq M] {n : M} (p : powers n) : ℕ :=
  Nat.find <| (mem_powers_iff p.val n).mp p.prop

@[simp]
theorem pow_log_eq_self [DecidableEq M] {n : M} (p : powers n) : pow n (log p) = p :=
  Subtype.ext <| Nat.find_spec p.prop

theorem pow_right_injective_iff_pow_injective {n : M} :
    (Function.Injective fun m : ℕ => n ^ m) ↔ Function.Injective (pow n) :=
  Subtype.coe_injective.of_comp_iff (pow n)

@[simp]
theorem log_pow_eq_self [DecidableEq M] {n : M} (h : Function.Injective fun m : ℕ => n ^ m)
    (m : ℕ) : log (pow n m) = m :=
  pow_right_injective_iff_pow_injective.mp h <| pow_log_eq_self _

/-- The exponentiation map is an isomorphism from the additive monoid on natural numbers to powers
when it is injective. The inverse is given by the logarithms. -/
@[simps]
def powLogEquiv [DecidableEq M] {n : M} (h : Function.Injective fun m : ℕ => n ^ m) :
    Multiplicative ℕ ≃* powers n where
  toFun m := pow n m.toAdd
  invFun m := Multiplicative.ofAdd (log m)
  left_inv := log_pow_eq_self h
  right_inv := pow_log_eq_self
  map_mul' _ _ := by simp only [pow, map_mul, ofAdd_add, toAdd_mul]

theorem log_mul [DecidableEq M] {n : M} (h : Function.Injective fun m : ℕ => n ^ m)
    (x y : powers (n : M)) : log (x * y) = log x + log y :=
  map_mul (powLogEquiv h).symm x y

theorem log_pow_int_eq_self {x : ℤ} (h : 1 < x.natAbs) (m : ℕ) : log (pow x m) = m :=
  (powLogEquiv (Int.pow_right_injective h)).symm_apply_apply _

@[simp]
theorem map_powers {N : Type*} {F : Type*} [Monoid N] [FunLike F M N] [MonoidHomClass F M N]
    (f : F) (m : M) :
    (powers m).map f = powers (f m) := by
  simp only [powers_eq_closure, map_mclosure f, Set.image_singleton]

end Submonoid

@[to_additive]
theorem IsScalarTower.of_mclosure_eq_top {N α} [Monoid M] [MulAction M N] [SMul N α] [MulAction M α]
    {s : Set M} (htop : Submonoid.closure s = ⊤)
    (hs : ∀ x ∈ s, ∀ (y : N) (z : α), (x • y) • z = x • y • z) : IsScalarTower M N α := by
  refine ⟨fun x => Submonoid.induction_of_closure_eq_top_left htop x ?_ ?_⟩
  · intro y z
    rw [one_smul, one_smul]
  · clear x
    intro x hx x' hx' y z
    rw [mul_smul, mul_smul, hs x hx, hx']

@[to_additive]
theorem SMulCommClass.of_mclosure_eq_top {N α} [Monoid M] [SMul N α] [MulAction M α] {s : Set M}
    (htop : Submonoid.closure s = ⊤) (hs : ∀ x ∈ s, ∀ (y : N) (z : α), x • y • z = y • x • z) :
    SMulCommClass M N α := by
  refine ⟨fun x => Submonoid.induction_of_closure_eq_top_left htop x ?_ ?_⟩
  · intro y z
    rw [one_smul, one_smul]
  · clear x
    intro x hx x' hx' y z
    rw [mul_smul, mul_smul, hx', hs x hx]

namespace Submonoid

variable {N : Type*} [CommMonoid N]

open MonoidHom

@[to_additive]
theorem sup_eq_range (s t : Submonoid N) : s ⊔ t = mrange (s.subtype.coprod t.subtype) := by
  rw [mrange_eq_map, ← mrange_inl_sup_mrange_inr, map_sup, map_mrange, coprod_comp_inl, map_mrange,
    coprod_comp_inr, mrange_subtype, mrange_subtype]

@[to_additive]
theorem mem_sup {s t : Submonoid N} {x : N} : x ∈ s ⊔ t ↔ ∃ y ∈ s, ∃ z ∈ t, y * z = x := by
  simp only [sup_eq_range, mem_mrange, coprod_apply, coe_subtype, Prod.exists,
    Subtype.exists, exists_prop]

end Submonoid

namespace AddSubmonoid

variable [AddMonoid A]

open Set

theorem closure_singleton_eq (x : A) :
    closure ({x} : Set A) = AddMonoidHom.mrange (multiplesHom A x) :=
  closure_eq_of_le (Set.singleton_subset_iff.2 ⟨1, one_nsmul x⟩) fun _ ⟨_n, hn⟩ =>
    hn ▸ nsmul_mem (subset_closure <| Set.mem_singleton _) _

/-- The `AddSubmonoid` generated by an element of an `AddMonoid` equals the set of
natural number multiples of the element. -/
theorem mem_closure_singleton {x y : A} : y ∈ closure ({x} : Set A) ↔ ∃ n : ℕ, n • x = y := by
  rw [closure_singleton_eq, AddMonoidHom.mem_mrange]; rfl

theorem closure_singleton_zero : closure ({0} : Set A) = ⊥ := by
  simp [eq_bot_iff_forall, mem_closure_singleton, nsmul_zero]

/-- The additive submonoid generated by an element. -/
def multiples (x : A) : AddSubmonoid A :=
  AddSubmonoid.copy (AddMonoidHom.mrange (multiplesHom A x)) (Set.range (fun i => i • x : ℕ → A)) <|
    Set.ext fun n => exists_congr fun i => by simp

attribute [to_additive existing] Submonoid.powers

attribute [to_additive (attr := simp)] Submonoid.mem_powers

attribute [to_additive (attr := norm_cast)] Submonoid.coe_powers

attribute [to_additive] Submonoid.mem_powers_iff

attribute [to_additive] Submonoid.decidableMemPowers

attribute [to_additive] Submonoid.fintypePowers

attribute [to_additive] Submonoid.powers_eq_closure

attribute [to_additive] Submonoid.powers_le

attribute [to_additive (attr := simp)] Submonoid.powers_one

attribute [to_additive "The additive submonoid generated by an element is
an additive group if that element has finite order."] Submonoid.groupPowers

end AddSubmonoid

namespace Submonoid

/-- An element is in the closure of a two-element set if it is a linear combination of those two
elements. -/
@[to_additive
      "An element is in the closure of a two-element set if it is a linear combination of
      those two elements."]
theorem mem_closure_pair {A : Type*} [CommMonoid A] (a b c : A) :
    c ∈ Submonoid.closure ({a, b} : Set A) ↔ ∃ m n : ℕ, a ^ m * b ^ n = c := by
  rw [← Set.singleton_union, Submonoid.closure_union, mem_sup]
  simp_rw [mem_closure_singleton, exists_exists_eq_and]

end Submonoid

section mul_add

theorem ofMul_image_powers_eq_multiples_ofMul [Monoid M] {x : M} :
    Additive.ofMul '' (Submonoid.powers x : Set M) = AddSubmonoid.multiples (Additive.ofMul x) := by
  ext
  exact Set.mem_image_iff_of_inverse (congrFun rfl) (congrFun rfl)

theorem ofAdd_image_multiples_eq_powers_ofAdd [AddMonoid A] {x : A} :
    Multiplicative.ofAdd '' (AddSubmonoid.multiples x : Set A) =
      Submonoid.powers (Multiplicative.ofAdd x) := by
  symm
  rw [Equiv.eq_image_iff_symm_image_eq]
  exact ofMul_image_powers_eq_multiples_ofMul

end mul_add
