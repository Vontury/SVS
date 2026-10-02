-- Phase 1 / plan §6.3. Hierarchical categories, max depth 3.

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    parent_id UUID,
    level INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_category_parent
        FOREIGN KEY (parent_id) REFERENCES categories(id),

    -- depth limit + level/parent shape (level 1 <=> no parent)
    CONSTRAINT chk_category_level CHECK (level BETWEEN 1 AND 3),
    CONSTRAINT chk_category_parent_shape CHECK (
        (level = 1 AND parent_id IS NULL) OR (level > 1 AND parent_id IS NOT NULL)
    )
);

CREATE INDEX idx_categories_parent_id ON categories(parent_id);

-- Siblings must have unique names (case-insensitive), so find-or-create by
-- (parent_id, name) in §24 is safe. Root categories share one "NULL parent" bucket.
CREATE UNIQUE INDEX uq_categories_parent_name
    ON categories (COALESCE(parent_id, '00000000-0000-0000-0000-000000000000'::uuid), LOWER(name));

-- A child's level must be exactly parent.level + 1 (a CHECK cannot read another row).
CREATE FUNCTION enforce_category_level() RETURNS trigger AS $$
DECLARE
    parent_level INTEGER;
BEGIN
    IF NEW.parent_id IS NOT NULL THEN
        SELECT level INTO parent_level FROM categories WHERE id = NEW.parent_id;
        IF parent_level IS NULL OR NEW.level <> parent_level + 1 THEN
            RAISE EXCEPTION 'category level % is inconsistent with parent level %', NEW.level, parent_level;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_categories_level
    BEFORE INSERT OR UPDATE OF parent_id, level ON categories
    FOR EACH ROW EXECUTE FUNCTION enforce_category_level();
