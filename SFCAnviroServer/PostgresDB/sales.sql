-- Table: anviro.sales

-- DROP TABLE IF EXISTS anviro.sales;

CREATE TABLE IF NOT EXISTS anviro.sales
(
    id bigint NOT NULL DEFAULT nextval('anviro.sales_id_seq'::regclass),
    customer_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT sales_pkey PRIMARY KEY (id),
    CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id)
        REFERENCES anviro.customers (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_sales_user FOREIGN KEY (user_id)
        REFERENCES anviro.users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS anviro.sales
    OWNER to postgres;