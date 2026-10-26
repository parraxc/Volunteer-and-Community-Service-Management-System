# ER diagrams — FRD v1.5 / current SQL

- **conceptual-chen.svg**: conceptual ER diagram using relationship diamonds, underlined keys, double lines for total participation, weak entity and identifying relationship, derived attributes, and a conceptual multivalued skills collection.
- **relational-schema.svg**: readable physical schema with all nine tables, every actual attribute/type, key flags, nullability, and relationship cardinalities.
- **relational-schema.mmd**: editable Mermaid source (renders on GitHub).
- **.dot files**: editable Graphviz sources for both SVGs.

Open SVGs in a browser and zoom, or print to PDF with landscape/custom large-paper settings. This avoids losing detail in a low-resolution screenshot. SQL is the authority for physical definitions. These diagrams include the HoursApproved column retained by the current schema and the composite VolunteerHours-to-VolunteerShift foreign key added with the acceptance tests.

## Relationships and notation

| Parent / child | Cardinality | Child participation |
|---|---|---|
| StaffMember / Event | Staff 0..N events; event exactly 1 coordinator | Total |
| Event / Shift | Event 0..N shifts; shift exactly 1 event | Total |
| Volunteer / VolunteerShift | Volunteer 0..N assignments; assignment exactly 1 volunteer | Total |
| Shift / VolunteerShift | Shift 0..N assignments; assignment exactly 1 shift | Total |
| VolunteerShift / VolunteerHours | Assignment 0..1 hours record; hours record exactly 1 assignment | Total for hours; partial for assignment |
| StaffMember / VolunteerShift (approval) | Staff 0..N approvals; assignment 0..1 approver | Partial |
| Volunteer / VolunteerSkill | Volunteer 0..N memberships; membership exactly 1 volunteer | Total for membership |
| Skill / VolunteerSkill | Skill 0..N memberships; membership exactly 1 skill | Total for membership |
| StaffMember / AuditLog | Staff 0..N entries; entry 0..1 mapped staff actor | Partial; deployment actor may be unmapped |

M:N Volunteer–Shift and Volunteer–Skill are resolved by junction entities. The optional 1:1 approved-hours extension is identification-dependent: its entire composite key is inherited from VolunteerShift, enforced by the composite FK. It has no independent surrogate identifier. The identifying relationship is drawn with a double diamond.

Contact/name strings remain atomic under the requirements; no unsupported composite address/name fields have been invented. Composite identifiers (AssignmentKey and MembershipKey) are drawn as branched composite attributes with their actual key components; they are diagram groupings, not extra SQL columns. Skills is conceptual multivalued information implemented through Skill and VolunteerSkill, not an additional SQL column. Derived totals/capacity are not stored columns. JSON audit images are historical payloads.

Graphviz cardinality numbers label entity ends using conventional Chen maximum/minimum counts; use the table above to read optional participation precisely. Nonempty event/shift populations are not required by SQL, so their parent-side participation remains partial. Run `dot -Tsvg conceptual-chen.dot -o conceptual-chen.svg` (and similarly for relational-schema.dot) if Graphviz is installed.
