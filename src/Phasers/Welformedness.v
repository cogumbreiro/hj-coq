
Require Import HJ.Vars.

(**
  Welformedness catpures a local property of taskviews, the relationship between
  signal-phase, wait-phase, and mode.
  It is an invariant of the various languages we defined, thus preserved by
  reduction at the taskview-level, at the phaser-level, and at the phasermap-level.
  
 *)

(** We first define the notion of welformed for taskviews. *)

Module Taskview.
  Require Import HJ.Phasers.Regmode.
  Require Import HJ.Phasers.Taskview.

(* end hide *)

  (** A welformed taskview has three possible cases:
  (i) the task has wait-capability and is ready to issue a signal,
  in which case the signal-phase and wait-phase match;
  (ii) the  task has wait-capability and has issued a signal, in which case
  the signal-phase is ahead of the wait-phase exactly one phase;
  (iii) the task is registered in signal-only mode, in which case the wait-phase
  cannot be ahead of the signal-phase.*)

  Inductive Welformed v : Prop :=
    | tv_welformed_wait_cap_eq:
      WaitCap (mode v) ->
      wait_phase v = signal_phase v ->
      Welformed v
    | tv_welformed_wait_cap_succ:
      WaitCap (mode v) ->
      S (wait_phase v) = signal_phase v ->
      Welformed v
    | tv_welformed_so:
      mode v = SIGNAL_ONLY ->
      wait_phase v <= signal_phase v ->
      Welformed v.

  Hint Constructors Welformed.

  (**
    Actually, regardless of the registration mode, the wait-phase cannot be
    greater than the signal-phase. *)

  Lemma welformed_wait_phase_le_signal_phase:
    forall v,
    Welformed v ->
    wait_phase v <= signal_phase v.
  Proof.
    intros.
    inversion H; intuition.
  Qed.

