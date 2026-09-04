-- ==============================================================================
-- CUSATIFY DATABASE SECURITY HARDENING & ROLE-BASED ACCESS CONTROL (RBAC) SCHEMA
-- PostgreSQL / Supabase Row-Level Security (RLS) Policies
-- ==============================================================================

-- 1. Helper Functions for Role Resolution
CREATE OR REPLACE FUNCTION public.is_faculty()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.faculty
    WHERE uid = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_student()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.students
    WHERE uid = auth.uid()
  );
$$;

-- ==============================================================================
-- 2. ENABLE ROW LEVEL SECURITY ON ALL TABLES
-- ==============================================================================
ALTER TABLE IF EXISTS public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.faculty ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.library_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notices ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- 3. STUDENTS TABLE POLICIES
-- ==============================================================================
DROP POLICY IF EXISTS "Authenticated users can view students" ON public.students;
CREATE POLICY "Authenticated users can view students"
  ON public.students
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Students can insert their own profile" ON public.students;
CREATE POLICY "Students can insert their own profile"
  ON public.students
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = uid);

DROP POLICY IF EXISTS "Students can update their own profile" ON public.students;
CREATE POLICY "Students can update their own profile"
  ON public.students
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = uid)
  WITH CHECK (auth.uid() = uid);

-- ==============================================================================
-- 4. FACULTY TABLE POLICIES
-- ==============================================================================
DROP POLICY IF EXISTS "Authenticated users can view faculty" ON public.faculty;
CREATE POLICY "Authenticated users can view faculty"
  ON public.faculty
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Faculty can insert their own profile" ON public.faculty;
CREATE POLICY "Faculty can insert their own profile"
  ON public.faculty
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = uid);

DROP POLICY IF EXISTS "Faculty can update their own profile" ON public.faculty;
CREATE POLICY "Faculty can update their own profile"
  ON public.faculty
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = uid)
  WITH CHECK (auth.uid() = uid);

-- ==============================================================================
-- 5. ATTENDANCE TABLE POLICIES
-- ==============================================================================
DROP POLICY IF EXISTS "Students view own attendance, faculty view all" ON public.attendance;
CREATE POLICY "Students view own attendance, faculty view all"
  ON public.attendance
  FOR SELECT
  TO authenticated
  USING (
    student_uid = auth.uid() OR public.is_faculty()
  );

DROP POLICY IF EXISTS "Only faculty can insert attendance" ON public.attendance;
CREATE POLICY "Only faculty can insert attendance"
  ON public.attendance
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_faculty() AND (faculty_uid = auth.uid() OR marked_by = auth.uid())
  );

DROP POLICY IF EXISTS "Only faculty can update attendance" ON public.attendance;
CREATE POLICY "Only faculty can update attendance"
  ON public.attendance
  FOR UPDATE
  TO authenticated
  USING (public.is_faculty())
  WITH CHECK (public.is_faculty());

-- ==============================================================================
-- 6. NOTES TABLE POLICIES (Strict User-Level Scoping)
-- ==============================================================================
DROP POLICY IF EXISTS "Users can only select their own notes" ON public.notes;
CREATE POLICY "Users can only select their own notes"
  ON public.notes
  FOR SELECT
  TO authenticated
  USING (user_uid = auth.uid());

DROP POLICY IF EXISTS "Users can only insert their own notes" ON public.notes;
CREATE POLICY "Users can only insert their own notes"
  ON public.notes
  FOR INSERT
  TO authenticated
  WITH CHECK (user_uid = auth.uid());

DROP POLICY IF EXISTS "Users can only update their own notes" ON public.notes;
CREATE POLICY "Users can only update their own notes"
  ON public.notes
  FOR UPDATE
  TO authenticated
  USING (user_uid = auth.uid())
  WITH CHECK (user_uid = auth.uid());

DROP POLICY IF EXISTS "Users can only delete their own notes" ON public.notes;
CREATE POLICY "Users can only delete their own notes"
  ON public.notes
  FOR DELETE
  TO authenticated
  USING (user_uid = auth.uid());

-- ==============================================================================
-- 7. EVENTS TABLE POLICIES
-- ==============================================================================
DROP POLICY IF EXISTS "Authenticated users can view events" ON public.events;
CREATE POLICY "Authenticated users can view events"
  ON public.events
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Only faculty can manage events" ON public.events;
CREATE POLICY "Only faculty can manage events"
  ON public.events
  FOR ALL
  TO authenticated
  USING (public.is_faculty())
  WITH CHECK (public.is_faculty());

-- ==============================================================================
-- 8. NOTICES TABLE POLICIES
-- ==============================================================================
DROP POLICY IF EXISTS "Authenticated users can view notices" ON public.notices;
CREATE POLICY "Authenticated users can view notices"
  ON public.notices
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Only faculty can manage notices" ON public.notices;
CREATE POLICY "Only faculty can manage notices"
  ON public.notices
  FOR ALL
  TO authenticated
  USING (public.is_faculty())
  WITH CHECK (public.is_faculty());

-- ==============================================================================
-- 9. ASSIGNMENTS TABLE POLICIES
-- ==============================================================================
DROP POLICY IF EXISTS "Authenticated users can view assignments" ON public.assignments;
CREATE POLICY "Authenticated users can view assignments"
  ON public.assignments
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Only faculty can manage assignments" ON public.assignments;
CREATE POLICY "Only faculty can manage assignments"
  ON public.assignments
  FOR ALL
  TO authenticated
  USING (public.is_faculty())
  WITH CHECK (public.is_faculty());

-- ==============================================================================
-- 10. LIBRARY LOGS POLICIES
-- ==============================================================================
DROP POLICY IF EXISTS "Users view own library logs, faculty view all" ON public.library_logs;
CREATE POLICY "Users view own library logs, faculty view all"
  ON public.library_logs
  FOR SELECT
  TO authenticated
  USING (
    user_uid = auth.uid() OR public.is_faculty()
  );

DROP POLICY IF EXISTS "Users can insert their own library logs" ON public.library_logs;
CREATE POLICY "Users can insert their own library logs"
  ON public.library_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (user_uid = auth.uid());

DROP POLICY IF EXISTS "Users can update their own library logs" ON public.library_logs;
CREATE POLICY "Users can update their own library logs"
  ON public.library_logs
  FOR UPDATE
  TO authenticated
  USING (user_uid = auth.uid() OR public.is_faculty())
  WITH CHECK (user_uid = auth.uid() OR public.is_faculty());

-- ==============================================================================
-- 11. STORAGE BUCKET POLICIES (profile-photos)
-- ==============================================================================
-- Ensure the storage bucket has RLS enabled
-- INSERT: Users can only upload into their own folder (e.g. students/{uid}.jpg)
-- SELECT: Public or authenticated read access
-- UPDATE/DELETE: Only photo owners
