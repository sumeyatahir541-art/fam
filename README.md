# FAMI Rent Management System

A professional, full-featured building shop and tenant rent management application. Track shop units, tenants, rent collection, and expenses with real-time updates and role-based access control.

## 🎯 Features

- **Shop & Tenant Management** - Register and manage building shops, tenants, and occupancy status
- **Payment Tracking** - Record, review, and reverse rent payments with audit trails
- **Arrears Management** - Monitor outstanding rent and identify defaulters
- **Collection Reports** - View monthly collection performance and KPIs
- **Activity Logging** - Complete audit history of all system actions
- **Role-Based Access** - Admin, Manager, Payment Officer, and Viewer roles
- **Real-Time Updates** - Live data synchronization across all users
- **Export Capabilities** - Download payment and report data as CSV

## 🏗️ Tech Stack

- **Frontend**: Vanilla JavaScript (HTML/CSS/JS single-file app)
- **Backend**: Supabase (PostgreSQL database with authentication)
- **Build Tool**: Vite 5.4.10
- **Hosting**: Vercel
- **Real-Time**: Supabase Realtime Subscriptions

## 📋 Prerequisites

- **Node.js** 18.0.0 or higher
- **npm** 9.0.0 or higher
- **Supabase Account** - [Create one here](https://supabase.com)
- **Vercel Account** (for deployment) - [Create one here](https://vercel.com)

## 🚀 Quick Start

### 1. Local Development Setup

```bash
# Clone the repository
git clone https://github.com/sumeyatahir541-art/fam.git
cd fam

# Install dependencies
npm install

# Create local environment file
cp .env.example .env.local
```

### 2. Configure Supabase

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Create a new project (or use existing)
3. Get your credentials:
   - **Project URL**: Settings > API > Project URL
   - **Anon Key**: Settings > API > Project API keys > `anon` (public)

4. Update `.env.local`:
```env
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
VITE_APP_ENV=development
```

### 3. Set Up Supabase Database

Run these SQL queries in your Supabase SQL Editor:

```sql
-- Create profiles table (auto-created by auth trigger)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  email TEXT UNIQUE,
  role TEXT CHECK (role IN ('admin', 'manager', 'payment_officer', 'viewer')) DEFAULT 'viewer',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create shops table
CREATE TABLE IF NOT EXISTS shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_code TEXT UNIQUE NOT NULL,
  tenant_name TEXT NOT NULL,
  phone TEXT,
  business_name TEXT,
  monthly_rent DECIMAL(12,2) NOT NULL,
  registration_date DATE NOT NULL,
  status TEXT CHECK (status IN ('active', 'released', 'vacant')) DEFAULT 'active',
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL,
  payment_month DATE NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_date DATE NOT NULL,
  method TEXT CHECK (method IN ('Cash', 'Bank Transfer', 'Check', 'Mobile Money')) DEFAULT 'Cash',
  reference TEXT,
  note TEXT,
  status TEXT CHECK (status IN ('posted', 'reversed')) DEFAULT 'posted',
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  reversed_at TIMESTAMP,
  reversed_by UUID REFERENCES profiles(id)
);

-- Create audit_logs table
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  details JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS (Row Level Security)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for profiles
CREATE POLICY "Profiles visible to authenticated users" ON profiles
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can update any profile" ON profiles
  FOR UPDATE USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Create RLS policies for shops
CREATE POLICY "Shops visible to authenticated users" ON shops
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Managers and admins can manage shops" ON shops
  FOR ALL USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'manager')
  ));

-- Create RLS policies for payments
CREATE POLICY "Payments visible to authenticated users" ON payments
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Payment officers and up can manage payments" ON payments
  FOR ALL USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'manager', 'payment_officer')
  ));

-- Create RLS policies for audit_logs
CREATE POLICY "Audit logs visible to authenticated users" ON audit_logs
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create function to calculate rent due
CREATE OR REPLACE FUNCTION calculate_rent_due_for_month(p_shop_id UUID, p_month TEXT)
RETURNS DECIMAL AS $$
DECLARE
  v_rent DECIMAL;
  v_paid DECIMAL;
  v_due DECIMAL;
BEGIN
  SELECT monthly_rent INTO v_rent FROM shops WHERE id = p_shop_id;
  SELECT COALESCE(SUM(amount), 0) INTO v_paid
    FROM payments
    WHERE shop_id = p_shop_id
      AND payment_month::TEXT LIKE p_month || '%'
      AND status = 'posted';
  v_due := GREATEST(0, v_rent - v_paid);
  RETURN v_due;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for audit logging
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details)
  VALUES (auth.uid(), 'INSERT', TG_TABLE_NAME, NEW.id, row_to_json(NEW));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 4. Run Development Server

```bash
npm run dev
```

Visit `http://localhost:3000` and sign up with a test account.

## 🌐 Deploying to Vercel

### 1. Push to GitHub

```bash
git add .
git commit -m "Initial commit: FAMI Rent Management"
git push origin main
```

### 2. Connect to Vercel

1. Go to [Vercel Dashboard](https://vercel.com)
2. Click **New Project**
3. Import your GitHub repository
4. Configure project:
   - **Framework Preset**: Vite
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`

### 3. Add Environment Variables

In Vercel project settings, add:

```
VITE_SUPABASE_URL = https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY = sb_publishable_dWUddy-e4ttuJBwAOFgRTQ_ZHNZDse3
```

### 4. Deploy

Click **Deploy** and wait for build to complete.

## 📊 Usage Guide

### Roles & Permissions

| Role | Permissions |
|------|------------|
| **Admin** | Full access including user management |
| **Manager** | Register/edit shops, record payments, view reports |
| **Payment Officer** | Record and reverse payments only |
| **Viewer** | Read-only access to all data |

### Key Workflows

**Register a Shop:**
1. Navigate to "Shops & Tenants"
2. Click "+ Register shop"
3. Fill in shop details and monthly rent
4. Click "Register Shop"

**Record Payment:**
1. Navigate to "Payments"
2. Fill in shop, month, amount
3. Add payment method and reference
4. Click "Record payment"

**View Arrears:**
1. Navigate to "Arrears"
2. See outstanding rent per shop
3. Identify serious defaulters (3+ months unpaid)

**Generate Reports:**
1. Navigate to "Reports"
2. Select year
3. View monthly collection performance
4. Export as CSV

## 🔐 Security Features

- ✅ Supabase Authentication (email/password)
- ✅ Row-Level Security (RLS) policies
- ✅ Role-based access control
- ✅ Audit trail for all actions
- ✅ Environment variable protection
- ✅ Secure API key handling

## 🐛 Troubleshooting

### "Supabase is not configured"
- Ensure `.env.local` has correct `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`
- Restart dev server: `npm run dev`

### "Authentication service unavailable"
- Check Supabase project status at [app.supabase.com](https://app.supabase.com)
- Verify network connectivity
- Check browser console for detailed error messages

### "Permission denied" on operations
- Verify your role has correct permissions (check with admin)
- Ensure RLS policies are enabled in Supabase
- Check audit logs for denied actions

### Build fails on Vercel
- Ensure all environment variables are set in Vercel project settings
- Check build logs for specific errors
- Verify `package.json` has all required dependencies

## 📝 Environment Variables

```env
# Required for all environments
VITE_SUPABASE_URL=         # Your Supabase project URL
VITE_SUPABASE_ANON_KEY=    # Your Supabase anon key (public)

# Optional
VITE_APP_ENV=              # 'development' or 'production'
```

**⚠️ NEVER commit `.env.local` or expose `VITE_SUPABASE_ANON_KEY` in public repositories.**

## 📦 Production Checklist

Before going live:

- [ ] Set strong admin user password
- [ ] Update Supabase RLS policies for production
- [ ] Enable email verification in Supabase Auth
- [ ] Set up CORS in Supabase (allowed hosts)
- [ ] Configure backup strategy for PostgreSQL
- [ ] Enable database logging
- [ ] Set up alerts for failed transactions
- [ ] Test all user roles and permissions
- [ ] Verify data export/import procedures
- [ ] Document system administrator procedures

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Supabase documentation: https://supabase.com/docs
3. Contact system administrator or submit an issue

## 📄 License

Private - FAMI Rent Management System

---

**Built with ❤️ for professional property management**
