#!/usr/bin/env python3
"""Integration/role/report/concurrency tests. Standard-library Python + MySQL CLI.
Run only against the disposable volunteer_db built from this checkout.
Expected SQL errors are checked individually; --force is never used.
"""
import argparse
import concurrent.futures
import decimal
import json
import os
from pathlib import Path
import secrets
import subprocess
import tempfile
import threading
import time

ROOT = Path(__file__).resolve().parents[2]
BASE = 910000

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--mysql', default='mysql', help='Path to MySQL client executable')
    p.add_argument('--admin-login-path', help='mysql_config_editor login path for a deployment account')
    p.add_argument('--admin-user', default='root', help='Used when --admin-login-path is absent')
    p.add_argument('--socket', help='Local test server socket; overrides TCP host/port')
    p.add_argument('--host', default='127.0.0.1')
    p.add_argument('--port', default='3306')
    p.add_argument('--allow-test-writes', action='store_true', help='Confirm this is a disposable course database')
    p.add_argument('--results', help='Write JSON evidence (contains no passwords)')
    args = p.parse_args()
    if not args.allow_test_writes:
        p.error('Pass --allow-test-writes only for a disposable volunteer_db; fixture rows remain until rebuild.')
    endpoint = ['--protocol=SOCKET', '--socket='+args.socket] if args.socket else [
        '--protocol=TCP', '--host='+args.host, '--port='+args.port]
    admin = ([args.mysql, '--login-path='+args.admin_login_path] if args.admin_login_path else
             [args.mysql, '--no-defaults', '--user='+args.admin_user])
    common = endpoint + ['--default-character-set=utf8mb4', '--batch', '--raw',
                         '--skip-column-names', '--connect-timeout=10', '--unbuffered',
                         '--init-command=SET SESSION time_zone="+00:00"', 'volunteer_db']
    commands = {'admin': admin + common}
    results = []
    users = []

    def sql(statement, who='admin', check=True):
        cp = subprocess.run(commands[who], input=statement, text=True, capture_output=True, timeout=30)
        if check and cp.returncode:
            raise AssertionError(cp.stderr.strip())
        return cp

    def rows(statement, who='admin'):
        return [line.split('\t') for line in sql(statement, who).stdout.splitlines() if line]

    def scalar(statement, who='admin'):
        values = rows(statement, who)
        if not values:
            raise AssertionError('Expected a scalar result')
        return values[-1][0]

    def eq(actual, expected):
        if actual != expected:
            raise AssertionError(f'Expected {expected!r}, got {actual!r}')

    def reject(statement, match, who='admin'):
        cp = sql(statement, who, check=False)
        if cp.returncode == 0:
            raise AssertionError('Invalid operation was accepted')
        if match.lower() not in cp.stderr.lower():
            raise AssertionError(f'Wrong rejection; expected {match!r}: {cp.stderr.strip()}')

    def case(name, fn):
        try:
            fn()
            print('PASS', name, flush=True)
            results.append({'test': name, 'status': 'PASS'})
        except Exception as exc:
            print('FAIL', name, str(exc), flush=True)
            results.append({'test': name, 'status': 'FAIL', 'detail': str(exc)})

    def assign(v, s, status='NULL', cin='NULL', cout='NULL', who='coord1'):
        return sql(f'CALL SaveAssignment({BASE+v},{BASE+s},{status},{cin},{cout});', who)

    def call(v, s, status='NULL', cin='NULL', cout='NULL'):
        return f'CALL SaveAssignment({BASE+v},{BASE+s},{status},{cin},{cout});'

    def approve(v, s, who='coord1'):
        return sql(f'CALL ApproveHours({BASE+v},{BASE+s});', who)

    def report(n, settings='', who='admin'):
        files = sorted((ROOT/'volunteer_DB/05_reports').glob(f'{n:02}_*.sql'))
        if len(files) != 1:
            raise AssertionError('Missing or ambiguous report file')
        return rows(settings+'\n'+files[0].read_text(), who)

    def filtered(n, settings='', who='admin'):
        return [row for row in report(n, settings, who) if row[0].isdigit() and int(row[0]) > BASE]

    def assert_count(query, expected):
        eq(int(scalar(query)), expected)

    def race(statements, lock_sql, expected_success=1):
        # Hold the shared serialization row while both calls start in real sessions.
        blocker = subprocess.Popen(commands['admin'], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, text=True)
        blocker.stdin.write('START TRANSACTION; '+lock_sql+"; SELECT 'LOCK_READY'; DO SLEEP(1.5); COMMIT;\n")
        blocker.stdin.close()
        while True:
            line = blocker.stdout.readline()
            if 'LOCK_READY' in line:
                break
            if not line:
                raise AssertionError('Could not acquire race fixture lock: '+blocker.stderr.read())
        barrier = threading.Barrier(len(statements))
        def request(item):
            who, statement = item
            barrier.wait(timeout=5)
            return sql(statement, who, check=False)
        try:
            with concurrent.futures.ThreadPoolExecutor(max_workers=len(statements)) as pool:
                out = list(pool.map(request, statements))
            eq(sum(cp.returncode == 0 for cp in out), expected_success)
            return out
        finally:
            blocker.wait(timeout=10)

    with tempfile.TemporaryDirectory(prefix='volunteer-tests-') as temp:
        try:
            version = scalar('SELECT VERSION();')
            print('Server:', version, flush=True)
            if int(scalar(f'SELECT COUNT(*) FROM Volunteer WHERE VolunteerID BETWEEN {BASE} AND {BASE+999};')):
                raise AssertionError('Fixture IDs already exist; rebuild the disposable database before rerunning.')
            # Unique short account names; accounts are removed in finally. Secrets live only in mode-600 files.
            tag = secrets.token_hex(3)
            for who, role in [('manager','manager_role'),('coord1','coordinator_role'),
                              ('coord2','coordinator_role'),('staff','staff_role')]:
                user = f'vt_{who}_{tag}'
                password = secrets.token_hex(24)
                sql(f"CREATE USER '{user}'@'localhost' IDENTIFIED BY '{password}';")
                users.append(user)
                sql(f"GRANT '{role}' TO '{user}'@'localhost'; SET DEFAULT ROLE '{role}' TO '{user}'@'localhost';")
                config = Path(temp)/f'{who}.cnf'
                config.write_text(f'[client]\nuser={user}\npassword={password}\n')
                os.chmod(config, 0o600)
                commands[who] = [args.mysql, '--defaults-file='+str(config), '--no-login-paths'] + common
            names = {who: scalar('SELECT SUBSTRING_INDEX(USER(),"@",1);',who)
                     for who in ['manager','coord1','coord2','staff']}
            sql(f"""
                INSERT INTO StaffMember VALUES
                  ({BASE+1},'Test Manager','Manager','{names['manager']}'),
                  ({BASE+2},'Test Coordinator One','Event Coordinator','{names['coord1']}'),
                  ({BASE+3},'Test Coordinator Two','Event Coordinator','{names['coord2']}'),
                  ({BASE+4},'Test Reader','Staff Member','{names['staff']}');
                INSERT INTO Event VALUES
                  ({BASE+1},'Fixture Event One','2026-11-01',{BASE+2}),
                  ({BASE+2},'Fixture Other Coordinator','2026-11-02',{BASE+3}),
                  ({BASE+3},'Fixture Empty Event','2026-11-03',{BASE+2});
            """)
            for i in range(1,31):
                sql(f"INSERT INTO Volunteer VALUES ({BASE+i},'Fixture Volunteer {i:02}','555-TEST','fixture{i}@example.invalid',{0 if i==6 else 1});")
            shifts = [(1,1,1,12,15),(2,1,4,14,17),(3,1,4,15,17),(4,1,4,8,10),
                      (5,1,4,10,12),(6,1,4,17,19),(7,1,1,8,10),(8,1,4,12,15),
                      (9,2,4,12,15),(10,1,4,19,21),(11,1,1,12,15),(12,1,4,12,15)]
            for sid,eid,cap,start,end in shifts:
                day='2026-11-02' if eid==2 else '2026-11-01'
                sql(f"INSERT INTO Shift VALUES ({BASE+sid},{BASE+eid},'Fixture Shift {sid}',{cap},'{day} {start:02}:00:00','{day} {end:02}:00:00');")
            sql(f"INSERT INTO Skill VALUES ({BASE+1},'Fixture Skill A','Test skill'),({BASE+2},'Fixture Skill B','Second test skill'); INSERT INTO VolunteerSkill VALUES ({BASE+1},{BASE+1}),({BASE+1},{BASE+2}),({BASE+2},{BASE+1});")

            case('FR-01..07 fixture entities and M:N skill memberships', lambda: assert_count(f'SELECT COUNT(*) FROM VolunteerSkill WHERE VolunteerID={BASE+1};',2))
            case('BR-05 invalid event coordinator rejected',lambda: reject(f"INSERT INTO Event VALUES ({BASE+99},'Invalid','2026-11-01',{BASE+1});",'coordinator'))
            case('BR-06 invalid staff role rejected',lambda: reject(f"UPDATE StaffMember SET StaffRole='Invalid' WHERE StaffID={BASE+4};",'chk_staff_role'))
            case('BR-07 capacity and chronological constraints',lambda: reject(f'UPDATE Shift SET Capacity=0 WHERE ShiftID={BASE+12};','chk_shift_capacity'))
            case('BR-08 shift outside event date rejected',lambda: reject(f"UPDATE Shift SET EndDateTime='2026-11-02 15:00:00' WHERE ShiftID={BASE+12};",'event date'))
            case('BR-03 missing parent event rejected',lambda: reject(f"INSERT INTO Shift VALUES ({BASE+99},{BASE+999},'Orphan',1,'2026-11-01 12:00:00','2026-11-01 15:00:00');",'foreign key constraint'))
            case('hours require exact assignment',lambda: reject(f'INSERT INTO VolunteerHours VALUES ({BASE+30},{BASE+12},1);','foreign key constraint'))
            case('BR-26 duplicate login rejected',lambda: reject(f"INSERT INTO StaffMember VALUES ({BASE+99},'Duplicate','Manager','{names['manager']}');",'Duplicate'))
            case('FR-09 unverified volunteer rejected',lambda: reject(call(6,1),'background','coord1'))
            case('BR-37 nonexistent volunteer rejected',lambda: reject(call(999,1),'Volunteer not found','coord1'))
            case('BR-37 nonexistent shift rejected',lambda: reject(call(1,999),'Shift not found','coord1'))
            case('BR-34 new attendance rejected',lambda: reject(call(3,8,'NULL',"'2026-11-01 12:00:00'"),'new assignment','coord1'))
            case('FR-05 assignment succeeds through procedure',lambda: assign(1,1))
            case('FR-08 duplicate assignment rejected',lambda: reject(call(1,1),'already exists','coord1'))
            case('FR-11 full shift rejected',lambda: reject(call(2,1),'capacity','coord1'))
            case('FR-10 overlap rejected',lambda: reject(call(1,2),'overlap','coord1'))
            case('FR-10 back-to-back accepted',lambda: assign(1,3))
            case('BR-34 new non-Scheduled assignment rejected',lambda: reject(call(3,8,"'No-Show'"),'new assignment','coord1'))
            case('BR-20 cancel scheduled assignment',lambda: assign(1,1,"'Cancelled'"))
            case('FR-11 cancellation frees capacity',lambda: assign(2,1))
            case('BR-20 reactivation on full shift rejected',lambda: reject(call(1,1,"'Scheduled'"),'capacity','coord1'))
            case('BR-20 cancel replacement',lambda: assign(2,1,"'Cancelled'"))
            case('BR-20 reactivation with free capacity succeeds',lambda: assign(1,1,"'Scheduled'"))
            case('FR-09 verify volunteer then assign',lambda: (sql(f'UPDATE Volunteer SET BackgroundCheck=1 WHERE VolunteerID={BASE+6};','coord1'),assign(6,4)))
            case('BR-17 early check-in rejected',lambda: reject(call(1,1,'NULL',"'2026-11-01 11:55:00'"),'within the shift','coord1'))
            case('BR-17 check-in at end rejected',lambda: reject(call(1,1,'NULL',"'2026-11-01 15:00:00'"),'within the shift','coord1'))
            case('FR-17 check-in derives In-Progress',lambda: (assign(1,1,'NULL',"'2026-11-01 12:00:00'"),eq(scalar(f'SELECT Status FROM VolunteerShift WHERE VolunteerID={BASE+1} AND ShiftID={BASE+1};'),'In-Progress')))
            case('BR-18 reversed checkout rejected',lambda: reject(call(1,1,'NULL','NULL',"'2026-11-01 11:00:00'"),'chk_vshift_checkout','coord1'))
            case('BR-17 next-day checkout rejected',lambda: reject(call(1,1,'NULL','NULL',"'2026-11-02 15:00:00'"),'event date','coord1'))
            case('FR-17 checkout derives Completed',lambda: (assign(1,1,'NULL','NULL',"'2026-11-01 15:00:00'"),eq(scalar(f'SELECT Status FROM VolunteerShift WHERE VolunteerID={BASE+1} AND ShiftID={BASE+1};'),'Completed')))
            case('BR-20 completed assignment cannot cancel',lambda: reject(call(1,1,"'Cancelled'"),'status change','coord1'))
            case('BR-16 completed requires times',lambda: reject(call(6,4,"'Completed'"),'chk_vshift_status_time','coord1'))
            case('FR-17 contradictory status rejected',lambda: reject(call(6,4,"'No-Show'","'2026-11-01 08:00:00'"),'contradicts','coord1'))
            case('FR-17 both times derive Completed',lambda: assign(6,4,'NULL',"'2026-11-01 08:00:00'","'2026-11-01 10:00:00'"))
            case('FR-14 wrong coordinator cannot approve',lambda: reject(f'CALL ApproveHours({BASE+1},{BASE+1});','assigned Event Coordinator','coord2'))
            case('FR-12 incomplete assignment cannot approve',lambda: reject(f'CALL ApproveHours({BASE+1},{BASE+3});','Completed','coord1'))
            case('FR-13 approve 3.00 hours',lambda: (approve(1,1),eq(decimal.Decimal(scalar(f'SELECT HoursWorked FROM VolunteerHours WHERE VolunteerID={BASE+1} AND ShiftID={BASE+1};')),decimal.Decimal('3.00'))))
            case('BR-22 duplicate approval rejected',lambda: reject(f'CALL ApproveHours({BASE+1},{BASE+1});','already approved','coord1'))
            case('BR-24 approved attendance immutable',lambda: reject(call(1,1,'NULL','NULL',"'2026-11-01 14:30:00'"),'approved','coord1'))
            case('approval flag agrees with metadata',lambda: eq(scalar(f'SELECT HoursApproved FROM VolunteerShift WHERE VolunteerID={BASE+1} AND ShiftID={BASE+1};'),'1'))
            case('BR-28 approver comes from actual account',lambda: eq(scalar(f'SELECT ApprovedBy FROM VolunteerShift WHERE VolunteerID={BASE+1} AND ShiftID={BASE+1};'),str(BASE+2)))
            case('BR-19 assignment DELETE blocked by trigger',lambda: reject(f'DELETE FROM VolunteerShift WHERE VolunteerID={BASE+1} AND ShiftID={BASE+3};','prohibited'))
            case('BR-36 hours UPDATE blocked by trigger',lambda: reject(f'UPDATE VolunteerHours SET HoursWorked=1 WHERE VolunteerID={BASE+1} AND ShiftID={BASE+1};','prohibited'))
            case('BR-36 hours DELETE blocked by trigger',lambda: reject(f'DELETE FROM VolunteerHours WHERE VolunteerID={BASE+1} AND ShiftID={BASE+1};','prohibited'))
            case('BR-30 audit UPDATE blocked by trigger',lambda: reject(f"UPDATE AuditLog SET RecordId='x' WHERE TableName='Volunteer' AND RecordId='VolunteerID={BASE+1}';",'prohibited'))
            case('BR-30 audit DELETE blocked by trigger',lambda: reject(f"DELETE FROM AuditLog WHERE TableName='Volunteer' AND RecordId='VolunteerID={BASE+1}';",'prohibited'))
            case('FR-19 event date immutable with shifts',lambda: reject(f"UPDATE Event SET EventDate='2026-11-04' WHERE EventID={BASE+1};",'once'))
            case('FR-19 shift capacity immutable with assignments',lambda: reject(f'UPDATE Shift SET Capacity=8 WHERE ShiftID={BASE+1};','once'))
            case('FR-19 coordinator role protected',lambda: reject(f"UPDATE StaffMember SET StaffRole='Staff Member' WHERE StaffID={BASE+2};",'coordinates'))
            case('FR-19 empty shift edits allowed',lambda: sql(f'UPDATE Shift SET Capacity=8 WHERE ShiftID={BASE+12};','coord1'))
            case('FR-15 staff can read volunteer data',lambda: eq(scalar(f'SELECT VolunteerName FROM Volunteer WHERE VolunteerID={BASE+1};','staff'),'Fixture Volunteer 01'))
            for name,statement,who in [
                ('staff write',f'UPDATE Volunteer SET BackgroundCheck=0 WHERE VolunteerID={BASE+1};','staff'),
                ('coordinator event write',f"UPDATE Event SET EventName='x' WHERE EventID={BASE+1};",'coord1'),
                ('direct assignment write',f"UPDATE VolunteerShift SET Status='Cancelled' WHERE VolunteerID={BASE+1} AND ShiftID={BASE+3};",'coord1'),
                ('direct hours insert',f'INSERT INTO VolunteerHours VALUES ({BASE+1},{BASE+3},2);','coord1'),
                ('manager approval',f'CALL ApproveHours({BASE+1},{BASE+3});','manager'),
                ('manager assignment',call(3,8),'manager'),
                ('staff approved-hours read','SELECT * FROM VolunteerHours;','staff'),
                ('coordinator audit read','SELECT * FROM AuditLog;','coord1'),
                ('staff delete',f'DELETE FROM Volunteer WHERE VolunteerID={BASE+30};','staff')]:
                case('FR-15 denied '+name,lambda q=statement,w=who: reject(q,'denied',w))

            def audit():
                entries=rows(f"SELECT Operation,ChangedByStaffID,JSON_EXTRACT(OldValues,'$.BackgroundCheck'),JSON_EXTRACT(NewValues,'$.BackgroundCheck') FROM AuditLog WHERE TableName='Volunteer' AND RecordId='VolunteerID={BASE+6}' AND Operation='UPDATE';")
                if not any(row[1:]==[str(BASE+2),'0','1'] for row in entries):
                    raise AssertionError('Missing mapped actor and old/new background values: '+str(entries))
                assert_count(f"SELECT COUNT(*) FROM AuditLog WHERE TableName='VolunteerHours' AND RecordId='VolunteerID={BASE+1};ShiftID={BASE+1}';",1)
            case('FR-16 mapped actor and audit before/after images',audit)
            def rollback():
                before=scalar(f"SELECT COUNT(*) FROM AuditLog WHERE TableName='Volunteer' AND RecordId='VolunteerID={BASE+30}';")
                sql(f"START TRANSACTION; UPDATE Volunteer SET VolunteerName='ROLLBACK_MARK' WHERE VolunteerID={BASE+30}; ROLLBACK;")
                eq(scalar(f'SELECT VolunteerName FROM Volunteer WHERE VolunteerID={BASE+30};'),'Fixture Volunteer 30')
                eq(scalar(f"SELECT COUNT(*) FROM AuditLog WHERE TableName='Volunteer' AND RecordId='VolunteerID={BASE+30}';"),before)
            case('transaction rollback removes data and audit together',rollback)
            # Report fixtures: same volunteer works two approved shifts at one event.
            assign(1,3,'NULL',"'2026-11-01 15:00:00'","'2026-11-01 17:00:00'")
            approve(1,3)
            assign(3,8); assign(3,8,"'No-Show'")
            case('BR-20 No-Show is final',lambda: reject(call(3,8,"'Scheduled'"),'status change','coord1'))
            assign(4,8); assign(4,8,"'Cancelled'")
            assign(5,8); assign(5,8,'NULL',"'2026-11-01 12:00:00'","'2026-11-01 15:00:00'")
            assign(8,6); assign(8,6,'NULL',"'2026-11-01 17:00:00'","'2026-11-01 17:00:10'")
            case('BR-22 rounded-zero approval rolled back',lambda: reject(f'CALL ApproveHours({BASE+8},{BASE+6});','too short','coord1'))
            case('failed approval leaves no hours or metadata',lambda: (assert_count(f'SELECT COUNT(*) FROM VolunteerHours WHERE VolunteerID={BASE+8} AND ShiftID={BASE+6};',0),eq(scalar(f'SELECT ApprovedAt IS NULL FROM VolunteerShift WHERE VolunteerID={BASE+8} AND ShiftID={BASE+6};'),'1')))
            case('RQ-01 directory includes all fixture volunteers',lambda: eq(len(filtered(1,who='staff')),30))
            def roster():
                out=report(2,f'SET @report_shift_id={BASE+8},@report_event_id=NULL;','staff')
                eq(sorted(int(row[4]) for row in out),[BASE+3,BASE+5])
            case('RQ-02 roster filters cancelled rows',roster)
            def capacity():
                out=report(3,f'SET @report_event_id={BASE+1};','staff')
                empty=next(row for row in out if row[0]==str(BASE+12))
                eq(empty[-2:],['0','8'])
                full=next(row for row in out if row[0]==str(BASE+1))
                eq(full[-2:],['1','0'])
            case('RQ-03 empty and full capacities',capacity)
            def pending():
                out=report(4,f'SET @report_coordinator_id={BASE+2};','coord1')
                keys={(row[3],row[5]) for row in out}
                if (str(BASE+1),str(BASE+1)) in keys or (str(BASE+8),str(BASE+5)) not in keys:
                    raise AssertionError('Pending/approved distinction incorrect')
            case('RQ-04 pending excludes approved hours',pending)
            def summary():
                out=report(5,"SET @report_start_date='2026-11-01',@report_end_date='2026-11-01';",'coord1')
                values={row[0]:decimal.Decimal(row[2]) for row in out}
                eq(values[str(BASE+1)],decimal.Decimal('5.00'))
                eq(values[str(BASE+30)],decimal.Decimal('0'))
                outside=report(5,"SET @report_start_date='2026-11-02',@report_end_date='2026-11-02';",'coord1')
                eq(next(decimal.Decimal(row[2]) for row in outside if row[0]==str(BASE+1)),decimal.Decimal('0'))
            case('RQ-05 inclusive date range and zero-hour volunteers',summary)
            case('RQ-06 distinct volunteer across two shifts',lambda: eq(report(6,f'SET @report_event_id={BASE+1};','coord1')[0][-2:],['1','5.00']))
            case('RQ-07 skill search handles M:N',lambda: eq(sorted(row[0] for row in report(7,f'SET @report_skill_code={BASE+1};','staff')),[str(BASE+1),str(BASE+2)]))
            sql(f'UPDATE Volunteer SET BackgroundCheck=0 WHERE VolunteerID={BASE+6};','coord1')
            case('RQ-08 only unverified volunteers',lambda: eq([row[0] for row in filtered(8,who='staff')],[str(BASE+6)]))
            case('RQ-09 attendance retains No-Show and Cancelled',lambda: eq(sorted(row[-1] for row in report(9,f'SET @report_event_id=NULL,@report_shift_id={BASE+8};','staff')),['Cancelled','Completed','No-Show']))
            def audit_report():
                out=report(10,f"SET @report_table='Volunteer',@report_record_id='VolunteerID={BASE+6}',@report_staff_id={BASE+2},@report_audit_start=NULL,@report_audit_end=NULL;",'manager')
                if not out or any(row[3]!=str(BASE+2) for row in out):
                    raise AssertionError('Audit filters/identity mismatch')
                eq([int(row[0]) for row in out],sorted([int(row[0]) for row in out],reverse=True))
            case('RQ-10 manager audit filtering and ordering',audit_report)
            case('RQ-10 coordinator cannot execute audit report',lambda: reject((ROOT/'volunteer_DB/05_reports/10_audit_log.sql').read_text(),'denied','coord1'))
            def capacity_race():
                outcomes=race([('coord1',call(10,7)),('coord1',call(11,7))],f'SELECT ShiftID FROM Shift WHERE ShiftID={BASE+7} FOR UPDATE')
                if not any('capacity' in cp.stderr.lower() for cp in outcomes if cp.returncode):
                    raise AssertionError('Losing request failed for a reason other than capacity')
                assert_count(f"SELECT COUNT(*) FROM VolunteerShift WHERE ShiftID={BASE+7} AND Status<>'Cancelled';",1)
            case('FR-18 two sessions contend for final capacity slot',capacity_race)
            def overlap_race():
                outcomes=race([('coord1',call(12,2)),('coord1',call(12,8))],f'SELECT VolunteerID FROM Volunteer WHERE VolunteerID={BASE+12} FOR UPDATE')
                if not any('overlap' in cp.stderr.lower() for cp in outcomes if cp.returncode):
                    raise AssertionError('Losing request failed for a reason other than overlap')
                assert_count(f'SELECT COUNT(*) FROM VolunteerShift WHERE VolunteerID={BASE+12};',1)
            case('FR-18 two sessions contend for overlapping assignments',overlap_race)
            def approval_race():
                outcomes=race([('coord1',f'CALL ApproveHours({BASE+5},{BASE+8});')]*2,f'SELECT VolunteerID FROM Volunteer WHERE VolunteerID={BASE+5} FOR UPDATE')
                if not any('already approved' in cp.stderr.lower() for cp in outcomes if cp.returncode):
                    raise AssertionError('Losing request failed for a reason other than duplicate approval')
                assert_count(f'SELECT COUNT(*) FROM VolunteerHours WHERE VolunteerID={BASE+5} AND ShiftID={BASE+8};',1)
            case('FR-18 simultaneous approval creates one hours record',approval_race)
            def killed_transaction():
                before=scalar(f"SELECT COUNT(*) FROM AuditLog WHERE TableName='Volunteer' AND RecordId='VolunteerID={BASE+29}';")
                victim=subprocess.Popen(commands['admin'],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
                try:
                    victim.stdin.write(f"START TRANSACTION; UPDATE Volunteer SET VolunteerName='KILL_MARK' WHERE VolunteerID={BASE+29}; SELECT CONCAT('VICTIM=',CONNECTION_ID()); DO SLEEP(20); COMMIT;\n")
                    victim.stdin.close()
                    while True:
                        line=victim.stdout.readline().strip()
                        if line.startswith('VICTIM='):
                            connection=int(line.split('=')[1]);break
                        if not line:
                            raise AssertionError('Victim session failed before readiness: '+victim.stderr.read())
                    sql(f'KILL CONNECTION {connection};')
                    victim.wait(timeout=10)
                    eq(scalar(f'SELECT VolunteerName FROM Volunteer WHERE VolunteerID={BASE+29};'),'Fixture Volunteer 29')
                    eq(scalar(f"SELECT COUNT(*) FROM AuditLog WHERE TableName='Volunteer' AND RecordId='VolunteerID={BASE+29}';"),before)
                finally:
                    if victim.poll() is None:
                        victim.terminate();victim.wait(timeout=5)
            case('killed transaction rolls back data and audit',killed_transaction)
            def final_invariants():
                text=(ROOT/'volunteer_DB/06_tests/01_environment_and_invariants.sql').read_text()
                # Execute the exact diagnostic queries after the environment preamble.
                body=text.split('-- Every Violations')[1]
                body='-- Every Violations'+body
                for row in rows(body):
                    eq(int(row[1]),0)
            case('final global integrity invariants',final_invariants)
        except Exception as exc:
            results.append({'test':'suite setup/execution','status':'FAIL','detail':str(exc)})
            print('FAIL suite setup/execution:',str(exc),flush=True)
        finally:
            for user in users:
                try:
                    sql(f"DROP USER IF EXISTS '{user}'@'localhost';")
                except Exception as exc:
                    results.append({'test':'temporary account cleanup','status':'FAIL','detail':str(exc)})
            passed=sum(item['status']=='PASS' for item in results)
            failed=len(results)-passed
            print(f'RESULT: {passed} passed; {failed} failed. Fixture rows remain until database rebuild.',flush=True)
            if args.results:
                Path(args.results).write_text(json.dumps({'server_version':locals().get('version','unknown'),
                    'source_commit':subprocess.run(['git','rev-parse','HEAD'],cwd=ROOT,text=True,capture_output=True).stdout.strip(),
                    'working_tree_dirty':bool(subprocess.run(['git','status','--porcelain'],cwd=ROOT,text=True,capture_output=True).stdout.strip()),
                    'note':'Fixture rows remain until rebuild; results describe the tested checkout, including any working-tree changes.',
                    'passed':passed,'failed':failed,'tests':results},indent=2)+'\n')
            return 1 if failed else 0

if __name__=='__main__':
    raise SystemExit(main())
