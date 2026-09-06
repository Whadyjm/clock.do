-- ==============================================================================
-- Clock.Do - Esquema de Base de Datos para Supabase
-- Ejecutar en el SQL Editor de tu proyecto en Supabase (https://supabase.com)
-- ==============================================================================

-- 1. Tabla de Bloques de Tiempo (Reloj Radial)
CREATE TABLE IF NOT EXISTS public.time_blocks (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    start_hour DOUBLE PRECISION NOT NULL,
    end_hour DOUBLE PRECISION NOT NULL,
    date DATE NOT NULL,
    category INTEGER NOT NULL DEFAULT 0,
    status INTEGER NOT NULL DEFAULT 0,
    is_full_day BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Índices para time_blocks
CREATE INDEX IF NOT EXISTS idx_time_blocks_user_date ON public.time_blocks(user_id, date);
CREATE INDEX IF NOT EXISTS idx_time_blocks_user_id ON public.time_blocks(user_id);

-- 2. Tabla de Tareas ToDo (Backlog)
CREATE TABLE IF NOT EXISTS public.todos (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category INTEGER NOT NULL DEFAULT 0,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Índices para todos
CREATE INDEX IF NOT EXISTS idx_todos_user_id ON public.todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_completed ON public.todos(user_id, is_completed);

-- 3. Habilitar Seguridad a Nivel de Fila (RLS)
ALTER TABLE public.time_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;

-- 4. Políticas de Seguridad (RLS) para time_blocks
CREATE POLICY "Los usuarios pueden ver sus propios bloques" 
    ON public.time_blocks FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden insertar sus propios bloques" 
    ON public.time_blocks FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden actualizar sus propios bloques" 
    ON public.time_blocks FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden eliminar sus propios bloques" 
    ON public.time_blocks FOR DELETE 
    USING (auth.uid() = user_id);

-- 5. Políticas de Seguridad (RLS) para todos
CREATE POLICY "Los usuarios pueden ver sus propias tareas" 
    ON public.todos FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden insertar sus propias tareas" 
    ON public.todos FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden actualizar sus propias tareas" 
    ON public.todos FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden eliminar sus propias tareas" 
    ON public.todos FOR DELETE 
    USING (auth.uid() = user_id);

-- ==============================================================================
-- 6. Tabla de Categorías Personalizadas
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.categories (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color BIGINT NOT NULL,
    icon_code_point INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_categories_user_id ON public.categories(user_id);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los usuarios pueden ver sus propias categorias" 
    ON public.categories FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden insertar sus propias categorias" 
    ON public.categories FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden actualizar sus propias categorias" 
    ON public.categories FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden eliminar sus propias categorias" 
    ON public.categories FOR DELETE 
    USING (auth.uid() = user_id);

-- ==============================================================================
-- Migraciones opcionales para time_blocks y todos:
-- ==============================================================================
-- 1. Notificaciones personalizadas por bloque
ALTER TABLE public.time_blocks ADD COLUMN IF NOT EXISTS notification_enabled BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.time_blocks ADD COLUMN IF NOT EXISTS reminder_minutes INTEGER;

-- 2. Referencia a categoría por ID (soporta categorías personalizadas)
ALTER TABLE public.time_blocks ADD COLUMN IF NOT EXISTS category_id TEXT;
ALTER TABLE public.todos ADD COLUMN IF NOT EXISTS category_id TEXT;
