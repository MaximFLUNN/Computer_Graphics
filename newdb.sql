--
-- PostgreSQL database dump
--

-- Dumped from database version 15.3
-- Dumped by pg_dump version 15.2

-- Started on 2023-06-08 19:18:24

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 237 (class 1255 OID 57443)
-- Name: add_contact_email(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_contact_email(contact_id_value text, email_value text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Проверяем, существует ли контакт с указанным contact_id
    IF NOT EXISTS(SELECT 1 FROM contacts WHERE contact_id = contact_id_value) THEN
        RAISE EXCEPTION 'Contact with such id does not exist';
    END IF;

    -- Проверяем, что контакт не имеет уже такого емейла
    IF EXISTS(SELECT 1 FROM contact_emails WHERE contact_id = contact_id_value AND email = email_value) THEN
        RAISE EXCEPTION 'Contact already has such email';
    END IF;

    -- Добавляем новый емейл для контакта
    INSERT INTO contact_emails (contact_id, email) VALUES (contact_id_value, email_value);

    RETURN;
END;
$$;


ALTER FUNCTION public.add_contact_email(contact_id_value text, email_value text) OWNER TO postgres;

--
-- TOC entry 238 (class 1255 OID 57444)
-- Name: add_contact_phone(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_contact_phone(contact_id_value text, phone_number_value text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Проверяем, существует ли контакт с указанным contact_id
    IF NOT EXISTS(SELECT 1 FROM contacts WHERE contact_id = contact_id_value) THEN
        RAISE EXCEPTION 'Contact with such id does not exist';
    END IF;

    -- Добавляем новый телефонный номер для контакта
    INSERT INTO contact_phones (contact_id, phone_number) VALUES (contact_id_value, phone_number_value);

    RETURN;
END;
$$;


ALTER FUNCTION public.add_contact_phone(contact_id_value text, phone_number_value text) OWNER TO postgres;

--
-- TOC entry 220 (class 1255 OID 32804)
-- Name: check_unit_func(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_unit_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN 
  IF NEW.prod_unit NOT IN ('Unit', 'Grams', 'Kilograms', 'Liters') THEN
    RAISE EXCEPTION 'Ошибка: текст поля prod_unit должен быть (Unit, Grams, Kilograms, Liters)';
  END IF;
  RETURN NEW;
END;$$;


ALTER FUNCTION public.check_unit_func() OWNER TO postgres;

--
-- TOC entry 236 (class 1255 OID 57368)
-- Name: delete_client_with_sales(text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.delete_client_with_sales(IN client_id_value text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Удаляем все записи из sales, которые связаны с удаляемым клиентом
  DELETE FROM sales WHERE client_id = client_id_value;

  -- Удаляем саму запись с клиентом из таблицы clients
  DELETE FROM clients WHERE client_id = client_id_value;

  RETURN;
END;
$$;


ALTER PROCEDURE public.delete_client_with_sales(IN client_id_value text) OWNER TO postgres;

--
-- TOC entry 232 (class 1255 OID 40970)
-- Name: insert_check_regular(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_check_regular() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN 
	IF ((SELECT client_regular FROM clients WHERE client_id = NEW.client_id) = 'No') THEN
		IF ((SELECT SUM(prod_price) FROM product WHERE prod_id IN 
			(SELECT prod_id FROM sales WHERE client_id = NEW.client_id)) > 5000)
		THEN 
			UPDATE clients SET client_regular = 'Yes' WHERE client_id = NEW.client_id;
		END IF;
	END IF;
	RETURN NEW;
END;$$;


ALTER FUNCTION public.insert_check_regular() OWNER TO postgres;

--
-- TOC entry 233 (class 1255 OID 57344)
-- Name: update_countt_product(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_countt_product() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN 
	IF (SELECT product.prod_count FROM product WHERE product.prod_id = NEW.prod_id) >= NEW.count THEN
		UPDATE product SET prod_count = prod_count - NEW.count WHERE prod_id = NEW.prod_id;
	ELSE 
		RAISE EXCEPTION 'На складе нет товара в нужном количестве!';
		RETURN NULL;
	END IF;
	RETURN NEW;
END;$$;


ALTER FUNCTION public.update_countt_product() OWNER TO postgres;

--
-- TOC entry 234 (class 1255 OID 57365)
-- Name: update_delivery_date(text, date); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.update_delivery_date(IN sid text, IN new_date date)
    LANGUAGE plpgsql
    AS $$
DECLARE
  cur_sales CURSOR FOR SELECT sale_id, delivery_date FROM sales FOR UPDATE;
  curr_id text;
  curr_date date;
BEGIN
  OPEN cur_sales;
  LOOP
    FETCH cur_sales INTO curr_id, curr_date;
    EXIT WHEN NOT FOUND;
	IF curr_id = sid THEN
    	curr_date := new_date; -- добавляем один день к дате
    	UPDATE sales SET delivery_date = curr_date WHERE CURRENT OF cur_sales; -- обновляем запись с помощью курсора
  	END IF;
  END LOOP;
  CLOSE cur_sales;
END;
$$;


ALTER PROCEDURE public.update_delivery_date(IN sid text, IN new_date date) OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 57366)
-- Name: update_sales_date(text, date); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.update_sales_date(IN sid text, IN new_date date)
    LANGUAGE plpgsql
    AS $$
DECLARE
  cur_sales CURSOR FOR SELECT sale_id, sale_date FROM sales FOR UPDATE;
  curr_id text;
  curr_date date;
BEGIN
  OPEN cur_sales;
  LOOP
    FETCH cur_sales INTO curr_id, curr_date;
    EXIT WHEN NOT FOUND;
	IF curr_id = sid THEN
    	curr_date := new_date; -- добавляем один день к дате
    	UPDATE sales SET sale_date = curr_date WHERE CURRENT OF cur_sales; -- обновляем запись с помощью курсора
  	END IF;
  END LOOP;
  CLOSE cur_sales;
END;
$$;


ALTER PROCEDURE public.update_sales_date(IN sid text, IN new_date date) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 215 (class 1259 OID 32776)
-- Name: clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clients (
    client_id text NOT NULL,
    client_last_name text NOT NULL,
    client_first_name text NOT NULL,
    client_middle_name text NOT NULL,
    client_address text NOT NULL,
    client_phone text NOT NULL,
    client_email text NOT NULL,
    client_regular text NOT NULL
);


ALTER TABLE public.clients OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 57419)
-- Name: contact_emails; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contact_emails (
    contact_id text NOT NULL,
    email text NOT NULL
);


ALTER TABLE public.contact_emails OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 57431)
-- Name: contact_phones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contact_phones (
    contact_id text NOT NULL,
    phone_number text NOT NULL
);


ALTER TABLE public.contact_phones OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 57412)
-- Name: contacts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contacts (
    contact_id text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL
);


ALTER TABLE public.contacts OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 32769)
-- Name: product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product (
    prod_id text NOT NULL,
    prod_name text NOT NULL,
    prod_price numeric(12,2) NOT NULL,
    prod_unit text NOT NULL,
    prod_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.product OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 32783)
-- Name: sales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sales (
    sale_id text NOT NULL,
    prod_id text NOT NULL,
    client_id text NOT NULL,
    sale_date date NOT NULL,
    delivery_date date NOT NULL,
    count integer NOT NULL
);


ALTER TABLE public.sales OWNER TO postgres;

--
-- TOC entry 3361 (class 0 OID 32776)
-- Dependencies: 215
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clients (client_id, client_last_name, client_first_name, client_middle_name, client_address, client_phone, client_email, client_regular) FROM stdin;
2	Филатов	Максим	Сергеевич	1 этаж ННГУ	89964433010	999099917@mail.ru	Yes
1	Кочетов	Николай	Алексеевич	Подвал ННГУ	88005553535	nikkochetov@outlook.com	Yes
\.


--
-- TOC entry 3364 (class 0 OID 57419)
-- Dependencies: 218
-- Data for Name: contact_emails; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.contact_emails (contact_id, email) FROM stdin;
1	test1@example.com
\.


--
-- TOC entry 3365 (class 0 OID 57431)
-- Dependencies: 219
-- Data for Name: contact_phones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.contact_phones (contact_id, phone_number) FROM stdin;
\.


--
-- TOC entry 3363 (class 0 OID 57412)
-- Dependencies: 217
-- Data for Name: contacts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.contacts (contact_id, first_name, last_name) FROM stdin;
1	Йа	Йаков
\.


--
-- TOC entry 3360 (class 0 OID 32769)
-- Dependencies: 214
-- Data for Name: product; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product (prod_id, prod_name, prod_price, prod_unit, prod_count) FROM stdin;
1	Микрофон Fifine A8	6100.00	Unit	100
3	Мышка asus keris	3500.00	Unit	0
2	Hoegaarden	69.00	Unit	216
\.


--
-- TOC entry 3362 (class 0 OID 32783)
-- Dependencies: 216
-- Data for Name: sales; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sales (sale_id, prod_id, client_id, sale_date, delivery_date, count) FROM stdin;
1	3	2	2023-08-11	2023-08-13	1
1	3	2	2023-08-11	2023-08-13	1
2	2	1	2023-08-06	2023-08-12	10
\.


--
-- TOC entry 3204 (class 2606 OID 32782)
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (client_id);


--
-- TOC entry 3208 (class 2606 OID 57425)
-- Name: contact_emails contact_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contact_emails
    ADD CONSTRAINT contact_emails_pkey PRIMARY KEY (contact_id, email);


--
-- TOC entry 3210 (class 2606 OID 57437)
-- Name: contact_phones contact_phones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contact_phones
    ADD CONSTRAINT contact_phones_pkey PRIMARY KEY (contact_id, phone_number);


--
-- TOC entry 3206 (class 2606 OID 57418)
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (contact_id);


--
-- TOC entry 3202 (class 2606 OID 32775)
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (prod_id);


--
-- TOC entry 3216 (class 2620 OID 40971)
-- Name: sales insert_check_regular_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER insert_check_regular_trigger BEFORE INSERT ON public.sales FOR EACH ROW EXECUTE FUNCTION public.insert_check_regular();


--
-- TOC entry 3215 (class 2620 OID 32806)
-- Name: product unit_check; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_check AFTER INSERT ON public.product FOR EACH ROW EXECUTE FUNCTION public.check_unit_func();


--
-- TOC entry 3217 (class 2620 OID 57345)
-- Name: sales update_product_count_on_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_product_count_on_insert BEFORE INSERT ON public.sales FOR EACH ROW EXECUTE FUNCTION public.update_countt_product();


--
-- TOC entry 3211 (class 2606 OID 49166)
-- Name: sales clients_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT clients_id FOREIGN KEY (client_id) REFERENCES public.clients(client_id) NOT VALID;


--
-- TOC entry 3213 (class 2606 OID 57426)
-- Name: contact_emails contact_email_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contact_emails
    ADD CONSTRAINT contact_email_fk FOREIGN KEY (contact_id) REFERENCES public.contacts(contact_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3214 (class 2606 OID 57438)
-- Name: contact_phones contact_phone_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contact_phones
    ADD CONSTRAINT contact_phone_fk FOREIGN KEY (contact_id) REFERENCES public.contacts(contact_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3212 (class 2606 OID 49171)
-- Name: sales product_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT product_id FOREIGN KEY (prod_id) REFERENCES public.product(prod_id) NOT VALID;


-- Completed on 2023-06-08 19:18:24

--
-- PostgreSQL database dump complete
--

