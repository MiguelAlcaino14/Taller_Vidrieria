/*
  # Add Indexes to Foreign Keys
  
  1. Performance Improvements
    - Add indexes on all foreign key columns to improve query performance
    - Indexes will speed up JOIN operations and foreign key lookups
  
  2. Tables Affected
    - `customers` - index on user_id
    - `cut_logs` - indexes on assignment_id, operator_id, sheet_id
    - `glass_projects` - indexes on customer_id, optimization_id
    - `manager_assignments` - index on user_id
    - `material_sheets` - indexes on glass_type_id, parent_sheet_id, user_id
    - `order_items` - indexes on aluminum_profile_id, glass_type_id
    - `sheet_assignments` - indexes on assigned_by, sheet_id
    - `system_settings` - index on updated_by
*/

-- Customers table
CREATE INDEX IF NOT EXISTS idx_customers_user_id ON customers(user_id);

-- Cut logs table
CREATE INDEX IF NOT EXISTS idx_cut_logs_assignment_id ON cut_logs(assignment_id);
CREATE INDEX IF NOT EXISTS idx_cut_logs_operator_id ON cut_logs(operator_id);
CREATE INDEX IF NOT EXISTS idx_cut_logs_sheet_id ON cut_logs(sheet_id);

-- Glass projects table
CREATE INDEX IF NOT EXISTS idx_glass_projects_customer_id ON glass_projects(customer_id);
CREATE INDEX IF NOT EXISTS idx_glass_projects_optimization_id ON glass_projects(optimization_id);

-- Manager assignments table
CREATE INDEX IF NOT EXISTS idx_manager_assignments_user_id ON manager_assignments(user_id);

-- Material sheets table
CREATE INDEX IF NOT EXISTS idx_material_sheets_glass_type_id ON material_sheets(glass_type_id);
CREATE INDEX IF NOT EXISTS idx_material_sheets_parent_sheet_id ON material_sheets(parent_sheet_id);
CREATE INDEX IF NOT EXISTS idx_material_sheets_user_id ON material_sheets(user_id);

-- Order items table
CREATE INDEX IF NOT EXISTS idx_order_items_aluminum_profile_id ON order_items(aluminum_profile_id);
CREATE INDEX IF NOT EXISTS idx_order_items_glass_type_id ON order_items(glass_type_id);

-- Sheet assignments table
CREATE INDEX IF NOT EXISTS idx_sheet_assignments_assigned_by ON sheet_assignments(assigned_by);
CREATE INDEX IF NOT EXISTS idx_sheet_assignments_sheet_id ON sheet_assignments(sheet_id);

-- System settings table
CREATE INDEX IF NOT EXISTS idx_system_settings_updated_by ON system_settings(updated_by);