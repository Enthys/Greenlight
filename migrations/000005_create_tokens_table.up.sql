CREATE TABLE IF NOT EXISTS tokens (
	hash bytea PRIMARY KEY,
	user_id bigint NOT NULL REFERENCES users ON DELETE CASCADE,
	expiry timestamp(0) WITH time zone NOT NULL,
	scope text NOT NULL
);
