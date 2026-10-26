USE volunteer_db;

-- RQ-10: MANAGER ONLY. All NULL filters = full audit history.
-- UTC timestamp interval is [start,end); RecordId is an exact key string.
SELECT a.AuditID, a.ChangedAt, a.ChangedBy, a.ChangedByStaffID, st.StaffName,
       a.TableName, a.RecordId, a.Operation, a.OldValues, a.NewValues
FROM AuditLog a
LEFT JOIN StaffMember st ON st.StaffID = a.ChangedByStaffID
WHERE (@report_table IS NULL OR a.TableName = @report_table)
  AND (@report_record_id IS NULL OR a.RecordId = @report_record_id)
  AND (@report_staff_id IS NULL OR a.ChangedByStaffID = @report_staff_id)
  AND (@report_audit_start IS NULL OR a.ChangedAt >= @report_audit_start)
  AND (@report_audit_end IS NULL OR a.ChangedAt < @report_audit_end)
ORDER BY a.ChangedAt DESC, a.AuditID DESC;
