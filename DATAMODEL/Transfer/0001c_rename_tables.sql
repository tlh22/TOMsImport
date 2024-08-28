-- Change names to something more sensible ...

ALTER TABLE IF EXISTS local_authority."PM_Lines_Transfer_BayRestrictions_Current"
    RENAME TO "Bays_Transfer";

ALTER TABLE IF EXISTS local_authority."PM_Lines_Transfer_LineRestrictions_Current"
    RENAME TO "Lines_Transfer";