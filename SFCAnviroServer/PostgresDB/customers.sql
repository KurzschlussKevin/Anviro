-- Table: anviro.customers

-- DROP TABLE IF EXISTS anviro.customers;

CREATE TABLE IF NOT EXISTS anviro.customers
(
    id bigint NOT NULL DEFAULT nextval('anviro.customers_id_seq'::regclass),
    kundennummer text COLLATE pg_catalog."default" NOT NULL,
    vorname text COLLATE pg_catalog."default" NOT NULL,
    nachname text COLLATE pg_catalog."default" NOT NULL,
    email text COLLATE pg_catalog."default",
    telefon text COLLATE pg_catalog."default",
    mobile text COLLATE pg_catalog."default",
    strasse text COLLATE pg_catalog."default",
    hausnummer text COLLATE pg_catalog."default",
    plz text COLLATE pg_catalog."default",
    stadt text COLLATE pg_catalog."default",
    status_id integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    CONSTRAINT customers_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS anviro.customers
    OWNER to postgres;
-- Index: ix_anviro_customers_id

-- DROP INDEX IF EXISTS anviro.ix_anviro_customers_id;

CREATE INDEX IF NOT EXISTS ix_anviro_customers_id
    ON anviro.customers USING btree
    (id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_anviro_customers_kundennummer

-- DROP INDEX IF EXISTS anviro.ix_anviro_customers_kundennummer;

CREATE UNIQUE INDEX IF NOT EXISTS ix_anviro_customers_kundennummer
    ON anviro.customers USING btree
    (kundennummer COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;