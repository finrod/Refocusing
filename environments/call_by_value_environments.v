Add LoadPath "../utils".
Require Import refocusing_environments.

Module CallByValue <: RED_LANG.

  Inductive term' : Set :=
  | var : nat -> term'
  | lam : term' -> term'
  | app : term' -> term' -> term'.
  Definition term := term'.

  Inductive closure' : Set :=
  | pair' : term -> list closure' -> closure'
  | comp  : closure' ->  closure' -> closure'.
  Definition closure := closure'.
  Definition env := list closure.
  Definition pair := pair'.

  Inductive value' : Set :=
  | v_lam : term -> env -> value'.
  Definition value := value'.

  Inductive redex' : Set :=
  | r_beta : value -> value -> redex'
  | r_get  : nat -> env -> redex'
  | r_app  : term -> term -> env -> redex'.
  Definition redex := redex'.

  Inductive frame' : Set :=
  | ap_r : closure -> frame'
  | ap_l : value -> frame'.
  Definition frame := frame'.
  Definition context := list frame.
  Definition empty : context := nil.

  Inductive closureC' : Set :=
  | pairC' : term -> list closureC' -> closureC'.
  Definition closureC := closureC'.
  Definition pairC := pairC'.
  Definition envC := list closureC.

  Inductive valueC' : Set :=
  | v_lamC : term -> envC -> valueC'.
  Definition valueC := valueC'.

  Inductive frameC' : Set :=
  | ap_rC : closureC -> frameC'
  | ap_lC : valueC -> frameC'.
  Definition frameC := frameC'.
  Definition contextC := list frameC'.
  Definition emptyC : contextC := nil.

  Definition value_to_closure (v : value) : closure :=
  match v with v_lam t s => pair (lam t) s end.
  Coercion value_to_closure : value >-> closure.
  Definition redex_to_closure (r : redex) : closure :=
  match r with
  | r_beta v v' => comp (v:closure) (v':closure)
  | r_get n s   => pair (var n) s
  | r_app t1 t2 s => pair (app t1 t2) s
  end.
  Coercion redex_to_closure : redex >-> closure.

  Definition atom_plug (c : closure) (f : frame) :=
    match f with
    | ap_r c0 => comp c c0 
    | ap_l v => comp (v : closure) c
    end.

  Definition plug (c : closure) (E : context) : closure := fold_left atom_plug E c.
  Definition compose (E E0 : context) : context := E ++ E0.
  Definition composeC (E E0 : contextC) : contextC := E ++ E0.

  Definition valueC_to_closureC (v : valueC) : closureC :=
  match v with v_lamC t s => pairC (lam t) s end.
  Coercion valueC_to_closureC : valueC >-> closureC.

  Fixpoint closureC_to_closure (cl : closureC) : closure :=
  match cl with pairC t s => pair t (map closureC_to_closure s) end.
  Coercion closureC_to_closure : closureC >-> closure.
  Definition envC_to_env : envC -> env := map closureC_to_closure.

  Definition valueC_to_value (v : valueC) : value :=
  match v with v_lamC t s => v_lam t (envC_to_env s) end.

  Definition frameC_to_frame (fC : frameC) : frame :=
  match fC with
  | ap_rC cC => ap_r cC
  | ap_lC vC => ap_l (valueC_to_value vC)
  end.
  Coercion frameC_to_frame : frameC >-> frame.
  Definition contextC_to_context : contextC -> context := map frameC_to_frame.
  Coercion contextC_to_context : contextC >-> context.

  Lemma closureC_ind : forall P : closureC' -> Prop,
  (forall (t : term) (l : list closureC'), (forall t0, In t0 l -> P t0) -> P (pairC' t l)) ->
  forall c : closureC', P c.
  Proof with auto.
    intros P h; refine (fix IH (c : closureC') : P c := _);
    destruct c; apply h; induction l; intros; destruct H; [rewrite <- H | apply IHl]...
  Qed.

  Lemma closureC_to_closure_injective : forall (cl cl0 : closureC), closureC_to_closure cl = closureC_to_closure cl0 -> cl = cl0.
  Proof with isda.
    induction cl using closureC_ind; destruct cl0; intro H_eq; inversion H_eq; f_equal; subst; clear H_eq.
    generalize dependent l0; induction l; destruct l0...
    inversion H2; f_equal...
  Qed.
  Hint Resolve closureC_to_closure_injective : ref.

  Definition envC_to_env_injective : forall sC sC0, envC_to_env sC = envC_to_env sC0 -> sC = sC0 :=
    map_injective closureC_to_closure closureC_to_closure_injective.
  Hint Resolve envC_to_env_injective : ref.

  Lemma valueC_to_value_injective : forall (v v0 : valueC), valueC_to_value v = valueC_to_value v0 -> v = v0.
  Proof with auto with ref.
    destruct v; destruct v0; intro H; inversion H; f_equal...
  Qed.
  Hint Resolve valueC_to_value_injective : ref.

  Lemma frameC_to_frame_injective : forall fC fC0, frameC_to_frame fC = frameC_to_frame fC0 -> fC = fC0.
  Proof with auto with ref.
    destruct fC; destruct fC0; intro H; inversion H; f_equal...
  Qed.
  Hint Resolve frameC_to_frame_injective : ref.

  Definition contextC_to_context_injective : forall E E0, contextC_to_context E = contextC_to_context E0 -> E = E0 :=
    map_injective frameC_to_frame frameC_to_frame_injective.
  Hint Resolve contextC_to_context_injective : ref.

  Lemma valueC_to_closureC_injective : forall (v v0 : valueC), valueC_to_closureC v = valueC_to_closureC v0 -> v = v0.
  Proof with auto.
    destruct v; destruct v0; intro H; inversion H; f_equal...
  Qed.
  Hint Resolve valueC_to_closureC : ref.

  Lemma value_to_closure_injective : forall v v0, value_to_closure v = value_to_closure v0 -> v = v0.
  Proof.
    destruct v; destruct v0; intro H; inversion H; f_equal...
  Qed.
  Hint Resolve value_to_closure_injective : ref.
  Lemma redex_to_closure_injective : forall r r0, redex_to_closure r = redex_to_closure r0 -> r = r0.
  Proof.
    destruct r; destruct r0; intro H; inversion H; f_equal; auto with ref.
  Qed.

  Lemma pairC_pair : forall t sC, closureC_to_closure (pairC t sC) = pair t (map closureC_to_closure sC).
  Proof. auto. Qed.
  Lemma pairC_injective : forall t t0 sC sC0, pairC t sC = pairC t0 sC0 -> t = t0 /\ sC = sC0.
  Proof. 
    intros t t0 sC sC0 PS; inversion PS; auto.
  Qed.
  Lemma valueC_to_closure_commutes : forall v, value_to_closure (valueC_to_value v) = closureC_to_closure (valueC_to_closureC v).
  Proof. destruct v; isda. Qed.

  Fixpoint nth_option (s : env) (n : nat) {struct s} : option closure :=
  match s, n with
  | nil, _ => None
  | h::t, O => Some h
  | h::t, S m => nth_option t m
  end.

  Definition contract (r : redex) : option closure :=
  match r with
  | r_beta (v_lam t s) cl => Some (pair t (value_to_closure cl :: s))
  | r_get x s => nth_option s x
  | r_app t s cl => Some (comp (pair t cl) (pair s cl))
  end.

  Definition only_empty (c : closure) : Prop := forall c0 E, plug c0 E = c -> E = empty.
  Definition only_trivial (c : closure) : Prop := forall c0 E, plug c0 E = c -> E = empty \/ exists v, c0 = value_to_closure v.

  Lemma closureC_only_empty : forall cC, only_empty (closureC_to_closure cC).
  Proof with isda.
    intros cC c E; generalize dependent c; induction E...
    assert (T := IHE _ H); subst; destruct cC; destruct a; discriminate.
  Qed.
  Lemma value_trivial : forall v : value, only_trivial (value_to_closure v).
  Proof with isda.
    intros v c E; generalize dependent c; induction E...
    destruct (IHE _ H) as [H0 | [v0 H0]]; subst; simpl in *;
    match goal with [Hdisc : atom_plug ?t ?a = _ ?v |- _ ] => destruct a; destruct v; discriminate Hdisc end.
  Qed.
  Lemma redex_trivial : forall r : redex, only_trivial (redex_to_closure r).
  Proof with isda; eauto.
    intros r c E; generalize dependent c; induction E...
    right; destruct (IHE _ H) as [H0 | [v0 H0]]; subst; simpl in *;
    match goal with [Hinv : atom_plug ?c ?a = _ ?rv |- _ ] => destruct a; destruct rv; inversion Hinv end...
  Qed.
  Lemma value_redex : forall (v : value) (r : redex), value_to_closure v <> redex_to_closure r.
  Proof.
    destruct v; destruct r; isda.
  Qed.

  Lemma ot_subt : forall c c0 f, only_trivial c -> atom_plug c0 f = c -> exists v, c0 = value_to_closure v.
  Proof with isda; eauto.
    intros; destruct (H c0 (f :: nil)) as [H1 | [v H1]]...
  Qed.

  Ltac ot_v c f :=
  match goal with
  | [Hot : (only_trivial ?H1) |- _] => destruct (ot_subt _ c f Hot) as [?v HV]; [auto | subst c]
  end.

  Ltac mlr rv :=
  match goal with
  | [ |- (exists v, ?H1 = value_to_closure v) \/ (exists r, ?H1 = redex_to_closure r)] =>
    match rv with
    | (?v : value) => left; exists v
    | (?r : redex) => right; exists r
    end; simpl; auto
  end.

  Lemma trivial_val_red : forall c : closure, only_trivial c ->
    (exists v : value, c = value_to_closure v) \/ (exists r : redex, c = redex_to_closure r).
  Proof.
    destruct c; intros.
    destruct t.
    mlr (r_get n l).
    mlr (v_lam t l).
    mlr (r_app t1 t2 l).
    ot_v c1 (ap_r c2); ot_v c2 (ap_l v); mlr (r_beta v v0).
  Qed.

  (** Datatype of decompositions -- either a value or a redex in a context (analogous to the decompose lemma) *)
  Inductive decomp : Set :=
  | d_val : value -> decomp
  | d_red : redex -> context -> decomp.

  Inductive interm_dec : Set :=
  | in_red : redex -> interm_dec
  | in_val : value -> interm_dec
  | in_clo : closure -> frame -> interm_dec.

  Definition decomp_to_closure (d : decomp) : closure :=
  match d with
    | d_val v => value_to_closure v
    | d_red r c0 => plug (redex_to_closure r) c0
  end.

  Definition closureC_dec : forall cC : closureC,
    {p : term * envC + valueC | match p with
	| inl (t, sC) => cC = pairC t sC
	| inr vC => cC = valueC_to_closureC vC
    end}.
  Proof with auto.
    destruct cC as [t sC]; exists (inl _ (t, sC))...
  Defined.
  Lemma dec_pairC : forall t sC, proj1_sig (closureC_dec (pairC t sC)) = inl _ (t, sC).
  Proof with auto.
    intros; simpl in *...
  Qed.

End CallByValue.

Module CBV_Prop <: LANG_PROP CallByValue := Lang_Prop CallByValue.

Module CallByValue_Eval <: RED_SEM CallByValue.
  Import CallByValue.
  Module P := CBV_Prop.
  Import P.
  Open Scope red_scope.

  Inductive dec' : closure -> context -> decomp -> Prop :=
  | d_var  : forall n s E,
               dec' (pair (var n) s) E (d_red (r_get n s) E)
  | d_v    : forall v E d
               (DEC_E : decctx E v d),
               dec' (v : closure) E d
  | d_app  : forall t0 t1 s E,
               dec' (pair (app t0 t1) s) E (d_red (r_app t0 t1 s) E)
  | d_cmp  : forall c0 c1 E d
               (DEC_C : dec' c0 (ap_r c1 :: E) d),
               dec' (comp c0 c1) E d
  with decctx : context -> value -> decomp -> Prop :=
  | dc_emp : forall v, decctx empty v (d_val v)
  | dc_apR : forall cl E v d
               (DEC_C : dec' cl (ap_l v :: E) d),
               decctx (ap_r cl :: E) v d
  | dc_apL : forall v v0 E,
               decctx (ap_l v :: E) v0 (d_red (r_beta v v0) E).

  Definition dec := dec'.
  Scheme dec_Ind := Induction for dec' Sort Prop
  with decctx_Ind := Induction for decctx Sort Prop.

  Inductive decempty : closure -> decomp -> Prop :=
  | d_intro : forall (c : closure) (d : decomp) (DEC : dec c empty d), decempty c d.

  Inductive iter : decomp -> value -> Prop :=
  | i_val : forall (v : value), iter (d_val v) v
  | i_red : forall (r : redex) (c : closure) (E : context) (d : decomp) (v : value)
              (CONTR : contract r = Some c)
              (D_EM  : decempty (E [c]) d)
              (R_IT  : iter d v),
              iter (d_red r E) v.

  Inductive eval : term -> value -> Prop :=
  | e_intro : forall (t : term) (d : decomp) (v : value)
                (D_EM : decempty (pair t nil) d)
                (ITER : iter d v),
                eval t v.

  Hint Constructors dec' decctx decempty iter eval.
  Hint Unfold dec.

  (** A redex in context will only ever be reduced to itself *)
  Lemma dec_redex_self : forall (r : redex) (c : context), dec (redex_to_closure r) c (d_red r c).
  Proof. destruct r; repeat constructor. Qed.

  Lemma decompose : forall c : closure, (exists v : value, c = v) \/
      (exists r : redex, exists E :context, c = E [ r ]).
  Proof with isda.
    induction c; try destruct t...
    right; exists (r_get n l); exists empty...
    left;  exists (v_lam t l)...
    right; exists (r_app t1 t2 l); exists empty...
    destruct IHc1 as [[v Hv] | [r [E HrE]]]; subst.
    destruct IHc2 as [[v0 Hv0] | [r [E HrE]]]; subst.
    right; exists (r_beta v v0); exists empty...
    right; exists r; exists (E · (ap_l v :: nil)); rewrite plug_compose...
    right; exists r; exists (E · (ap_r c2 :: nil)); rewrite plug_compose...
  Qed.

  (** dec is left inverse of plug *)
  Lemma dec_correct : forall c E d, dec c E d -> decomp_to_closure d = E [c].
  Proof with isda.
    induction 1 using dec_Ind with
    (P := fun c E d (DEC : dec c E d) => decomp_to_closure d = E [c])
    (P0:= fun E v d (DECX : decctx E v d) => decomp_to_closure d = E [v])...
  Qed.

  Lemma dec_plug : forall E E0 c d, dec (E [c]) E0 d -> dec c (E · E0) d.
  Proof with isda.
    induction E...
    apply IHE in H; destruct a...
    inversion H; subst; try destruct v...
    inversion H; subst; try destruct v0...
    inversion DEC_C; try destruct v; subst...
    inversion DEC_E; destruct v0; inversion H1; subst...
  Qed.

  Lemma dec_plug_rev : forall E E0 c d, dec c (E · E0) d -> dec (E [c]) E0 d.
  Proof with isda; auto 6.
    induction E; try destruct a...
  Qed.

End CallByValue_Eval.

Module CallByValue_Ref <: RED_REF_LANG.

  Module Lang := CallByValue.
  Import Lang.

  Definition dec_closure (cl : closure) : interm_dec :=
  match cl with
  | pair (lam t) s => in_val (v_lam t s)
  | pair (var n) s => in_red (r_get n s)
  | pair (app t t0) s => in_red (r_app t t0 s)
  | comp cl0 cl1 => in_clo cl0 (ap_r cl1)
  end.

  Definition dec_context (f : frame) (v : value) : interm_dec :=
  match f with
  | ap_r cl => in_clo cl (ap_l v)
  | ap_l v0 => in_red (r_beta v0 v)
  end.

  Inductive subclosure_one_step : closure -> closure -> Prop :=
  | scl : forall cl cl0 f (AP : cl = atom_plug cl0 f), subclosure_one_step cl0 cl.
  Lemma subclosure_one_step_wf : well_founded subclosure_one_step.
  Proof. prove_st_wf. Qed.

  Definition closure_order : closure -> closure -> Prop := clos_trans_n1 _ subclosure_one_step.
  Notation " cl <| cl0 " := (closure_order cl cl0) (at level 40) : red_scope.
  Definition closure_order_wf : well_founded closure_order := wf_clos_trans_r _ _ subclosure_one_step_wf.

  Definition frame_order (f f0 : frame) : Prop :=
  match f, f0 with
  | ap_l _, ap_r _ => True
  | _, _ => False
  end.
  Notation " f <: f0 " := (frame_order f f0) (at level 40) : red_scope.
  Lemma frame_order_wf : well_founded frame_order.
  Proof. prove_ec_wf. Qed.

  Open Scope red_scope.

  Lemma dec_closure_red_empty  : forall c r, dec_closure c = in_red r -> only_empty c.
  Proof with isda.
    destruct c; intros r H; try discriminate; destruct t; inversion H; subst; clear H; intros c E H;
    generalize dependent c; induction E; isda; assert (ht := IHE _ H); subst; destruct a...
  Qed.
  Lemma dec_closure_val_empty  : forall c v, dec_closure c = in_val v -> only_empty c.
  Proof with isda.
    destruct c; intros r H; try discriminate; destruct t; inversion H; subst; clear H; intros c E H;
    generalize dependent c; induction E...
    assert (ht := IHE _ H); subst; destruct a...
  Qed.
  Lemma dec_closure_clo_top    : forall c c0 f, dec_closure c = in_clo c0 f -> forall f0, ~f <: f0.
  Proof.
    destruct c; try destruct t; intros; inversion H; subst; isda.
  Qed.
  Lemma dec_context_red_bot    : forall f v r, dec_context f v = in_red r -> forall f0, ~ f0 <: f.
  Proof.
    destruct f; intros; inversion H; subst; destruct f0; isda.
  Qed.
  Lemma dec_context_val_bot    : forall f v v0, dec_context f v = in_val v0 -> forall f0, ~ f0 <: f.
  Proof. destruct f; isda. Qed.
  Lemma dec_context_clo_next   : forall f f0 v c, dec_context f v = in_clo c f0 -> f0 <: f /\ forall f1, f1 <: f -> ~ f0 <: f1.
  Proof. 
    destruct f; intros; inversion H; subst; intuition isda; destruct f1; isda.
  Qed.

  Lemma dec_closure_correct : forall c, match dec_closure c with
    | in_red r => redex_to_closure r = c
    | in_val v => value_to_closure v = c
    | in_clo c0 f =>  atom_plug c0 f = c
    end.
  Proof with isda.
    destruct c; try destruct t...
  Qed.
  Lemma dec_context_correct : forall f v, match dec_context f v with
    | in_red r  => redex_to_closure r  = atom_plug (value_to_closure v) f
    | in_val v0 => value_to_closure v0 = atom_plug (value_to_closure v) f
    | in_clo c f0 => atom_plug c f0 = atom_plug (value_to_closure v) f
    end.
  Proof.
    destruct f; isda.
  Qed.

  Lemma frame_order_antisym : forall f f0, f <: f0 -> ~ f0 <: f.
  Proof.
    destruct f; destruct f0; isda.
  Qed.
  Lemma dec_frame_ord : forall c c0 f f0, atom_plug c f = atom_plug c0 f0 -> f <: f0 \/ f0 <: f \/ (c = c0 /\ f = f0).
  Proof.
    destruct f; destruct f0; intros; inversion H; isda; apply value_to_closure_injective in H1; subst; isda. 
  Qed.
  Lemma frame_det : forall c c0 f f0, f <: f0 -> atom_plug c f = atom_plug c0 f0 -> exists v, c0 = value_to_closure v.
  Proof.
    destruct f; destruct f0; intros; inversion H; inversion H0; subst; eauto.
  Qed.

  Lemma getC : forall l i r, nth_option (map closureC_to_closure l) i = Some r ->
    {c:closureC | r = closureC_to_closure c}.
  Proof.
    induction l; induction i; simpl; intros; try discriminate.
    split with a; congruence.
    eapply IHl; eapply H.
  Qed.

  Definition dcl c cC ofC : Prop :=
  match ofC with
  | None => c = closureC_to_closure cC
  | Some fC => dec_closure c = in_clo (closureC_to_closure cC) (frameC_to_frame fC)
  end.

  Definition closure_red : forall cC r cl (DCL : dec_closure (closureC_to_closure cC) = in_red r) (CTR : contract r = Some cl),
    {p : closureC * option frameC | match p with (cC, ofC) => dcl cl cC ofC end }.
  Proof with isda.
    destruct cC; destruct t; intros; inversion DCL; subst; inversion CTR; subst.
    destruct (getC _ _ _ H0) as [cC EQCC]; subst; exists (cC, None)...
    exists (pairC t1 l, Some (ap_rC (pairC t2 l)))...
  Defined.
  Definition context_red : forall fC vC r cl (DCT : dec_context (frameC_to_frame fC) (valueC_to_value vC) = in_red r) (CTR : contract r = Some cl),
    {p : closureC * option frameC | match p with (cC, ofC) => dcl cl cC ofC end}.
  Proof with isda.
    destruct fC; intros; inversion DCT; subst; destruct v; inversion CTR; subst.
    exists (pairC t ((valueC_to_closureC vC) :: e), None); simpl; repeat f_equal.
    rewrite valueC_to_closure_commutes...
  Defined.
  Definition closure_val : forall cC v (DCL : dec_closure (closureC_to_closure cC) = in_val v), { vC : valueC | v = valueC_to_value vC}.
  Proof with isda.
    destruct cC as [t sC]; destruct t; intros; inversion DCL; subst; exists (v_lamC t sC)...
  Defined.
  Definition context_val : forall fC vC v (DCT : dec_context (frameC_to_frame fC) (valueC_to_value vC) = in_val v),
    {vC0 : valueC | v = valueC_to_value vC0}.
  Proof with isda.
    destruct fC...
  Defined.
  Definition context_clo : forall fC vC cl f (DCT : dec_context (frameC_to_frame fC) (valueC_to_value vC) = in_clo cl f),
    { p : closureC * frameC | match p with 
      (cC, fC) => cl = closureC_to_closure (cC) /\ f = frameC_to_frame fC
    end}.
  Proof with isda.
    destruct fC; intros; inversion DCT; subst; exists (c, ap_lC vC)...
  Defined.

  (*Definition closure_red : forall cC r cl (DCL : dec_closure (closureC_to_closure cC) = in_red r) (CTR : contract r = Some cl),
    {p : term * envC * option frameC | match p with (t, sC, ofC) => dcl cl t sC ofC end }.
  Proof with isda.
    destruct cC; destruct t; intros; inversion DCL; subst; inversion CTR; subst.
    destruct (getC _ _ _ H0) as [cC EQCC]; subst; destruct cC.
    exists (t, l0, None)...
    exists (t1, l, Some (ap_rC (pairC t2 l)))...
  Defined.
  Lemma context_red : forall fC vC r cl (DCT : dec_context (frameC_to_frame fC) (valueC_to_value vC) = in_red r) (CTR : contract r = Some cl),
    {p : term * envC * option frameC | match p with (t, sC, ofC) => dcl cl t sC ofC end}.
  Proof with isda.
    destruct fC; intros; inversion DCT; subst; destruct vC; destruct v; inversion CTR; subst.
    exists (t0, (pairC (lam t) e)  :: e0, None)...
  Defined.
  Lemma closure_val : forall cC v (DCL : dec_closure (closureC_to_closure cC) = in_val v), { vC : valueC | v = valueC_to_value vC}.
  Proof with isda.
    destruct cC; destruct t; intros; inversion DCL; subst; exists (v_lamC t l)...
  Defined.
  Lemma context_val : forall fC vC v (DCT : dec_context (frameC_to_frame fC) (valueC_to_value vC) = in_val v),
    {vC0 : valueC | v = valueC_to_value vC0}.
  Proof.
    destruct fC; isda.
  Defined.
  Lemma context_clo : forall fC vC cl f (DCT : dec_context (frameC_to_frame fC) (valueC_to_value vC) = in_clo cl f),
    { p : term * envC * frameC | match p with 
      (t, sC, fC) => cl = closureC_to_closure (pairC t sC) /\ f = frameC_to_frame fC
    end}.
  Proof.
    destruct fC; intros; inversion DCT; destruct c; subst.
    exists (t, l, ap_lC vC); isda.
  Defined.*)

  Close Scope red_scope.

End CallByValue_Ref.

Module CBV_RS <: RED_REF_SEM CallByValue := RedRefSem CallByValue_Ref.

Section Equivalence.

  Import CallByValue.

  Lemma dec_equiv : forall c E d, CallByValue_Eval.dec c E d <-> CBV_RS.dec c E d.
  Proof with isda.
    split...
    induction H using CallByValue_Eval.dec_Ind with
    (P := fun c E d (DEC : CallByValue_Eval.dec c E d) => CBV_RS.dec c E d)
    (P0:= fun E v d (DECX : CallByValue_Eval.decctx E v d) => CBV_RS.decctx E v d)...
    destruct v; econstructor...
    econstructor 3...
    econstructor 4...
    induction H using CBV_RS.dec_Ind with
    (P := fun c E d (DEC : CBV_RS.dec c E d) => CallByValue_Eval.dec c E d)
    (P0:= fun E v d (DECX : CBV_RS.decctx E v d) => CallByValue_Eval.decctx E v d);
    match goal with
    | [ DCL : CBV_RS.dec_closure ?c = ?int |- _ ] => destruct c; try destruct t; inversion DCL; subst
    | [ DCT : CBV_RS.dec_context ?f ?v = ?int |- _ ] => destruct f; inversion DCT; subst
    | [ |- _ ] => idtac
    end...
    cutrewrite ((pair' (lam t) l : closure) = (v_lam t l : value)); auto.
  Qed.

  Lemma iter_equiv : forall d v, CallByValue_Eval.iter d v <-> CBV_RS.RS.iter d v.
  Proof with isda.
    split; intro H; induction H; econstructor; eauto; constructor; inversion_clear D_EM;
    [rewrite <- dec_equiv | rewrite dec_equiv]...
  Qed.

  Lemma eval_equiv : forall t v, CallByValue_Eval.eval t v <-> CBV_RS.RS.eval t v.
  Proof with isda.
    split; intro H; inversion_clear H; inversion_clear D_EM; constructor 1 with d;
      [constructor; rewrite <- dec_equiv | rewrite <- iter_equiv
      | constructor; rewrite dec_equiv | rewrite iter_equiv]...
  Qed.

End Equivalence.

Module CBV_EAM <: PROPER_EA_MACHINE CallByValue := ProperEAMachine CallByValue CBV_RS.

Module CEKMachine <: ABSTRACT_MACHINE.

  Import CallByValue.
  Module P := CBV_Prop.
  Import P.
  Import CBV_EAM.
  Open Scope red_scope.
  Open Scope eam_scope.

  Definition term := term.
  Definition value := valueC.
  Definition configuration := configuration.
  Definition c_init := c_init.
  Definition c_final := c_final.

  Reserved Notation " c |> c0 " (at level 70, no associativity).

  Inductive transition' : configuration -> configuration -> Prop :=
  | t_init : forall t,
      <<i t >> |> << t, nil, emptyC >>
  | t_lam  : forall t sC EC,
      << lam t, sC, EC >> |> << EC, v_lamC t sC >>
  | t_var  : forall n sC sC0 t0 EC
      (GET : nth_option (envC_to_env sC) n = Some (closureC_to_closure (pairC t0 sC0))),
      << var n, sC, EC >> |> << t0, sC0, EC >>
  | t_app  : forall t0 t1 sC EC,
      << app t0 t1, sC, EC >> |> << t0, sC, ap_rC (pairC t1 sC) :: EC >>
  | t_val  : forall v,
      << emptyC, v >> |> <<f v >>
  | t_apR  : forall t sC EC vC,
      << ap_rC (pairC t sC) :: EC, vC >> |> << t, sC, ap_lC vC :: EC >>
  | t_apL  : forall t sC EC vC,
      << ap_lC (v_lamC t sC) :: EC, vC >> |> << t, (vC : closureC) :: sC, EC >>

  where " c |> c0 " := (transition' c c0).

  Definition transition := transition'.

  Inductive trans_close : configuration -> configuration -> Prop :=
  | one_step   : forall (c0 c1 : configuration), transition c0 c1 -> trans_close c0 c1
  | multi_step : forall (c0 c1 c2 : configuration), transition c0 c1 -> trans_close c1 c2 -> trans_close c0 c2.

  Inductive eval : term -> value -> Prop :=
  | e_intro : forall (t : term) (v : value), trans_close (c_init t) (c_final v) -> eval t v.

  Hint Constructors transition' trans_close eval.
  Hint Unfold transition.
  Notation " c |>+ c0 " := (trans_close c c0) (at level 70, no associativity).
    
  Lemma trans_eam_cek : forall c c0, c → c0 -> c |> c0.
  Proof with isda.
    intros; inversion H; auto; try unfold dec_closure in DCL; try unfold dec_context in DCT.
    (* red *)
    remember (closure_red _ _ _ DCL CONTR) as UNF; clear HeqUNF; destruct UNF as [[cc [ff |]] HUNF];
    destruct t; inversion DCL; inversion TO_C; isda; subst...
      (* var *)
    destruct (CallByValue_Ref.getC _ _ _ CONTR) as [ccC HcC]; destruct ccC; destruct t; subst...
      (* app *)
    inversion CONTR; subst; inversion HUNF; destruct cC; inversion UNFOLD; subst...
    replace (ap_r (pair t2 (map closureC_to_closure sC))) with (frameC_to_frame (ap_rC (pairC t2 sC))) in H2; auto;
    inversion H1; apply envC_to_env_injective in H4; apply frameC_to_frame_injective in H2; subst...
      (* var *)
      destruct cC; inversion UNFOLD; subst...
      destruct cC; inversion CONTR.
    destruct cC; inversion UNFOLD.
    (* val *)
    remember (closure_val _ _ DCL) as UNF; clear HeqUNF; destruct UNF as [vC0 HUNF];
    destruct t; inversion DCL; isda; subst...
    replace (v_lam t (map closureC_to_closure sC)) with (valueC_to_value (v_lamC t sC)) in H3; auto;
    apply valueC_to_value_injective in H3; subst...
    (* beta *)
    remember (context_red _ _ _ _ DCT CONTR) as UNF; clear HeqUNF; destruct UNF as [[ccC [ff |]] HUNF];
      destruct f; inversion DCT; inversion TO_C; destruct v0; isda; subst; inversion CONTR; destruct cC;
        inversion UNFOLD; subst...
    destruct t0...
    inversion H1; destruct sC; inversion H3; subst.
    apply envC_to_env_injective in H5; rewrite valueC_to_closure_commutes in H4; 
      apply closureC_to_closure_injective in H4; subst...
    destruct cC; inversion UNFOLD.
    (* c-val (False) *)
    destruct fC; inversion DCT.
    (* ap_r *)
    remember (context_clo _ _ _ _ DCT) as UNF; clear HeqUNF; destruct UNF as [[ccC ff] [H_cl H_f]]; 
    destruct fC; inversion DCT; inversion TO_C; destruct cC; inversion UNFOLD; isda; subst.
    replace (ap_l (valueC_to_value vC)) with (frameC_to_frame (ap_lC vC)) in H_f; auto;
    apply frameC_to_frame_injective in H_f; apply closureC_to_closure_injective in H_cl; subst...
    destruct cC; inversion UNFOLD.
  Qed.

  Lemma trans_cek_eam : forall c c0, c |> c0 -> c → c0.
  Proof with isda.
    intros; inversion H; auto.
    (* lam *)
    assert (DCL : CBV_RS.dec_closure (closureC_to_closure (pairC (lam t) sC)) = in_val (valueC_to_value (v_lamC t sC))); auto.
    constructor 4 with _ DCL.
    remember (closure_val _ _ DCL) as UNF; clear HeqUNF; destruct UNF as [vC HUNF]; simpl; apply valueC_to_value_injective in HUNF...
    (* var *)
    assert (DCL : CBV_RS.dec_closure (closureC_to_closure (pairC (var n) sC)) = in_red (r_get n (envC_to_env sC))); auto.
    assert (CONTR : contract (r_get n (envC_to_env sC)) = Some (closureC_to_closure (pairC t0 sC0))); auto.
    replace EC with (opt_to_list None × EC); auto.
    constructor 2 with _ _ (pairC t0 sC0) DCL CONTR; auto.
    remember (closure_red _ _ _ DCL CONTR) as UNF; clear HeqUNF; destruct UNF as [[ccC [ff |]] HUNF]...
    destruct t0...
    destruct ccC; inversion HUNF; subst; unfold pairC; repeat f_equal; apply envC_to_env_injective...
    (* app *)
    assert (DCL : CBV_RS.dec_closure (closureC_to_closure (pairC (app t0 t1) sC)) = in_red (r_app t0 t1 (envC_to_env sC))); auto.
    assert (CONTR : contract (r_app t0 t1 (envC_to_env sC)) = Some (comp (closureC_to_closure (pairC t0 sC)) (closureC_to_closure (pairC t1 sC)))); auto.
    replace (ap_rC (pairC t1 sC) :: EC) with (opt_to_list (Some (ap_rC (pairC t1 sC))) × EC); auto.
    constructor 2 with _ _ (pairC t0 sC) DCL CONTR; auto.
    remember (closure_red _ _ _ DCL CONTR) as UNF; clear HeqUNF; destruct UNF as [[ccC [ff |]] HUNF];
      isda; destruct ccC; inversion HUNF; subst; unfold pairC; repeat f_equal;
        [apply envC_to_env_injective | apply frameC_to_frame_injective]...
    (* ap_r *)
    assert (DCT : CBV_RS.dec_context (frameC_to_frame (ap_rC (pairC t sC))) (valueC_to_value vC) = in_clo (closureC_to_closure (pairC t sC)) (frameC_to_frame (ap_lC vC))); auto.
    constructor 9 with _ _ (pairC t sC) DCT; auto.
    remember (context_clo _ _ _ _ DCT) as UNF; clear HeqUNF; destruct UNF as [[ccC ff] [H_cl H_f]]; 
      isda; destruct ccC; inversion H_cl; unfold pairC; repeat f_equal;
        [apply envC_to_env_injective | apply frameC_to_frame_injective]...
    (* ap_l *)
    assert (DCT : CBV_RS.dec_context (frameC_to_frame (ap_lC (v_lamC t sC))) (valueC_to_value vC) = in_red (r_beta (valueC_to_value (v_lamC t sC)) (valueC_to_value vC))); auto.
    assert (CONTR : contract (r_beta (valueC_to_value (v_lamC t sC)) (valueC_to_value vC)) = Some (closureC_to_closure (pairC t ((vC : closureC) :: sC)))).
    simpl; rewrite valueC_to_closure_commutes; auto.
    replace EC with (opt_to_list None × EC); auto.
    constructor 6 with _ _ (pairC t ((vC:closureC) :: sC)) DCT CONTR; auto.
    remember (context_red _ _ _ _ DCT CONTR) as UNF; clear HeqUNF; 
      destruct UNF as [[ccC [ff |]] HUNF]...
    destruct t...
    destruct ccC; inversion HUNF; unfold pairC; repeat f_equal; apply envC_to_env_injective...
  Qed.

  Lemma tcl_eam_cek : forall c c0, c →+ c0 -> c |>+ c0.
  Proof.
    induction 1; eauto using trans_eam_cek.
  Qed.

  Lemma tcl_cek_eam : forall c c0, c |>+ c0 -> c →+ c0.
  Proof.
    induction 1; eauto using trans_cek_eam.
  Qed.

  Lemma eval_cek : forall t v, AM.eval t v <-> eval t v.
  Proof.
    split; intro H; inversion_clear H; auto using tcl_cek_eam, tcl_eam_cek.
  Qed.

  Theorem CEKMachineCorrect : forall t (v : CallByValue.valueC), CallByValue_Eval.eval t (CallByValue.valueC_to_value v) <-> eval t v.
  Proof with auto.
    intros; rewrite eval_equiv; rewrite eval_apply_correct; apply eval_cek.
  Qed.

End CEKMachine.
