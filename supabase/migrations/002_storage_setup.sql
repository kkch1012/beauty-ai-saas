-- ============================================
-- Storage Buckets Setup
-- Migration: 002_storage_setup
-- ============================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    ('customer-photos', 'customer-photos', FALSE, 10485760, ARRAY['image/png', 'image/jpeg', 'image/webp']),
    ('simulation-results', 'simulation-results', FALSE, 10485760, ARRAY['image/png', 'image/jpeg']),
    ('eyebrow-designs', 'eyebrow-designs', FALSE, 10485760, ARRAY['image/png', 'image/jpeg', 'image/webp']),
    ('contracts', 'contracts', FALSE, 20971520, ARRAY['application/pdf', 'image/png']),
    ('signatures', 'signatures', FALSE, 5242880, ARRAY['image/png', 'image/svg+xml'])
ON CONFLICT (id) DO UPDATE SET
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ============================================
-- Storage RLS Policies
-- ============================================

-- Customer Photos: 본인 폴더만 접근
CREATE POLICY "Users can upload own customer photos"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'customer-photos'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view own customer photos"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'customer-photos'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete own customer photos"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'customer-photos'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Simulation Results
CREATE POLICY "Users can upload simulation results"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'simulation-results'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view own simulation results"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'simulation-results'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Eyebrow Designs: 본인 것 + 공개 폴더
CREATE POLICY "Users can upload own designs"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'eyebrow-designs'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view own and public designs"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'eyebrow-designs'
        AND (
            auth.uid()::text = (storage.foldername(name))[1]
            OR (storage.foldername(name))[1] = 'public'
        )
    );

CREATE POLICY "Users can delete own designs"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'eyebrow-designs'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Contracts
CREATE POLICY "Users can upload contracts"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'contracts'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view own contracts"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'contracts'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Signatures
CREATE POLICY "Users can upload signatures"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'signatures'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view own signatures"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'signatures'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );
