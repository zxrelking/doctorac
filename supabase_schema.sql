-- ============================================================================
-- DOCTORAC (دكتوراك) - Supabase PostgreSQL Schema, RLS Policies, Storage & Triggers
-- Run this script FIRST in the Supabase SQL Editor, then run supabase_seed.sql
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. PROFILES TABLE (Synced with auth.users)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL DEFAULT 'سارة محمد',
    email TEXT NOT NULL DEFAULT '',
    phone TEXT DEFAULT '01012345678',
    gender TEXT DEFAULT 'أنثى' CHECK (gender IN ('أنثى', 'ذكر')),
    address TEXT DEFAULT 'المنصورة، مصر',
    avatar_url TEXT DEFAULT 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=600&q=80',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 2. DOCTORS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.doctors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    specialty TEXT NOT NULL,
    specialty_category TEXT NOT NULL, -- قلب وأوعية | باطنة | أطفال | جلدية | عيون
    bio TEXT NOT NULL,
    experience_years INTEGER NOT NULL DEFAULT 10,
    rating NUMERIC(2,1) NOT NULL DEFAULT 4.8,
    reviews_count INTEGER NOT NULL DEFAULT 100,
    consultation_fee INTEGER NOT NULL DEFAULT 250,
    wait_time_minutes INTEGER NOT NULL DEFAULT 15,
    hospital_name TEXT NOT NULL,
    city TEXT NOT NULL DEFAULT 'المنصورة',
    address TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL DEFAULT 31.0409,
    longitude DOUBLE PRECISION NOT NULL DEFAULT 31.3785,
    photo_url TEXT NOT NULL,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    available_slots TEXT[] NOT NULL DEFAULT ARRAY['5:00 م', '5:30 م', '6:00 م', '6:30 م', '7:00 م', '7:30 م'],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 3. LABS & LAB TESTS TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.labs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    tagline TEXT NOT NULL DEFAULT 'تحاليل دقيقة ورعاية تطمئنك',
    rating NUMERIC(2,1) NOT NULL DEFAULT 4.9,
    reviews_count INTEGER NOT NULL DEFAULT 214,
    working_hours TEXT NOT NULL DEFAULT '8 ص - 10 م',
    home_visit_available BOOLEAN NOT NULL DEFAULT TRUE,
    results_turnaround TEXT NOT NULL DEFAULT 'خلال 24 ساعة',
    address TEXT NOT NULL,
    city TEXT NOT NULL DEFAULT 'المنصورة، مصر',
    latitude DOUBLE PRECISION NOT NULL DEFAULT 31.0425,
    longitude DOUBLE PRECISION NOT NULL DEFAULT 31.3640,
    is_accredited BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.lab_tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lab_id UUID NOT NULL REFERENCES public.labs(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    short_name TEXT NOT NULL,
    category TEXT NOT NULL, -- الأكثر طلباً | تحاليل الدم | فيتامينات
    price INTEGER NOT NULL,
    prep_notes TEXT NOT NULL DEFAULT 'صورة الدم الكاملة لا تتطلب صياماً عادةً.',
    icon_type TEXT NOT NULL DEFAULT 'blood', -- blood | vitamin | cbc | liver | kidney | thyroid
    is_popular BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 4. PHARMACIES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.pharmacies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    short_name TEXT NOT NULL,
    tagline TEXT NOT NULL DEFAULT 'أدويتك ورعايتك أقرب إليك',
    storefront_url TEXT NOT NULL,
    rating NUMERIC(2,1) NOT NULL DEFAULT 4.8,
    reviews_count INTEGER NOT NULL DEFAULT 96,
    distance_km NUMERIC(3,1) NOT NULL DEFAULT 1.2,
    is_open_24h BOOLEAN NOT NULL DEFAULT TRUE,
    is_open_now BOOLEAN NOT NULL DEFAULT TRUE,
    delivery_available BOOLEAN NOT NULL DEFAULT TRUE,
    delivery_fee INTEGER NOT NULL DEFAULT 20,
    delivery_time_text TEXT NOT NULL DEFAULT '30-45 دقيقة',
    address TEXT NOT NULL,
    city TEXT NOT NULL DEFAULT 'المنصورة، مصر',
    latitude DOUBLE PRECISION NOT NULL DEFAULT 31.0442,
    longitude DOUBLE PRECISION NOT NULL DEFAULT 31.3587,
    phone TEXT NOT NULL DEFAULT '19600',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 5. RADIOLOGY CENTERS & SCANS TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.radiology_centers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    tagline TEXT NOT NULL DEFAULT 'تشخيص أدق بأحدث أجهزة التصوير',
    rating NUMERIC(2,1) NOT NULL DEFAULT 4.8,
    reviews_count INTEGER NOT NULL DEFAULT 175,
    working_hours TEXT NOT NULL DEFAULT '9 ص - 11 م',
    wait_time_text TEXT NOT NULL DEFAULT '20 دقيقة',
    report_turnaround TEXT NOT NULL DEFAULT 'خلال 24 ساعة',
    address TEXT NOT NULL,
    city TEXT NOT NULL DEFAULT 'المنصورة، مصر',
    latitude DOUBLE PRECISION NOT NULL DEFAULT 31.0418,
    longitude DOUBLE PRECISION NOT NULL DEFAULT 31.3742,
    safety_warning TEXT NOT NULL DEFAULT 'أبلغ المركز عن أي أجهزة أو غرسات معدنية.',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.radiology_scans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    center_id UUID NOT NULL REFERENCES public.radiology_centers(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    short_name TEXT NOT NULL,
    scan_type TEXT NOT NULL, -- MRI | CT | X-Ray | Ultrasound
    price INTEGER NOT NULL,
    safety_notes TEXT NOT NULL DEFAULT 'أبلغ المركز عن أي أجهزة أو غرسات معدنية.',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 6. BOOKINGS TABLE (Doctors, Labs, Radiology)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reference_code TEXT NOT NULL,
    booking_type TEXT NOT NULL CHECK (booking_type IN ('doctor', 'lab', 'radiology')),
    provider_id UUID,
    provider_name TEXT NOT NULL,
    provider_subtitle TEXT NOT NULL,
    provider_image_url TEXT,
    service_title TEXT NOT NULL,
    location_text TEXT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TEXT NOT NULL,
    patient_name TEXT NOT NULL,
    patient_phone TEXT NOT NULL,
    payment_method TEXT NOT NULL DEFAULT 'الدفع نقداً في العيادة',
    price INTEGER NOT NULL,
    booking_fee INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'scheduled', 'completed', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 7. ORDERS TABLE (Pharmacy Orders & Lab/Radiology Results)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reference_code TEXT NOT NULL,
    order_type TEXT NOT NULL CHECK (order_type IN ('pharmacy', 'lab', 'radiology')),
    provider_id UUID,
    provider_name TEXT NOT NULL,
    provider_subtitle TEXT NOT NULL,
    items_summary TEXT NOT NULL,
    total_price INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'on_the_way' CHECK (status IN ('on_the_way', 'processing', 'result_ready', 'delivered', 'cancelled')),
    prescription_url TEXT,
    result_file_url TEXT,
    delivery_address TEXT DEFAULT 'المنصورة، مصر',
    order_date_text TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 8. INDEXES FOR FAST QUERIES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_doctors_category ON public.doctors(specialty_category);
CREATE INDEX IF NOT EXISTS idx_doctors_featured ON public.doctors(is_featured);
CREATE INDEX IF NOT EXISTS idx_lab_tests_lab_id ON public.lab_tests(lab_id);
CREATE INDEX IF NOT EXISTS idx_lab_tests_category ON public.lab_tests(category);
CREATE INDEX IF NOT EXISTS idx_radiology_scans_center_id ON public.radiology_scans(center_id);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON public.bookings(appointment_date);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);

-- ============================================================================
-- 9. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.labs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lab_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pharmacies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.radiology_centers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.radiology_scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Public Catalog Read Policies
DROP POLICY IF EXISTS "Doctors are viewable by everyone" ON public.doctors;
CREATE POLICY "Doctors are viewable by everyone" ON public.doctors
    FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Labs are viewable by everyone" ON public.labs;
CREATE POLICY "Labs are viewable by everyone" ON public.labs
    FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Lab tests are viewable by everyone" ON public.lab_tests;
CREATE POLICY "Lab tests are viewable by everyone" ON public.lab_tests
    FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Pharmacies are viewable by everyone" ON public.pharmacies;
CREATE POLICY "Pharmacies are viewable by everyone" ON public.pharmacies
    FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Radiology centers are viewable by everyone" ON public.radiology_centers;
CREATE POLICY "Radiology centers are viewable by everyone" ON public.radiology_centers
    FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Radiology scans are viewable by everyone" ON public.radiology_scans;
CREATE POLICY "Radiology scans are viewable by everyone" ON public.radiology_scans
    FOR SELECT USING (TRUE);

-- Profiles Policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Bookings Policies
DROP POLICY IF EXISTS "Users can view own bookings" ON public.bookings;
CREATE POLICY "Users can view own bookings" ON public.bookings
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own bookings" ON public.bookings;
CREATE POLICY "Users can create own bookings" ON public.bookings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own bookings" ON public.bookings;
CREATE POLICY "Users can update own bookings" ON public.bookings
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own bookings" ON public.bookings;
CREATE POLICY "Users can delete own bookings" ON public.bookings
    FOR DELETE USING (auth.uid() = user_id);

-- Orders Policies
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
CREATE POLICY "Users can create own orders" ON public.orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;
CREATE POLICY "Users can update own orders" ON public.orders
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 10. STORAGE BUCKETS & POLICIES (Avatars, Prescriptions, Lab Results)
-- ============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES
    ('avatars', 'avatars', TRUE),
    ('prescriptions', 'prescriptions', TRUE),
    ('lab_results', 'lab_results', TRUE)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public avatar read" ON storage.objects;
CREATE POLICY "Public avatar read" ON storage.objects
    FOR SELECT USING (bucket_id IN ('avatars', 'prescriptions', 'lab_results'));

DROP POLICY IF EXISTS "Authenticated users upload avatars" ON storage.objects;
CREATE POLICY "Authenticated users upload avatars" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id IN ('avatars', 'prescriptions', 'lab_results'));

DROP POLICY IF EXISTS "Authenticated users update own files" ON storage.objects;
CREATE POLICY "Authenticated users update own files" ON storage.objects
    FOR UPDATE TO authenticated
    USING (bucket_id IN ('avatars', 'prescriptions', 'lab_results'));

-- ============================================================================
-- 11. AUTOMATIC PROFILE + STARTER DEMO ACTIVITY TRIGGER FOR NEW USERS
-- ============================================================================
CREATE OR REPLACE FUNCTION public.seed_demo_activity_for_user(
    target_user_id UUID,
    user_full_name TEXT DEFAULT 'سارة محمد'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Insert starter upcoming doctor booking & lab booking so "مواعيدي" is immediately testable
    INSERT INTO public.bookings (
        user_id, reference_code, booking_type, provider_id,
        provider_name, provider_subtitle, provider_image_url,
        service_title, location_text, appointment_date, appointment_time,
        patient_name, patient_phone, payment_method, price, status
    )
    VALUES
    (
        target_user_id,
        '#DOC-8492',
        'doctor',
        '11111111-1111-1111-1111-111111111101',
        'د. أحمد حسن',
        'أخصائي قلب وأوعية دموية',
        'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=600&q=80',
        'كشف طبي - عيادة د. أحمد حسن',
        'المنصورة • شارع الجمهورية',
        CURRENT_DATE + INTERVAL '2 days',
        '05:00 مساءً',
        user_full_name,
        '01012345678',
        'الدفع نقداً في العيادة',
        250,
        'confirmed'
    ),
    (
        target_user_id,
        '#LAB-3104',
        'lab',
        '22222222-2222-2222-2222-222222222201',
        'تحليل صورة دم كاملة (CBC)',
        'معامل المختبر - فرع المنصورة',
        NULL,
        'تحليل صورة دم كاملة (CBC)',
        'المنصورة • شارع الترعة',
        CURRENT_DATE + INTERVAL '4 days',
        '09:00 صباحاً',
        user_full_name,
        '01012345678',
        'الدفع نقداً في المعمل',
        180,
        'scheduled'
    );

    -- Insert starter pharmacy & lab orders so "طلباتي" is immediately testable
    INSERT INTO public.orders (
        user_id, reference_code, order_type, provider_id,
        provider_name, provider_subtitle, items_summary,
        total_price, status, delivery_address, order_date_text
    )
    VALUES
    (
        target_user_id,
        '#ORD-5021',
        'pharmacy',
        '44444444-4444-4444-4444-444444444401',
        'صيدلية العائلة الصحية',
        'أدوية وعناية • توصيل إلى المنصورة',
        'روشتة + مكملات غذائية (3 أصناف)',
        320,
        'on_the_way',
        'المنصورة، شارع جيهان',
        'اليوم، 24 نوفمبر • 11:45 ص'
    ),
    (
        target_user_id,
        '#LAB-2190',
        'lab',
        '22222222-2222-2222-2222-222222222201',
        'تحليل صورة دم كاملة (CBC)',
        'معامل المختبر - فرع المنصورة',
        'سحب عينة من المنزل',
        210,
        'result_ready',
        'المنصورة، شارع الترعة',
        '22 نوفمبر 2026'
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_full_name TEXT;
BEGIN
    v_full_name := COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'full_name'), ''), 'سارة محمد');

    INSERT INTO public.profiles (id, full_name, email, phone, gender, address, avatar_url)
    VALUES (
        NEW.id,
        v_full_name,
        COALESCE(NEW.email, ''),
        COALESCE(NEW.raw_user_meta_data->>'phone', '01012345678'),
        COALESCE(NEW.raw_user_meta_data->>'gender', 'أنثى'),
        COALESCE(NEW.raw_user_meta_data->>'address', 'المنصورة، مصر'),
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=600&q=80'
    )
    ON CONFLICT (id) DO NOTHING;

    -- Seed starter bookings & orders for immediate exploration
    PERFORM public.seed_demo_activity_for_user(NEW.id, v_full_name);

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Updated_at auto-touch trigger
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS trg_bookings_updated_at ON public.bookings;
CREATE TRIGGER trg_bookings_updated_at
    BEFORE UPDATE ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS trg_orders_updated_at ON public.orders;
CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
