/*
  # Remove Unused Audit Indexes

  1. Analysis
    - Reviewed application query patterns
    - Identified indexes that are not used in queries
    - Audit columns (assigned_by, updated_by, operator_id) are rarely queried
    - Keeping indexes on these columns adds unnecessary write overhead

  2. Indexes Removed
    - `idx_sheet_assignments_assigned_by` - Audit column, never queried
    - `idx_system_settings_updated_by` - Audit column, never queried
    - `idx_cut_logs_operator_id` - Not used in current queries

  3. Indexes Retained (Critical for Performance)
    - Foreign key columns: Essential for JOIN performance and constraint checking
    - RLS policy columns: Used in WHERE clauses for access control
    - Frequently filtered columns: Used in application queries

  4. Performance Impact
    - Reduced write overhead on INSERT/UPDATE operations
    - No impact on read performance (removed indexes were never used)
    - Faster table maintenance operations
*/

-- Remove audit column indexes that are not used in queries
DROP INDEX IF EXISTS idx_sheet_assignments_assigned_by;
DROP INDEX IF EXISTS idx_system_settings_updated_by;
DROP INDEX IF EXISTS idx_cut_logs_operator_id;
