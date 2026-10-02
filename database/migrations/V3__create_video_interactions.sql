-- Phase 1 / plan §6.4, §5 Rule 5. Append-only history.

CREATE TABLE video_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    video_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_interaction_video
        FOREIGN KEY (video_id) REFERENCES videos(id),
    CONSTRAINT chk_interaction_action
        CHECK (action IN ('SAVED', 'OPENED', 'REOPENED', 'DELETED'))
);

CREATE INDEX idx_interactions_video_id ON video_interactions(video_id);
CREATE INDEX idx_interactions_user_id  ON video_interactions(user_id);

-- Interaction history must never be overwritten or removed.
CREATE FUNCTION forbid_interaction_mutation() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'video_interactions is append-only';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_interactions_append_only
    BEFORE UPDATE OR DELETE ON video_interactions
    FOR EACH ROW EXECUTE FUNCTION forbid_interaction_mutation();
