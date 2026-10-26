# Volunteer and Community Service Management System

CS 437 database project by Christian Parra and Prabhas Penumatsa. See Functional Requirements.md and Technical Design Document.md for scope and design.

## Build the disposable course database

Prerequisites: MySQL Community Server 8.0.16+ (with CHECK enforcement), matching MySQL client, and an administrative deployment account. Set credentials locally with mysql_config_editor. The project uses MySQL roles, procedures, triggers, and InnoDB. The actual installed version must be recorded in test evidence.

```sh
sh make_build_all.sh
mysql --login-path=volunteer-admin < build_all.sql
```

**This deliberately drops and recreates volunteer_db and recreates the restricted volunteer_proc account. Use a disposable course server.** Stop on any build error; do not use --force. The build installs fictional seed data and roles. It does not run report scripts, acceptance fixtures, or approvals. The standalone table file is a build fragment; use the generator for a complete build.

## Deliverables

- [Ten SQL reports and usage examples](volunteer_DB/05_reports/README.md)
- [Acceptance tests and execution instructions](volunteer_DB/06_tests/README.md)
- [ER diagrams and notation](docs/er/README.md)
- [Implementation fixes and verification limits](docs/COMPLETION-NOTES.md)

For report demonstrations, provision individual operational accounts and map them to StaffMember.DbUsername as in the existing sample provisioning script, using local credentials. The automated acceptance runner creates and removes its own random test accounts, so manual sample accounts are not required to run it. Fixture rows remain until a deliberate rebuild.

No MySQL integration pass is claimed in this delivery: run the acceptance suite on the working team server and save its JSON evidence before submission.
