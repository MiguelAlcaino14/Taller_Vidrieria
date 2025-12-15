export interface Cut {
  id: string;
  width: number;
  height: number;
  quantity: number;
  label: string;
}

export interface CutLine {
  id: string;
  type: 'horizontal' | 'vertical';
  position: number;
  start: number;
  end: number;
  order: number;
}

export interface CutInstruction {
  step: number;
  type: 'horizontal' | 'vertical';
  position: number;
  description: string;
  resultingPieces: number;
}

export interface PlacedCut {
  cut: Cut;
  x: number;
  y: number;
  width: number;
  height: number;
  rotated: boolean;
  isPattern?: boolean;
}

export interface Remnant {
  x: number;
  y: number;
  width: number;
  height: number;
  area: number;
}

export interface PackingResult {
  placedCuts: PlacedCut[];
  cutLines?: CutLine[];
  cutInstructions?: CutInstruction[];
  utilization: number;
  method?: string;
  remnants?: Remnant[];
}

export interface Sheet {
  width: number;
  height: number;
  cutThickness: number;
  glassThickness: number;
  cuttingMethod: 'manual' | 'machine';
}

export interface Project {
  id?: string;
  name: string;
  sheet: Sheet;
  cuts: Cut[];
  createdAt?: string;
  updatedAt?: string;
}

export type ValidationStatus = 'safe' | 'warning' | 'danger';

export interface CutValidation {
  status: ValidationStatus;
  message: string;
  minDimension: number;
}

export type CustomerType = 'individual' | 'company';

export interface Customer {
  id: string;
  user_id: string;
  name: string;
  phone: string;
  email: string;
  address: string;
  customer_type: CustomerType;
  notes: string;
  created_at: string;
  updated_at: string;
}

export type OrderStatus = 'quoted' | 'approved' | 'in_production' | 'ready' | 'delivered' | 'cancelled';

export interface Order {
  id: string;
  user_id: string;
  customer_id: string | null;
  order_number: string;
  name: string;
  status: OrderStatus;
  notes: string;
  sheet_width: number;
  sheet_height: number;
  cut_thickness: number;
  glass_thickness: number;
  cutting_method: 'manual' | 'machine';
  cuts: Cut[];
  quote_date: string;
  approved_date: string | null;
  promised_date: string | null;
  delivered_date: string | null;
  subtotal_materials: number;
  subtotal_labor: number;
  discount_amount: number;
  total_amount: number;
  created_at: string;
  updated_at: string;
}

export interface GlassType {
  id: string;
  name: string;
  description: string;
  price_per_sqm: number;
  available_thicknesses: number[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface AluminumProfile {
  id: string;
  name: string;
  color: string;
  description: string;
  price_per_meter: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export type AccessoryUnitType = 'unit' | 'meter' | 'kg';

export interface Accessory {
  id: string;
  name: string;
  description: string;
  unit_price: number;
  unit_type: AccessoryUnitType;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface AccessoryUsed {
  accessory_id: string;
  quantity: number;
  unit_price: number;
}

export interface GlassPiece {
  width: number;
  height: number;
  quantity: number;
  label: string;
}

export interface OrderItem {
  id: string;
  order_id: string;
  item_number: number;
  description: string;
  quantity: number;
  glass_type_id: string | null;
  glass_thickness: number;
  aluminum_profile_id: string | null;
  glass_pieces: GlassPiece[];
  accessories_used: AccessoryUsed[];
  labor_cost: number;
  item_total: number;
  notes: string;
  created_at: string;
}

export type MaterialType = 'glass' | 'mirror' | 'aluminum';
export type SheetOrigin = 'purchase' | 'remnant';
export type SheetStatus = 'available' | 'reserved' | 'used' | 'damaged';
export type MaterialStatus = 'pending' | 'assigned' | 'cutting' | 'completed';
export type AssignmentStatus = 'pending' | 'in_progress' | 'completed' | 'cancelled';

export interface MaterialSheet {
  id: string;
  user_id: string;
  material_type: MaterialType;
  glass_type_id: string | null;
  thickness: number;
  width: number;
  height: number;
  area_total: number;
  origin: SheetOrigin;
  parent_sheet_id: string | null;
  source_order_id: string | null;
  status: SheetStatus;
  purchase_date: string;
  purchase_cost: number;
  supplier: string;
  notes: string;
  created_at: string;
  updated_at: string;
}

export interface SheetAssignment {
  id: string;
  order_id: string;
  sheet_id: string;
  assigned_date: string;
  assigned_by: string;
  cuts_assigned: PlacedCut[];
  status: AssignmentStatus;
  utilization_percentage: number;
  waste_area: number;
  completed_date: string | null;
  created_at: string;
}

export interface GeneratedRemnant {
  width: number;
  height: number;
  x: number;
  y: number;
}

export interface CutLog {
  id: string;
  order_id: string;
  sheet_id: string;
  assignment_id: string | null;
  cut_date: string;
  operator_id: string;
  successful_pieces: number;
  failed_pieces: number;
  generated_remnants: GeneratedRemnant[];
  notes: string;
  created_at: string;
}

export interface SheetWithCuts {
  sheet_id: string;
  sheet: MaterialSheet;
  cuts: PlacedCut[];
  utilization: number;
  waste_area: number;
}

export interface OptimizationSuggestion {
  id: string;
  order_id: string;
  suggestion_number: number;
  sheets_used: string[];
  sheet_details: SheetWithCuts[];
  total_utilization: number;
  total_waste: number;
  estimated_remnants: GeneratedRemnant[];
  total_cost: number;
  uses_remnants: boolean;
  created_at: string;
}

export interface SystemSetting {
  id: string;
  setting_key: string;
  setting_value: number | string | boolean | object;
  description: string;
  updated_by: string | null;
  updated_at: string;
}

export interface OrderWithMaterial extends Order {
  material_status: MaterialStatus;
  cutting_plan: object;
  assigned_sheets: string[];
  optimization_id: string | null;
  estimated_waste: number;
  actual_waste: number;
  material_cost: number;
}
