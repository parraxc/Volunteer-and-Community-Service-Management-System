OUT=build_all.sql

cat > "$OUT" <<'EOF'
DROP DATABASE IF EXISTS volunteer_db;
CREATE DATABASE volunteer_db;
USE volunteer_db;
EOF

for f in volunteer_DB/[0-9][0-9]_*/*.sql; do
  printf '\n-- ===== %s =====\n' "$f" >> "$OUT"
  cat "$f" >> "$OUT"
  printf '\n' >> "$OUT"
done

echo "Wrote $OUT"