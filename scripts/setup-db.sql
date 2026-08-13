-- FAMI Rent Management System - Database Setup Script
-- Run this in Supabase SQL Editor

-- Create auth trigger for profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', new.email, COALESCE(new.raw_user_meta_data->>'role', 'viewer'));
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  email TEXT UNIQUE,
  role TEXT CHECK (role IN ('admin', 'manager', 'payment_officer', 'viewer')) DEFAULT 'viewer',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create shops table
CREATE TABLE IF NOT EXISTS public.shops (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_code TEXT NOT NULL UNIQUE,
  tenant_name TEXT NOT NULL,
  phone TEXT,
  business_name TEXT,
  monthly_rent DECIMAL(12,2) NOT NULL,
  registration_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'released', 'vacant')),
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create payments table
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  payment_month DATE NOT NULL,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  payment_date DATE NOT NULL,
  method TEXT NOT NULL DEFAULT 'Cash' CHECK (method IN ('Cash', 'Bank Transfer', 'Check', 'Mobile Money')),
  reference TEXT,
  note TEXT,
  status TEXT NOT NULL DEFAULT 'posted' CHECK (status IN ('posted', 'reversed')),
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  reversed_at TIMESTAMP WITH TIME ZONE,
  reversed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL
);

-- Create audit_logs table
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  details JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_payments_shop_id ON public.payments(shop_id);
CREATE INDEX IF NOT EXISTS idx_payments_payment_month ON public.payments(payment_month);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(status);
CREATE INDEX IF NOT EXISTS idx_shops_status ON public.shops(status);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies
-- Profiles policies
CREATE POLICY "Profiles readable by authenticated" ON public.profiles
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can manage all profiles" ON public.profiles
  FOR ALL USING (EXISTS(
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Shops policies
CREATE POLICY "Shops readable by authenticated" ON public.shops
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Managers and admins manage shops" ON public.shops
  FOR ALL USING (EXISTS(
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'manager')
  ));

-- Payments policies
CREATE POLICY "Payments readable by authenticated" ON public.payments
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Payment officers manage payments" ON public.payments
  FOR ALL USING (EXISTS(
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'manager', 'payment_officer')
  ));

-- Audit logs policies
CREATE POLICY "Audit logs readable by authenticated" ON public.audit_logs
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create calculate_rent_due_for_month function
CREATE OR REPLACE FUNCTION public.calculate_rent_due_for_month(p_shop_id UUID, p_month TEXT)
RETURNS DECIMAL AS $$
DECLARE
  v_rent DECIMAL;
  v_paid DECIMAL;
  v_due DECIMAL;
BEGIN
  SELECT monthly_rent INTO v_rent FROM public.shops WHERE id = p_shop_id;
  IF v_rent IS NULL THEN
    RETURN 0;
  END IF;
  
  SELECT COALESCE(SUM(amount), 0) INTO v_paid
    FROM public.payments
    WHERE shop_id = p_shop_id
      AND to_char(payment_month, 'YYYY-MM') = p_month
      AND status = 'posted';
  
  v_due := GREATEST(0, v_rent - v_paid);
  RETURN v_due;
END;
$$ LANGUAGE plpgsql STABLE;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.calculate_rent_due_for_month(UUID, TEXT) TO authenticated;

PRINT 'Database setup complete!';
