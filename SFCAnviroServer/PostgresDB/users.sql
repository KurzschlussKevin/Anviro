-- Table: anviro.customers

-- DROP TABLE IF EXISTS anviro.customers;

CREATE TABLE IF NOT EXISTS anviro.customers
(
    id bigint NOT NULL DEFAULT nextval('anviro.customers_id_seq'::regclass),
    company text COLLATE pg_catalog."default" NOT NULL,
    customer_number text COLLATE pg_catalog."default" NOT NULL,
    postal_code text COLLATE pg_catalog."default",
    city text COLLATE pg_catalog."default",
    house_number text COLLATE pg_catalog."default",
    street text COLLATE pg_catalog."default",
    contact_name text COLLATE pg_catalog."default",
    email text COLLATE pg_catalog."default",
    phone text COLLATE pg_catalog."default",
    mobile text COLLATE pg_catalog."default",
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT customers_pkey PRIMARY KEY (id),
    CONSTRAINT customers_customer_number_key UNIQUE (customer_number)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS anviro.customers
    OWNER to postgres;
-- Index: idx_customers_customer_number

-- DROP INDEX IF EXISTS anviro.idx_customers_customer_number;

CREATE INDEX IF NOT EXISTS idx_customers_customer_number
    ON anviro.customers USING btree
    (customer_number COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;