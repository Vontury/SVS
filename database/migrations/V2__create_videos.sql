-- Phase 1 / plan §6.2, §7, §8.
-- user_id intentionally has no FK: it references Supabase's auth.users(id),
-- which does not exist in a plain local PostgreSQL.

CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    url TEXT NOT NULL,
    platform VARCHAR(50),
    title TEXT,
    description TEXT,
    summary TEXT,
    category_id UUID,
    status VARCHAR(30) NOT NULL DEFAULT 'PROCESSING',
    saved_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    first_opened_at TIMESTAMP WITH TIME ZONE,
    last_opened_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_video_category
        FOREIGN KEY (category_id) REFERENCES categories(id),
    CONSTRAINT chk_video_status
        CHECK (status IN ('PROCESSING', 'COMPLETED', 'FAILED'))
);

CREATE INDEX idx_videos_user_id        ON videos(user_id);
CREATE INDEX idx_videos_category_id    ON videos(category_id);
CREATE INDEX idx_videos_last_opened_at ON videos(last_opened_at);
CREATE INDEX idx_videos_saved_at       ON videos(saved_at);
