# Reports, tests, and ER delivery — October 25, 2026

Baseline: public main commit `033aaf2` / FRD v1.4. The teammate's existing requirements and TDD were preserved except for a short implementation cross-reference and correcting direct schema contradictions. No GitHub push is part of this delivery.

## Deliverables

- `volunteer_DB/05_reports`: ten read-only queries and a role/filter/expected-results guide.
- `volunteer_DB/06_tests`: a standard-library Python/MySQL acceptance runner, read-only SQL invariants, and run instructions. Real separate connections exercise permissions, concurrency, approval, and killed-transaction rollback. Expected failures are checked for the correct reason rather than ignored.
- `docs/er`: physical schema and conceptual Chen diagrams in SVG, editable Graphviz/Mermaid sources, and notation guide. All nine tables and all 44 columns are represented.

## Small prerequisite fixes included

1. Distinct local variable names in SaveAssignment/ApproveHours prevent MySQL variable names from shadowing StaffID, StaffRole, VolunteerID, ShiftID, EventID, and ApprovedAt column references.
2. ApproveHours now uses defined event/coordinator variables, checks missing authorization defensively, runs under the restricted volunteer_proc definer, and updates the retained HoursApproved flag along with metadata.
3. Audit triggers use a distinct local actor variable so ChangedByStaffID is populated for a mapped user.
4. Corrected `vs.ShifID` in reactivation validation.
5. Added the missing StaffMember coordinator-role protection trigger required by FR-19/BR-33.
6. Added a composite VolunteerHours → VolunteerShift foreign key to enforce the exact assignment dependency represented by the weak entity.
7. The build generator now explicitly installs setup/tables/routines/triggers/seed/security only; reports/tests never execute during a rebuild. Removed redundant DROP/CREATE from the table fragment and regenerated build_all.sql.

These changes are included as reviewable source changes, not claims of successful MySQL execution. The suite should be run by the teammate on the working MySQL installation before submission. If additional implementation defects appear, the suite reports them instead of suppressing them.

## Validation and limits

- All ten actual report SELECTs passed 17 supplementary portable-query assertions, including empty shifts, zero totals, date bounds, DISTINCT volunteers, cancellation, skills, and audit filters.
- Python syntax and command-line help checked; complete MySQL integration suite remains unexecuted here.
- SVGs rendered and visually inspected; columns/types are generated from the updated CREATE TABLE definitions.
- Generated build checked for deterministic regeneration and exclusion of test/report SQL.
- MySQL 26.10.0 and 8.4.13 both failed initialization in this restricted environment (system-information permission denied; crash before schema creation). This is not recorded as a successful database build or test run.

## Remaining team work

Run the deliberate disposable-database build, then the automated suite and presentation demonstrations using the README. Record the actual MySQL version and results. Review the small prerequisite fixes with your teammate; commit the completed deliverables using your own account when ready.
