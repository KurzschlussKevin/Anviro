-- Table: anviro.sales_items

-- DROP TABLE IF EXISTS anviro.sales_items;

CREATE TABLE IF NOT EXISTS anviro.sales_items
(
    id bigint NOT NULL DEFAULT nextval('anviro.sales_items_id_seq'::regclass),
    sale_id bigint NOT NULL,
    position_nr text COLLATE pg_catalog."default",
    bezeichnung text COLLATE pg_catalog."default" NOT NULL,
    gruppe text COLLATE pg_catalog."default",
    menge double precision DEFAULT 0.0,
    einzelpreis double precision DEFAULT 0.0,
    gesamt double precision DEFAULT 0.0,
    CONSTRAINT sales_items_pkey PRIMARY KEY (id),
    CONSTRAINT fk_items_sale FOREIGN KEY (sale_id)
        REFERENCES anviro.sales (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS anviro.sales_items
    OWNER to postgres;