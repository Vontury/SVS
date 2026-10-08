-- Phase 1: hierarchical categories (max 3 levels).
-- Level 1: parent_id IS NULL. Level 2 -> parent is level 1. Level 3 -> parent is level 2.

CREATE TABLE categories (
                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

                            name VARCHAR(255) NOT NULL,

                            parent_id UUID,

                            level INTEGER NOT NULL,

                            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

                            CONSTRAINT fk_category_parent
                                FOREIGN KEY (parent_id)
                                    REFERENCES categories(id),

                            CONSTRAINT chk_category_level
                                CHECK (level BETWEEN 1 AND 3),

                            CONSTRAINT chk_category_root
                                CHECK (
                                    (level = 1 AND parent_id IS NULL)
                                        OR (level > 1 AND parent_id IS NOT NULL)
                                    )
);

-- A child's level must be exactly parent.level + 1 (a CHECK cannot read another row).
CREATE FUNCTION enforce_category_level() RETURNS TRIGGER AS $$
DECLARE
parent_level INTEGER;
BEGIN
    IF NEW.parent_id IS NOT NULL THEN
SELECT level INTO parent_level FROM categories WHERE id = NEW.parent_id;
IF NEW.level <> parent_level + 1 THEN
            RAISE EXCEPTION 'category level % is invalid under a parent of level %',
                NEW.level, parent_level
                USING ERRCODE = 'check_violation';
END IF;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_category_level
    BEFORE INSERT OR UPDATE OF parent_id, level ON categories
    FOR EACH ROW EXECUTE FUNCTION enforce_category_level();

-- Names are unique among siblings, so "Speaking" under IELTS and "Speaking" under
-- another branch are different rows (exact match; fuzzy merging is Phase 15).
CREATE UNIQUE INDEX uq_categories_root_name
    ON categories (name) WHERE parent_id IS NULL;

CREATE UNIQUE INDEX uq_categories_child_name
    ON categories (parent_id, name) WHERE parent_id IS NOT NULL;