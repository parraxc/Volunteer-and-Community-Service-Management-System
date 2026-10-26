# Acceptance tests

Use Python 3.9+ and an installed MySQL command-line client. Run against **a disposable course server/database only**. The existing build drops `volunteer_db` and recreates the restricted `volunteer_proc` account. The suite adds reserved fixture IDs 910001–910999 and temporarily creates four accounts with project roles. It never rebuilds the database automatically and never uses real volunteer data.

## Run

1. Configure a deployment/admin login path without putting a password in a shell command:

   ```sh
   mysql_config_editor set --login-path=volunteer-admin --host=localhost --user=root --password
   ```

2. From the repository root, deliberately rebuild the disposable database:

   ```sh
   sh make_build_all.sh
   mysql --login-path=volunteer-admin < build_all.sql
   ```

   Stop if the build returns an error. Do not use `--force`. If your server is remote, this suite's automatically created localhost-only accounts will not work: use a local test server or provision an explicitly reviewed remote variant. Existing sample-account provisioning is not required by the automated suite.

3. Run the suite (use your actual socket path):

   ```sh
   python3 volunteer_DB/06_tests/run_tests.py \
     --admin-login-path=volunteer-admin --socket=/tmp/mysql.sock \
     --allow-test-writes --results=test-results.json
   ```

   Alternatively, for a local TCP server use `--host=127.0.0.1 --port=3306` instead of `--socket`. A custom client can be selected with `--mysql=/absolute/path/to/mysql`. `--admin-user=root` without a login path is for an isolated passwordless local server only. The socket/host/port options are explicit and override endpoint values in a login path.

4. A successful run prints PASS for each case, zero failures, and exits 0. Failure exits 1. JSON contains the actual server version, source commit, results, and whether the checkout had uncommitted changes. Do not label unexecuted tests passed. Rebuild before rerunning: fixture rows remain because assignment/history delete protection is intentionally not disabled.

Temporary test accounts are dropped in a finally block; their random credentials live only in temporary mode-600 configuration files. Fixture StaffMember rows remain after account cleanup. The deployment account needs CREATE USER, DROP USER, permission to grant existing project roles, full fixture DML/SELECT, and authority to kill the suite's own test connection. Those powers are not granted to operational roles.

## Coverage

- Valid entity creation and M:N skills; duplicate login, invalid role, coordinator, date, capacity, and missing-parent checks.
- SaveAssignment success, duplicate, background-check failure then verification, overlap, back-to-back shifts, capacity, cancellation/reactivation, and invalid initial status/times.
- Trigger-derived check-in/check-out status; early/late check-in, reversed/next-day checkout, contradictory status, and final-status rules.
- Correct/wrong coordinator approval, incomplete/duplicate/rounded-zero approval, immutable approved records, linked hours, and connected-user identity.
- Real Manager/Coordinator/Staff connections check reads, forbidden writes, procedure execution, audit visibility, and protected approved-hours reads.
- Every actual report SQL file runs against known fixtures, including date boundaries, zero-hour volunteers, empty shifts, cancelled/no-show attendance, and one volunteer working multiple shifts at one event.
- Audit old/new images and staff mapping; explicit rollback; KILL CONNECTION rollback; two sessions racing for capacity, overlap, and duplicate approval.
- Event/shift/coordinator-role edit protection and allowed edits on an unassigned shift.

`01_environment_and_invariants.sql` is an additional read-only diagnostic: run it as admin/Manager with `mysql --login-path=volunteer-admin < volunteer_DB/06_tests/01_environment_and_invariants.sql`. Every Violations value must be zero. The Python runner checks these invariants automatically at the end and exits nonzero for violations. Do not interpret the absence of a build error as an acceptance-test pass.

## Presentation evidence

The runner's PASS lines and JSON are evidence only after execution on MySQL. For the demo, also capture the report result tables, one 3.00-hour approval, its two audit entries, a permission denial under a real Staff login, the trigger-derived status, and a before/after transaction rollback. The killed-transaction and concurrent tests use separate actual database sessions and assert final data; they are not mock tests.

## Verification in this chat

Report SELECT logic passed 17 supplementary assertions using SQLite with only a TIMESTAMPDIFF portability adapter. This is **not MySQL integration verification**. Both downloaded MySQL 26.10.0 and 8.4.13 server binaries crashed during initialization in this restricted environment; a required system-information call was denied. No MySQL instance was initialized, and no integration/permission/concurrency PASS is claimed. Python syntax, generated build consistency, report logic, SQL schema/diagram column coverage, and rendered diagram layout were checked locally.