(* begin hide *)

  Lemma tv_welformed_eq:
    forall v,
    wait_phase v = signal_phase v ->
    Welformed v.
  Proof.
    intros.
    destruct (wait_cap_so_dec (mode v)); auto; intuition.
  Qed.

  Lemma tv_welformed_succ:
    forall v,
    S (wait_phase v) = signal_phase v ->
    Welformed v.
  Proof.
    intros.
    destruct (wait_cap_so_dec (mode v)); auto; intuition.
  Qed.

  Lemma welformed_inv_sw:
    forall v,
    Welformed v ->
    WaitCap (mode v) ->
    (wait_phase v = signal_phase v) \/ (S (wait_phase v) = signal_phase v).
  Proof.
    intros.
    inversion H; intuition.
    apply so_to_not_wait_cap in H1.
    contradiction.
  Qed.

  Lemma make_welformed:
    Welformed Taskview.make.
  Proof.
    intros.
    apply tv_welformed_wait_cap_eq.
    rewrite make_mode.
    auto.
    rewrite make_signal_phase.
    rewrite make_wait_phase.
    trivial.
  Qed.

  Lemma signal_preserves_welformed:
    forall v,
    Welformed v ->
    Welformed (Taskview.signal v).
  Proof.
    intros.
    inversion H.
    - apply tv_welformed_wait_cap_succ.
      rewrite signal_preserves_mode; auto.
      apply signal_wait_cap_signal_phase in H0.
      rewrite H0.
      auto using signal_preserves_wait_phase.
    - apply tv_welformed_wait_cap_succ.
      rewrite signal_preserves_mode; auto.
      apply signal_wait_cap_signal_phase in H0.
      rewrite H0.
      auto using signal_preserves_wait_phase.
    - apply tv_welformed_so.
      rewrite signal_preserves_mode; auto.
      rewrite signal_preserves_wait_phase.
      rewrite signal_so_signal_phase; auto.
  Qed.

  Lemma wait_preserves_welformed:
    forall v,
    Welformed v ->
    WaitPre v ->
    Welformed (Taskview.wait v).
  Proof.
    intros.
    destruct H0.
    inversion H.
    - assert (wait_phase v <> signal_phase v) by intuition.
      contradiction.
    - apply tv_welformed_wait_cap_eq.
      rewrite wait_preserves_mode; auto.
      rewrite wait_preserves_signal_phase.
      rewrite <- H1.
      rewrite wait_wait_phase.
      trivial.
    - apply tv_welformed_so.
      rewrite wait_preserves_mode; auto.
      rewrite wait_wait_phase.
      rewrite wait_preserves_signal_phase.
      intuition.
  Qed.

  (* end hide*)

  (** The operational semantics of taskviews preserves the property of [Welformed]. *)

  Theorem tv_reduces_preserves_welformed:
    forall v o v',
    Welformed v ->
    Reduces v o v' ->
    Welformed v'.
  Proof.
    intros.
    inversion H0;
    subst;
    auto using signal_preserves_welformed, wait_preserves_welformed.
  Qed.

  (* begin hide *)

  Lemma signal_phase_signal_inv:
    forall v,
    Welformed v ->
    signal_phase (Taskview.signal v) = signal_phase v
    \/ signal_phase (Taskview.signal v) = S (signal_phase v).
  Proof.
    intros.
    inversion H.
    - rewrite signal_wait_cap_signal_phase; auto.
    - rewrite signal_wait_cap_signal_phase; auto.
    - rewrite signal_so_signal_phase; auto.
  Qed.

  Lemma signal_phase_le_signal:
    forall v,
    Welformed v ->
    signal_phase v <= signal_phase (signal v).
  Proof.
    intros.
    apply signal_phase_signal_inv in H.
    destruct H; intuition.
  Qed.

  Lemma reduces_wait_post:
    forall v v',
    Welformed v ->
    Reduces v WAIT v' ->
    (mode v' = SIGNAL_ONLY \/ WaitCap (mode v') /\ wait_phase v' = signal_phase v').
  Proof.
    intros.
    inversion H0.
    destruct H1.
    inversion H.
    - assert (wait_phase v <> signal_phase v) by intuition.
      contradiction H4.
    - right.
      rewrite wait_preserves_signal_phase.
      rewrite wait_wait_phase.
      intuition.
    - left.
      rewrite wait_preserves_mode.
      assumption.
  Qed.

  Lemma reduces_wait_inv_wait_cap:
    forall v v',
    Welformed v ->
    WaitCap (mode v) ->
    Reduces v WAIT v' ->
    signal_phase v' = wait_phase v'.
  Proof.
    intros.
    inversion H1; subst.
    apply reduces_wait_post in H1; auto.
    destruct H1 as [R|(?,?)].
    - (* absurd case *)
      assert (WaitCap (mode (wait v))). {
        auto using wait_preserves_mode.
      }
      rewrite R in *.
      inversion H1.
    - intuition.
  Qed.

  Lemma reduces_trans_inv:
    forall x y z o,
    Welformed x ->
    WaitCap (mode x) ->
    Reduces x WAIT y ->
    Reduces y o z ->
    o = SIGNAL.
  Proof.
    intros.
    inversion H1; subst.
    inversion H2; trivial; subst.
    subst.
    apply reduces_wait_post in H1.
    {
      destruct H1 as [?|(?,?)].
      - rewrite wait_cap_rw in *.
        rewrite wait_preserves_mode in *.
        contradiction.
      - destruct H3 as [H3].
        destruct H4 as [H4].
        rewrite wait_preserves_signal_phase in *.
        rewrite H5 in *.
        assert (signal_phase x <> signal_phase x). {
          intuition.
        }
        assert (signal_phase x = signal_phase x) by auto.
        contradiction.
    }
    assumption.
  Qed.

  Lemma set_mode_preserves_welformed:
    forall v r,
    Welformed v ->
    r_le r (mode v) ->
    Welformed (set_mode v r).
  Proof.
    intros.
    remember (mode v) as r'.
    symmetry in Heqr'.
    destruct r';
    try (inversion H0;
      subst;
      rewrite <- Heqr';
      rewrite set_mode_ident;
      auto).
    inversion H.
    - auto using tv_welformed_eq.
    - auto using tv_welformed_succ.
    - rewrite Heqr' in H1.
      inversion H1.
  Qed.

(* end hide *)

End Taskview.

(** We now define the notion of welformed for phasers, which states that
  every taskview mentioned in the phaser must be also welformed. *)

