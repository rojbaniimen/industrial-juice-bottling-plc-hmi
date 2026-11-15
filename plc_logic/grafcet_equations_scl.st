(* ============================================================================
 * Project   : Automated Fruit Juice Bottling & Mixing Station (TIA Portal V17)
 * PLC / HMI : Siemens SIMATIC S7-1200 (192.168.0.1) <-> TP700 Comfort (192.168.0.2)
 * Authors   : Imen Rojbani, Eya Yousfi, Wiem Abidi, Youssef Rebah (ENSIT - 2GEC)
 * ============================================================================ *)

REGION GRAFCET_STEP_EQUATIONS
    (* Step X0: Initial Idle State *)
    #Set_X0   := #X7 AND #be;
    #Reset_X0 := #X0 AND #dcy AND #pb;

    (* Step X1: Conveyor Belt Advance (KM1) *)
    #Set_X1   := #X0 AND #dcy AND #pb;
    #Reset_X1 := (#X1 AND #ja) OR (#X1 AND #jo);

    (* Step X2: Apple Juice Dosing Branch (E1 - 30s) *)
    #Set_X2   := #X1 AND #ja;
    #Reset_X2 := #X3 OR (#X2 AND #T_X2_30s.Q);

    (* Step X8: Orange Juice Dosing Branch (E2 - 30s) *)
    #Set_X8   := #X1 AND #jo;
    #Reset_X8 := #X3 OR (#X8 AND #T_X8_30s.Q);

    (* Step X3 & X4: Water Dosing & Level Control (E3 - 30s) *)
    #Set_X3   := (#X2 AND #T_X2_30s.Q) OR (#X8 AND #T_X8_30s.Q);
    #Reset_X3 := #X4 OR (#X3 AND #T_X4_30s.Q);

    (* Step X5: Timed Agitator Mixing Phase (KM - 30s) *)
    #Set_X5   := #X4 AND #je;
    #Reset_X5 := #X6 OR (#X5 AND #T_Mix.Q);

    (* Step X6: Labeling Station Detection (pbe) *)
    #Set_X6   := #X5 AND #T_Mix.Q;
    #Reset_X6 := #X6 AND #pbe;

    (* Step X7: Final Bottle Evacuation (be) *)
    #Set_X7   := #X6 AND #pbe;
    #Reset_X7 := #X7 AND #be;
END_REGION

REGION ACTUATORS_AND_DIAGNOSTICS
    (* Conveyor Motor (KM1) with Jam Fault Interlock *)
    #KM1 := (#X1 OR #X6) AND NOT #Defaut_Bouteille;

    (* Selective Recipe Valves & Mixer Motor *)
    #E1 := #X2;                                      (* Apple Juice Valve *)
    #E2 := #X8;                                      (* Orange Juice Valve *)
    #E3 := #X3;                                      (* Water Valve *)
    #KM := #X5 AND NOT #T_Mix.Q;                     (* Mixer Motor *)

    (* Network 11: Bottle Jam Watchdog Timer (> 10s on Conveyor) *)
    #T_Fail(IN := #X1, PT := T#10s);
    IF #T_Fail.Q THEN
        #Defaut_Bouteille := TRUE;
    END_IF;

    (* Network 12: Production Lot Counter (CTU - Target 500 Bottles) *)
    #C_Cycle(CU := #X7, R := #HMI_Counter_Reset, PV := 1000);
    #H_Batch_Done := (#C_Cycle.CV >= 500);
END_REGION