Module Phaser.
  Import Taskview.
  Require Import HJ.Phasers.Phaser.

  Inductive Welformed (ph:phaser) : Prop :=
    ph_welformed_def:
      (forall t v,
        Map_TID.MapsTo t v ph ->
        Taskview.Welformed v) ->
      Welformed ph.

  (* begin hide *)

  Lemma ph_welformed_to_tv_welformed:
    forall t v ph,
    Welformed ph ->
    Map_TID.MapsTo t v ph ->
    Taskview.Welformed v.
  Proof.
    intros.
    inversion H.
    eauto.
  Qed.

  Lemma ph_signal_preserves_welformed:
    forall ph t ph',
    Welformed ph ->
    Reduces ph t SIGNAL ph' ->
    Welformed ph'.
  Proof.
    intros.
    inversion H0; subst; simpl in *.
    destruct H1 as [H1].
    apply Map_TID_Extra.in_to_mapsto in H1.
    destruct H1 as (v, Hmt).
    assert (R: signal t ph = Map_TID.add t (Taskview.signal v) ph) by auto using ph_signal_spec.
    rewrite R.
    apply ph_welformed_def.
    intros.
    destruct (TID.eq_dec t0 t).
    + subst.
      remember (Taskview.signal _) as v'.
      assert (v0 = v'). {
        assert (Map_TID.MapsTo t v' (Map_TID.add t v' ph)) by auto using Map_TID.add_1.
        eauto using Map_TID_Facts.MapsTo_fun.
      }
      subst.
      assert (Taskview.Welformed v) by eauto using ph_welformed_to_tv_welformed.
      auto using signal_preserves_welformed.
    + apply Map_TID_Facts.add_neq_mapsto_iff in H1; auto with *.
      eauto using ph_welformed_to_tv_welformed.
  Qed.

  Lemma ph_wait_preserves_welformed:
    forall ph t ph',
    Welformed ph ->
    Reduces ph t WAIT ph' ->
    Welformed ph'.
  Proof.
    intros.
    inversion H0; subst; simpl in *.
    destruct H1.
    assert (R: wait t ph = Map_TID.add t (Taskview.wait v) ph) by auto using ph_wait_spec.
    rewrite R; clear R.
    apply ph_welformed_def.
    intros.
    destruct (TID.eq_dec t0 t).
    + subst.
      remember (Taskview.wait _) as v'.
      assert (v0 = v'). {
        assert (Map_TID.MapsTo t v' (Map_TID.add t v' ph)) by auto using Map_TID.add_1.
        eauto using Map_TID_Facts.MapsTo_fun.
      }
      subst.
      assert (Taskview.Welformed v) by eauto using ph_welformed_to_tv_welformed.
      auto using wait_preserves_welformed.
    + apply Map_TID_Facts.add_neq_mapsto_iff in H4; auto with *.
      eauto using ph_welformed_to_tv_welformed.
  Qed.

  Lemma ph_drop_preserves_welformed:
    forall ph t ph',
    Welformed ph ->
    Reduces ph t DROP ph' ->
    Welformed ph'.
  Proof.
    intros.
    inversion H0; subst; simpl in *.
    unfold drop in *.
    destruct H1.
    apply ph_welformed_def.
    intros.
    rewrite Map_TID_Facts.remove_mapsto_iff in H2.
    destruct H2.
    eauto using ph_welformed_to_tv_welformed.
  Qed.

  Lemma ph_register_preserves_welformed:
    forall ph t r ph',
    Welformed ph ->
    Reduces ph t (REGISTER r) ph' ->
    Welformed ph'.
  Proof.
    intros.
    inversion H0; subst; simpl in *.
    destruct H1.
    assert (R:= H0).
    apply ph_register_spec with (v:=v) in R; auto.
    rewrite R; clear R.
    apply ph_welformed_def.
    intros.
    destruct (TID.eq_dec t0 t).
    + subst.
      rewrite Map_TID_Facts.add_mapsto_iff in H4.
      destruct H4 as [(?,?)|(?,?)].
      * subst.
        contradiction H1.
        eauto using Map_TID_Extra.mapsto_to_in.
      * eauto using ph_welformed_to_tv_welformed.
    + rewrite Map_TID_Facts.add_mapsto_iff in H4.
      destruct H4 as [(?,?)|(?,?)].
      * subst.
        eauto using set_mode_preserves_welformed, ph_welformed_to_tv_welformed.
      * eauto using ph_welformed_to_tv_welformed.
  Qed.

  (* end hide *)

  Lemma ph_reduces_preserves_welformed:
    forall ph t o ph',
    Welformed ph ->
    Reduces ph t o ph' ->
    Welformed ph'.
  Proof.
    intros.
    destruct o; subst; inversion H; simpl in *.
    - eauto using
      ph_signal_preserves_welformed.
    - eauto using
      ph_wait_preserves_welformed.
    - eauto using 
      ph_drop_preserves_welformed.
    - eauto using ph_register_preserves_welformed.
  Qed.

End Phaser.

Module Phasermap.
  Require Import HJ.Phasers.Lang.
  Import Phaser.

  Inductive Welformed (m:phasermap) : Prop :=
    pm_welformed_def:
      (forall p ph,
        Map_PHID.MapsTo p ph m ->
        Phaser.Welformed ph) ->
      Welformed m.
(*
  Lemma ph_reduces_preserves_welformed:
    forall m t o m',
    Welformed ph ->
    Reduction m t o m' ->
    Welformed m'.
  Proof.
*)
End Phasermap.
