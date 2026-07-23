--
-- PostgreSQL database dump
--

\restrict qTS7jXzgNRnYwcQYyA1WUEHIdkyuuXIaIyzzD89zwc6p2IbWSHblIIEp4DcWOid

-- Dumped from database version 13.23
-- Dumped by pg_dump version 13.23

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'WIN1252';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: dim_date; Type: TABLE DATA; Schema: ndbc_dw; Owner: -
--

COPY ndbc_dw.dim_date (date_key, full_date, day_of_month, iso_day_of_week, day_name, week_of_year, month_number, month_name, quarter_number, year_number, is_weekend) FROM stdin;
20260503	2026-05-03	3	7	Sunday	18	5	May	2	2026	t
20260504	2026-05-04	4	1	Monday	19	5	May	2	2026	f
20260505	2026-05-05	5	2	Tuesday	19	5	May	2	2026	f
20260506	2026-05-06	6	3	Wednesday	19	5	May	2	2026	f
20260507	2026-05-07	7	4	Thursday	19	5	May	2	2026	f
20260508	2026-05-08	8	5	Friday	19	5	May	2	2026	f
20260509	2026-05-09	9	6	Saturday	19	5	May	2	2026	t
20260510	2026-05-10	10	7	Sunday	19	5	May	2	2026	t
20260511	2026-05-11	11	1	Monday	20	5	May	2	2026	f
20260512	2026-05-12	12	2	Tuesday	20	5	May	2	2026	f
20260513	2026-05-13	13	3	Wednesday	20	5	May	2	2026	f
20260514	2026-05-14	14	4	Thursday	20	5	May	2	2026	f
20260515	2026-05-15	15	5	Friday	20	5	May	2	2026	f
20260516	2026-05-16	16	6	Saturday	20	5	May	2	2026	t
20260517	2026-05-17	17	7	Sunday	20	5	May	2	2026	t
20260518	2026-05-18	18	1	Monday	21	5	May	2	2026	f
20260519	2026-05-19	19	2	Tuesday	21	5	May	2	2026	f
20260520	2026-05-20	20	3	Wednesday	21	5	May	2	2026	f
20260521	2026-05-21	21	4	Thursday	21	5	May	2	2026	f
20260522	2026-05-22	22	5	Friday	21	5	May	2	2026	f
20260523	2026-05-23	23	6	Saturday	21	5	May	2	2026	t
20260524	2026-05-24	24	7	Sunday	21	5	May	2	2026	t
20260525	2026-05-25	25	1	Monday	22	5	May	2	2026	f
20260526	2026-05-26	26	2	Tuesday	22	5	May	2	2026	f
20260527	2026-05-27	27	3	Wednesday	22	5	May	2	2026	f
20260528	2026-05-28	28	4	Thursday	22	5	May	2	2026	f
20260529	2026-05-29	29	5	Friday	22	5	May	2	2026	f
20260530	2026-05-30	30	6	Saturday	22	5	May	2	2026	t
20260531	2026-05-31	31	7	Sunday	22	5	May	2	2026	t
20260601	2026-06-01	1	1	Monday	23	6	June	2	2026	f
20260602	2026-06-02	2	2	Tuesday	23	6	June	2	2026	f
20260603	2026-06-03	3	3	Wednesday	23	6	June	2	2026	f
20260604	2026-06-04	4	4	Thursday	23	6	June	2	2026	f
20260605	2026-06-05	5	5	Friday	23	6	June	2	2026	f
20260606	2026-06-06	6	6	Saturday	23	6	June	2	2026	t
20260607	2026-06-07	7	7	Sunday	23	6	June	2	2026	t
20260608	2026-06-08	8	1	Monday	24	6	June	2	2026	f
20260609	2026-06-09	9	2	Tuesday	24	6	June	2	2026	f
20260610	2026-06-10	10	3	Wednesday	24	6	June	2	2026	f
20260611	2026-06-11	11	4	Thursday	24	6	June	2	2026	f
20260612	2026-06-12	12	5	Friday	24	6	June	2	2026	f
20260613	2026-06-13	13	6	Saturday	24	6	June	2	2026	t
20260614	2026-06-14	14	7	Sunday	24	6	June	2	2026	t
20260615	2026-06-15	15	1	Monday	25	6	June	2	2026	f
20260616	2026-06-16	16	2	Tuesday	25	6	June	2	2026	f
20260617	2026-06-17	17	3	Wednesday	25	6	June	2	2026	f
20260618	2026-06-18	18	4	Thursday	25	6	June	2	2026	f
20260619	2026-06-19	19	5	Friday	25	6	June	2	2026	f
20260620	2026-06-20	20	6	Saturday	25	6	June	2	2026	t
20260621	2026-06-21	21	7	Sunday	25	6	June	2	2026	t
20260622	2026-06-22	22	1	Monday	26	6	June	2	2026	f
20260623	2026-06-23	23	2	Tuesday	26	6	June	2	2026	f
20260624	2026-06-24	24	3	Wednesday	26	6	June	2	2026	f
20260625	2026-06-25	25	4	Thursday	26	6	June	2	2026	f
20260626	2026-06-26	26	5	Friday	26	6	June	2	2026	f
20260627	2026-06-27	27	6	Saturday	26	6	June	2	2026	t
20260628	2026-06-28	28	7	Sunday	26	6	June	2	2026	t
20260629	2026-06-29	29	1	Monday	27	6	June	2	2026	f
20260630	2026-06-30	30	2	Tuesday	27	6	June	2	2026	f
20260701	2026-07-01	1	3	Wednesday	27	7	July	3	2026	f
20260702	2026-07-02	2	4	Thursday	27	7	July	3	2026	f
20260703	2026-07-03	3	5	Friday	27	7	July	3	2026	f
20260704	2026-07-04	4	6	Saturday	27	7	July	3	2026	t
20260705	2026-07-05	5	7	Sunday	27	7	July	3	2026	t
20260706	2026-07-06	6	1	Monday	28	7	July	3	2026	f
20260707	2026-07-07	7	2	Tuesday	28	7	July	3	2026	f
20260708	2026-07-08	8	3	Wednesday	28	7	July	3	2026	f
20260709	2026-07-09	9	4	Thursday	28	7	July	3	2026	f
20260710	2026-07-10	10	5	Friday	28	7	July	3	2026	f
20260711	2026-07-11	11	6	Saturday	28	7	July	3	2026	t
20260712	2026-07-12	12	7	Sunday	28	7	July	3	2026	t
20260713	2026-07-13	13	1	Monday	29	7	July	3	2026	f
20260714	2026-07-14	14	2	Tuesday	29	7	July	3	2026	f
20260715	2026-07-15	15	3	Wednesday	29	7	July	3	2026	f
20260716	2026-07-16	16	4	Thursday	29	7	July	3	2026	f
20260717	2026-07-17	17	5	Friday	29	7	July	3	2026	f
20260718	2026-07-18	18	6	Saturday	29	7	July	3	2026	t
20260719	2026-07-19	19	7	Sunday	29	7	July	3	2026	t
20260720	2026-07-20	20	1	Monday	30	7	July	3	2026	f
20260721	2026-07-21	21	2	Tuesday	30	7	July	3	2026	f
20260722	2026-07-22	22	3	Wednesday	30	7	July	3	2026	f
20260723	2026-07-23	23	4	Thursday	30	7	July	3	2026	f
\.


--
-- Data for Name: dim_scrape_run; Type: TABLE DATA; Schema: ndbc_dw; Owner: -
--

COPY ndbc_dw.dim_scrape_run (scrape_run_key, scrape_run_id, started_at, finished_at, target_met, station_list_source_url, source_output_directory, source_loaded_at, dw_created_at, dw_updated_at) FROM stdin;
1	ndbc-20260723-101648-3184b99631	2026-07-23 17:16:48.964552+07	2026-07-23 17:26:53.111285+07	t	https://www.ndbc.noaa.gov/to_station.shtml	D:\\ZIZAKAYA\\Asisten Basis Data\\Seleksi-2026-Tugas-1\\Automated Scheduling\\runs\\pipeline-20260723-101640	2026-07-23 17:27:09.27017+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
2	ndbc-20260723-061419-0c3bbdce81	2026-07-23 13:14:19.412435+07	2026-07-23 13:24:10.318476+07	t	https://www.ndbc.noaa.gov/to_station.shtml	D:\\ZIZAKAYA\\Asisten Basis Data\\Seleksi-2026-Tugas-1\\Data Scraping\\data	2026-07-23 15:41:00.918213+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
3	ndbc-20260723-103155-0974ed7ac0	2026-07-23 17:31:55.96113+07	2026-07-23 17:41:55.677945+07	t	https://www.ndbc.noaa.gov/to_station.shtml	D:\\ZIZAKAYA\\Asisten Basis Data\\Seleksi-2026-Tugas-1\\Automated Scheduling\\runs\\pipeline-20260723-103152	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
\.


--
-- Data for Name: dim_station; Type: TABLE DATA; Schema: ndbc_dw; Owner: -
--

COPY ndbc_dw.dim_station (station_key, station_id, station_name, location, device_type, payload, latitude, longitude, water_depth_meter, station_status, provider_name, provider_base_url, detail_url, realtime_data_url, source_created_at, source_updated_at, dw_created_at, dw_updated_at) FROM stdin;
1	41010	CANAVERAL EAST	120NM East of Cape Canaveral	2.1-meter ionomer foam buoy	SCOOP payload	28.86	-78.478	903.1	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41010	https://www.ndbc.noaa.gov/data/realtime2/41010.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
2	41013	Frying Pan Shoals, NC	\N	3-meter discus buoy	SCOOP payload	33.436	-77.764	30.8	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41013	https://www.ndbc.noaa.gov/data/realtime2/41013.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
3	41025	Diamond Shoals, NC	\N	3-meter foam buoy	SCOOP payload	35.026	-75.38	61	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41025	https://www.ndbc.noaa.gov/data/realtime2/41025.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
4	41040	NORTH EQUATORIAL ONE- 470 NM East of Martinique	\N	3-meter foam buoy	SCOOP payload	14.568	-53.037	5069	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41040	https://www.ndbc.noaa.gov/data/realtime2/41040.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
5	41041	NORTH EQUATORIAL TWO	890 NM East of Martinique	2.1-meter ionomer foam buoy	SCOOP payload	14.259	-46.052	3506	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41041	https://www.ndbc.noaa.gov/data/realtime2/41041.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
6	41043	NE PUERTO RICO	170 NM NNE of San Juan, PR	3-meter foam buoy	SCOOP payload	21.09	-64.864	5286	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41043	https://www.ndbc.noaa.gov/data/realtime2/41043.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
7	41044	NE ST MARTIN	330 NM NE St Martin Is	3-meter discus buoy	SCOOP payload	21.582	-58.63	5419	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41044	https://www.ndbc.noaa.gov/data/realtime2/41044.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
8	41046	EAST BAHAMAS	335 NM East of San Salvador Is, Bahamas	3-meter foam buoy	SCOOP payload	23.84	-68.34	5553	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41046	https://www.ndbc.noaa.gov/data/realtime2/41046.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
9	41047	NE BAHAMAS	350 NM ENE of Nassau, Bahamas	3-meter foam buoy	SCOOP payload	27.557	-71.48	5328	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41047	https://www.ndbc.noaa.gov/data/realtime2/41047.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
10	41048	WEST BERMUDA	240 NM West of Bermuda	3-meter foam buoy	SCOOP payload	31.89	-69.708	5410	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41048	https://www.ndbc.noaa.gov/data/realtime2/41048.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
11	41049	SOUTH BERMUDA	300 NM SSE of Bermuda	3-meter foam buoy	SCOOP payload	27.505	-62.271	5480	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41049	https://www.ndbc.noaa.gov/data/realtime2/41049.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
12	42001	MID GULF	180 nm South of Southwest Pass, LA	3-meter foam buoy	SCOOP payload	25.922	-89.638	3195	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=42001	https://www.ndbc.noaa.gov/data/realtime2/42001.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
13	42002	WEST GULF	207 NM East of Brownsville, TX	3-meter foam buoy	SCOOP payload	25.95	-93.78	3208	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=42002	https://www.ndbc.noaa.gov/data/realtime2/42002.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
14	42012	ORANGE BEACH	44 NM SE of Mobile, AL	3-meter discus buoy	Athena payload	30.061	-87.547	27	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=42012	https://www.ndbc.noaa.gov/data/realtime2/42012.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
15	42035	GALVESTON,TX	22 NM East of Galveston, TX	3-meter foam buoy	SCOOP payload	29.235	-94.41	15.5	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=42035	https://www.ndbc.noaa.gov/data/realtime2/42035.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
16	42036	WEST TAMPA	112 NM WNW of Tampa, FL	3-meter discus buoy	SCOOP payload	28.5	-84.505	53.3	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=42036	https://www.ndbc.noaa.gov/data/realtime2/42036.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
17	42039	PENSACOLA	115NM SSE of Pensacola, FL	2.1-meter ionomer foam buoy	SCOOP payload	28.768	-86.024	297	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=42039	https://www.ndbc.noaa.gov/data/realtime2/42039.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
18	42040	LUKE OFFSHORE TEST PLATFORM	63 NM South of Dauphin Island, AL	3-meter foam buoy	SCOOP payload	29.207	-88.237	192	NO_RECENT_DATA	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=42040	https://www.ndbc.noaa.gov/data/realtime2/42040.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
19	42055	BAY OF CAMPECHE	214 NM NE of Veracruz, MX	3-meter foam buoy	SCOOP payload	22.14	-94.112	3608	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=42055	https://www.ndbc.noaa.gov/data/realtime2/42055.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
20	42056	Yucatan Basin	120 NM ESE of Cozumel, MX	3-meter foam buoy	SCOOP payload	19.82	-84.98	4578	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=42056	https://www.ndbc.noaa.gov/data/realtime2/42056.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
21	42057	Western Caribbean	195 NM WSW of Negril, Jamaica	3-meter discus buoy	SCOOP payload	16.975	-81.578	412	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=42057	https://www.ndbc.noaa.gov/data/realtime2/42057.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
22	42058	Central Caribbean	210 NM SSE of Kingston, Jamaica	3-meter foam buoy	SCOOP payload	14.114	-75.949	3953	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=42058	https://www.ndbc.noaa.gov/data/realtime2/42058.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
23	42059	Eastern Caribbean Sea	180 NM SSW of Ponce, PR	3-meter foam buoy	SCOOP payload	15.255	-67.621	4779	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=42059	https://www.ndbc.noaa.gov/data/realtime2/42059.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
24	42060	Caribbean Valley	63 NM WSW of Montserrat	3-meter foam buoy	SCOOP payload	16.428	-63.21	1556	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=42060	https://www.ndbc.noaa.gov/data/realtime2/42060.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
25	44007	PORTLAND	12 NM Southeast of Portland,ME	3-meter discus buoy	SCOOP payload	43.525	-70.14	49	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=44007	https://www.ndbc.noaa.gov/data/realtime2/44007.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
26	44008	NANTUCKET 54 NM Southeast of Nantucket	\N	3-meter discus buoy	SCOOP payload	40.5	-69.254	73	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=44008	https://www.ndbc.noaa.gov/data/realtime2/44008.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
27	44009	DELAWARE BAY 26 NM Southeast of Cape May, NJ	\N	3-meter discus buoy	SCOOP payload	38.46	-74.692	24	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=44009	https://www.ndbc.noaa.gov/data/realtime2/44009.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
28	44011	GEORGES BANK 170 NM East of Hyannis, MA	\N	3-meter foam buoy	SCOOP payload	41.088	-66.546	90.2	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=44011	https://www.ndbc.noaa.gov/data/realtime2/44011.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
29	44013	BOSTON 16 NM East of Boston, MA	\N	2.1-meter ionomer foam buoy	SCOOP payload	42.346	-70.651	64.6	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=44013	https://www.ndbc.noaa.gov/data/realtime2/44013.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
30	44014	VIRGINIA BEACH 64 NM East of Virginia Beach, VA	\N	2.1-meter ionomer foam buoy	SCOOP payload	36.603	-74.837	49.1	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=44014	https://www.ndbc.noaa.gov/data/realtime2/44014.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
31	44025	LONG ISLAND	30 NM South of Islip, NY	3-meter foam buoy	SCOOP payload	40.258	-73.175	40.2	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=44025	https://www.ndbc.noaa.gov/data/realtime2/44025.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
32	44027	Jonesport, ME	20 NM SE of Jonesport, ME	3-meter foam buoy	SCOOP payload	44.284	-67.301	188	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=44027	https://www.ndbc.noaa.gov/data/realtime2/44027.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
33	44065	New York Harbor Entrance	15 NM SE of Breezy Point , NY	3-meter foam buoy	SCOOP payload	40.368	-73.701	26	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=44065	https://www.ndbc.noaa.gov/data/realtime2/44065.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
34	45001	MID SUPERIOR- 60 NM North Northeast Hancock, MI	\N	2.1-meter ionomer foam buoy	SCOOP payload	48.061	-87.793	247	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=45001	https://www.ndbc.noaa.gov/data/realtime2/45001.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
35	45002	NORTH MICHIGAN- Halfway between North Manitou and Washington Islands.	\N	2.1-meter ionomer foam buoy	SCOOP payload	45.344	-86.411	181.4	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=45002	https://www.ndbc.noaa.gov/data/realtime2/45002.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
36	45004	EAST SUPERIOR -70 NM NE Marquette, MI	\N	2.3-meter foam discus buoy	SCOOP payload	47.583	-86.586	237.2	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=45004	https://www.ndbc.noaa.gov/data/realtime2/45004.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
37	45005	WEST ERIE	16 NM NW of Lorain, OH	2.3-meter foam discus buoy	SCOOP payload	41.677	-82.398	9.8	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=45005	https://www.ndbc.noaa.gov/data/realtime2/45005.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
38	45006	WEST SUPERIOR	30NM NE of Outer Island, WI	2.3-meter foam discus buoy	SCOOP payload	47.335	-89.793	194.5	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=45006	https://www.ndbc.noaa.gov/data/realtime2/45006.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
39	45012	EAST Lake Ontario	20NM North Northeast of Rochester, NY	2.3-meter foam discus buoy	SCOOP payload	43.621	-77.401	143.3	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=45012	https://www.ndbc.noaa.gov/data/realtime2/45012.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
40	46001	WESTERN GULF OF ALASKA	175NM SE of Kodiak, AK	3-meter foam buoy w/ seal cage	SCOOP payload	56.296	-148.027	4123	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46001	https://www.ndbc.noaa.gov/data/realtime2/46001.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
41	46002	WEST OREGON	275NM West of Coos Bay, OR	3-meter foam buoy w/ seal cage	SCOOP payload	42.56	-130.523	3438	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46002	https://www.ndbc.noaa.gov/data/realtime2/46002.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
42	46005	WEST WASHINGTON	300NM West of Aberdeen, WA	3-meter foam buoy	SCOOP payload	46.147	-131.077	2811	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46005	https://www.ndbc.noaa.gov/data/realtime2/46005.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
43	46006	SOUTHEAST PAPA	600NM West of Eureka, CA	3-meter foam buoy	SCOOP payload	40.73	-137.42	4335	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46006	https://www.ndbc.noaa.gov/data/realtime2/46006.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
44	46011	SANTA MARIA	21NM NW of Point Arguello, CA	3-meter discus buoy w/ seal cage	SCOOP payload	34.937	-120.999	416	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46011	https://www.ndbc.noaa.gov/data/realtime2/46011.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
45	46013	BODEGA BAY	48NM NW of San Francisco, CA	3-meter discus buoy w/ seal cage	SCOOP payload	38.235	-123.317	128.3	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46013	https://www.ndbc.noaa.gov/data/realtime2/46013.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
46	46014	PT ARENA	19NM North of Point Arena, CA	3-meter discus buoy w/ seal cage	SCOOP payload	39.225	-123.98	335	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46014	https://www.ndbc.noaa.gov/data/realtime2/46014.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
47	46015	PORT ORFORD	15 NM West of Port Orford, OR	3-meter discus buoy w/ seal cage	SCOOP payload	42.754	-124.839	446	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46015	https://www.ndbc.noaa.gov/data/realtime2/46015.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
48	46022	EEL RIVER	17NM WSW of Eureka, CA	3-meter foam buoy w/ seal cage	SCOOP payload	40.716	-124.54	456	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46022	https://www.ndbc.noaa.gov/data/realtime2/46022.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
49	46025	Santa Monica Basin	33NM WSW of Santa Monica, CA	3-meter discus buoy w/ seal cage	SCOOP payload	33.765	-119.077	868	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46025	https://www.ndbc.noaa.gov/data/realtime2/46025.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
50	46026	SAN FRANCISCO	18NM West of San Francisco, CA	3-meter foam buoy	SCOOP payload	37.75	-122.838	53	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46026	https://www.ndbc.noaa.gov/data/realtime2/46026.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
51	46027	ST GEORGES	8 NM NW of Crescent City, CA	3-meter discus buoy w/ seal cage	SCOOP payload	41.84	-124.382	60	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46027	https://www.ndbc.noaa.gov/data/realtime2/46027.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
52	46028	CAPE SAN MARTIN	55NM West NW of Morro Bay, CA	3-meter foam buoy w/ seal cage	SCOOP payload	35.763	-121.9	1136	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46028	https://www.ndbc.noaa.gov/data/realtime2/46028.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
53	46029	COLUMBIA RIVER BAR	20NM West of Columbia River Mouth	2.1-meter ionomer foam buoy w/ seal cage	SCOOP payload	46.148	-124.508	135	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46029	https://www.ndbc.noaa.gov/data/realtime2/46029.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
54	46035	CENTRAL BERING SEA	310 NM North of Adak, AK	3-meter foam buoy	SCOOP payload	57.034	-177.468	3696	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46035	https://www.ndbc.noaa.gov/data/realtime2/46035.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
55	46041	CAPE ELIZABETH	45NM NW of Aberdeen, WA	3-meter discus buoy w/ seal cage	SCOOP payload	47.352	-124.739	131	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46041	https://www.ndbc.noaa.gov/data/realtime2/46041.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
56	46042	MONTEREY	27NM WNW of Monterey, CA	3-meter foam buoy w/ seal cage	SCOOP payload	36.787	-122.408	1710	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46042	https://www.ndbc.noaa.gov/data/realtime2/46042.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
57	46047	TANNER BANK	121 NM West of San Diego, CA	3-meter foam buoy	SCOOP payload	32.418	-119.535	1390	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46047	https://www.ndbc.noaa.gov/data/realtime2/46047.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
58	46050	STONEWALL BANK	20NM West of Newport, OR	3-meter foam buoy	SCOOP payload	44.679	-124.535	149	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46050	https://www.ndbc.noaa.gov/data/realtime2/46050.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
59	46053	EAST SANTA BARBARA	12NM Southwest of Santa Barbara, CA	3-meter foam buoy w/ seal cage	SCOOP payload	34.246	-119.842	417	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46053	https://www.ndbc.noaa.gov/data/realtime2/46053.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
60	46054	WEST SANTA BARBARA 38 NM West of Santa Barbara, CA	\N	3-meter discus buoy w/ seal cage	SCOOP payload	34.274	-120.468	454	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46054	https://www.ndbc.noaa.gov/data/realtime2/46054.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
61	46059	WEST CALIFORNIA	357NM West of San Francisco, CA	3-meter discus buoy	SCOOP payload	38.067	-129.895	4620	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46059	https://www.ndbc.noaa.gov/data/realtime2/46059.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
62	46060	WEST ORCA BAY	8NM NW of Hinchinbrook Is., AK	3-meter foam buoy w/ seal cage	SCOOP payload	60.571	-146.795	430	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46060	https://www.ndbc.noaa.gov/data/realtime2/46060.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
63	46061	Seal Rocks	Between Montague and Hinchinbrook Islands, AK	3-meter discus buoy w/ seal cage	SCOOP payload	60.23	-146.837	215	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46061	https://www.ndbc.noaa.gov/data/realtime2/46061.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
64	46066	SOUTH KODIAK	310NM SSW of Kodiak, AK	3-meter discus buoy	SCOOP payload	52.776	-154.992	4459	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46066	https://www.ndbc.noaa.gov/data/realtime2/46066.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
65	46069	SOUTH SANTA ROSA	14 NM SW of Santa Rosa Island, CA	3-meter foam buoy w/ seal cage	SCOOP payload	33.657	-120.227	985	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46069	https://www.ndbc.noaa.gov/data/realtime2/46069.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
66	46070	SOUTHWEST BERING SEA	142NM NNE OF ATTU IS, AK	3-meter foam buoy	SCOOP payload	55.048	175.246	3848	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46070	https://www.ndbc.noaa.gov/data/realtime2/46070.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
67	46071	WESTERN ALEUTIANS	14NM SOUTH OF AMCHITKA IS, AK	3-meter discus buoy w/ seal cage	SCOOP payload	51.035	179.808	4058	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46071	https://www.ndbc.noaa.gov/data/realtime2/46071.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
68	46072	CENTRAL ALEUTIANS 230 NM SW Dutch Harbor	\N	3-meter discus buoy	SCOOP payload	51.645	-172.145	3589	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46072	https://www.ndbc.noaa.gov/data/realtime2/46072.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
69	46073	SOUTHEAST BERING SEA	205 NM WNW of Dutch Harbor, AK	3-meter discus buoy	SCOOP payload	54.985	-171.874	3445	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46073	https://www.ndbc.noaa.gov/data/realtime2/46073.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
70	46075	SHUMAGIN ISLANDS	85NM South of Sand Point, AK	3-meter discus buoy w/ seal cage	SCOOP payload	53.938	-160.735	2520	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46075	https://www.ndbc.noaa.gov/data/realtime2/46075.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
71	46076	CAPE CLEARE	17 NM South of Montague Is, AK	3-meter discus buoy w/ seal cage	SCOOP payload	59.508	-148.005	200	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46076	https://www.ndbc.noaa.gov/data/realtime2/46076.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
72	46077	SHELIKOF STRAIT, AK	\N	3-meter discus buoy w/ seal cage	SCOOP payload	57.869	-154.211	200	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46077	https://www.ndbc.noaa.gov/data/realtime2/46077.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
73	46078	ALBATROSS BANK	104NM South of Kodiak Is., AK	3-meter discus buoy w/ seal cage	SCOOP payload	55.561	-152.599	5361	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46078	https://www.ndbc.noaa.gov/data/realtime2/46078.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
74	46080	PORTLOCK BANK	76 NM ENE of Kodiak, AK	3-meter discus buoy w/ seal cage	SCOOP payload	57.91	-150.129	220	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46080	https://www.ndbc.noaa.gov/data/realtime2/46080.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
75	41001	EAST HATTERAS	150 NM East of Cape Hatteras	3-meter foam buoy	SCOOP payload	34.791	-72.42	4450	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41001	https://www.ndbc.noaa.gov/data/realtime2/41001.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
76	41002	SOUTH HATTERAS	225 NM South of Cape Hatteras	3-meter foam buoy	SCOOP payload	31.743	-74.955	3666	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41002	https://www.ndbc.noaa.gov/data/realtime2/41002.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
77	41004	EDISTO	41 NM Southeast of Charleston, SC	3-meter foam buoy	SCOOP payload	32.502	-79.099	35	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41004	https://www.ndbc.noaa.gov/data/realtime2/41004.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
78	41008	GRAYS REEF	40 NM Southeast of Savannah, GA	3-meter discus buoy	SCOOP payload	31.4	-80.866	16	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41008	https://www.ndbc.noaa.gov/data/realtime2/41008.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
79	41009	CANAVERAL 20 NM East of Cape Canaveral, FL	\N	3-meter discus buoy	SCOOP payload	28.508	-80.185	42	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=41009	https://www.ndbc.noaa.gov/data/realtime2/41009.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
80	44020	NANTUCKET SOUND	\N	3-meter foam buoy	SCOOP payload	41.497	-70.283	16.5	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=44020	https://www.ndbc.noaa.gov/data/realtime2/44020.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
81	46081	Western Prince William Sound	\N	3-meter discus buoy w/ seal cage	SCOOP payload	60.802	-148.283	327	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46081	https://www.ndbc.noaa.gov/data/realtime2/46081.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
82	46082	Cape Suckling	35 NM SE of Kayak Is, AK	3-meter discus buoy w/ seal cage	SCOOP payload	59.67	-143.353	296	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46082	https://www.ndbc.noaa.gov/data/realtime2/46082.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
83	46083	FAIRWEATHER GROUND	105 NM West of Juneau, AK	3-meter discus buoy	SCOOP payload	58.276	-138.024	131	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46083	https://www.ndbc.noaa.gov/data/realtime2/46083.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
84	46084	CAPE EDGECUMBE	25NM SSW of Cape Edgecumbe, AK	3-meter discus buoy w/ seal cage	SCOOP payload	56.614	-136.04	1149	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46084	https://www.ndbc.noaa.gov/data/realtime2/46084.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
85	46085	CENTRAL GULF OF ALASKA	265NM West of Cape Ommaney, AK	3-meter foam buoy	SCOOP payload	55.84	-142.895	3749	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46085	https://www.ndbc.noaa.gov/data/realtime2/46085.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
86	46086	SAN CLEMENTE BASIN	27NM SE Of San Clemente Is, CA	2.1-meter ionomer foam buoy	SCOOP payload	32.504	-118.029	1862	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46086	https://www.ndbc.noaa.gov/data/realtime2/46086.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
87	46087	Neah Bay	6 NM North of Cape Flattery, WA (Traffic Separation Lighted Buoy)	3-meter discus buoy w/ seal cage	SCOOP payload	48.493	-124.727	259	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46087	https://www.ndbc.noaa.gov/data/realtime2/46087.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
88	46088	NEW DUNGENESS	17 NM NE of Port Angeles, WA	3-meter discus buoy w/ seal cage	SCOOP payload	48.332	-123.179	115.5	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46088	https://www.ndbc.noaa.gov/data/realtime2/46088.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
89	46089	TILLAMOOK, OR	85 NM WNW of Tillamook, OR	3-meter discus buoy w/ seal cage	SCOOP payload	45.928	-125.815	2360	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=46089	https://www.ndbc.noaa.gov/data/realtime2/46089.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
90	51000	NORTHERN HAWAII ONE	245NM NE of Honolulu HI	3-meter foam buoy	SCOOP payload	23.534	-153.752	4848	ACTIVE	National Data Buoy Center	https://www.ndbc.noaa.gov	https://www.ndbc.noaa.gov/station_page.php?station=51000	https://www.ndbc.noaa.gov/data/realtime2/51000.txt	2026-07-23 15:41:00.918213+07	2026-07-23 17:42:04.373661+07	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07
\.


--
-- Data for Name: dim_time; Type: TABLE DATA; Schema: ndbc_dw; Owner: -
--

COPY ndbc_dw.dim_time (time_key, full_time, hour_number, minute_number, second_number, minute_of_day, time_bucket) FROM stdin;
0	00:00:00	0	0	0	0	00:00-05:59
900	00:09:00	0	9	0	9	00:00-05:59
1000	00:10:00	0	10	0	10	00:00-05:59
2000	00:20:00	0	20	0	20	00:00-05:59
3000	00:30:00	0	30	0	30	00:00-05:59
3900	00:39:00	0	39	0	39	00:00-05:59
4000	00:40:00	0	40	0	40	00:00-05:59
5000	00:50:00	0	50	0	50	00:00-05:59
10000	01:00:00	1	0	0	60	00:00-05:59
10900	01:09:00	1	9	0	69	00:00-05:59
11000	01:10:00	1	10	0	70	00:00-05:59
12000	01:20:00	1	20	0	80	00:00-05:59
13000	01:30:00	1	30	0	90	00:00-05:59
13900	01:39:00	1	39	0	99	00:00-05:59
14000	01:40:00	1	40	0	100	00:00-05:59
15000	01:50:00	1	50	0	110	00:00-05:59
20000	02:00:00	2	0	0	120	00:00-05:59
20900	02:09:00	2	9	0	129	00:00-05:59
21000	02:10:00	2	10	0	130	00:00-05:59
22000	02:20:00	2	20	0	140	00:00-05:59
23000	02:30:00	2	30	0	150	00:00-05:59
23900	02:39:00	2	39	0	159	00:00-05:59
24000	02:40:00	2	40	0	160	00:00-05:59
25000	02:50:00	2	50	0	170	00:00-05:59
25800	02:58:00	2	58	0	178	00:00-05:59
30000	03:00:00	3	0	0	180	00:00-05:59
30900	03:09:00	3	9	0	189	00:00-05:59
31000	03:10:00	3	10	0	190	00:00-05:59
32000	03:20:00	3	20	0	200	00:00-05:59
33000	03:30:00	3	30	0	210	00:00-05:59
33900	03:39:00	3	39	0	219	00:00-05:59
34000	03:40:00	3	40	0	220	00:00-05:59
35000	03:50:00	3	50	0	230	00:00-05:59
35800	03:58:00	3	58	0	238	00:00-05:59
40000	04:00:00	4	0	0	240	00:00-05:59
40900	04:09:00	4	9	0	249	00:00-05:59
41000	04:10:00	4	10	0	250	00:00-05:59
42000	04:20:00	4	20	0	260	00:00-05:59
42800	04:28:00	4	28	0	268	00:00-05:59
43000	04:30:00	4	30	0	270	00:00-05:59
43900	04:39:00	4	39	0	279	00:00-05:59
44000	04:40:00	4	40	0	280	00:00-05:59
45000	04:50:00	4	50	0	290	00:00-05:59
50000	05:00:00	5	0	0	300	00:00-05:59
50900	05:09:00	5	9	0	309	00:00-05:59
51000	05:10:00	5	10	0	310	00:00-05:59
52000	05:20:00	5	20	0	320	00:00-05:59
53000	05:30:00	5	30	0	330	00:00-05:59
53900	05:39:00	5	39	0	339	00:00-05:59
54000	05:40:00	5	40	0	340	00:00-05:59
55000	05:50:00	5	50	0	350	00:00-05:59
60000	06:00:00	6	0	0	360	06:00-11:59
60900	06:09:00	6	9	0	369	06:00-11:59
61000	06:10:00	6	10	0	370	06:00-11:59
61419	06:14:19	6	14	19	374	06:00-11:59
62000	06:20:00	6	20	0	380	06:00-11:59
62410	06:24:10	6	24	10	384	06:00-11:59
63000	06:30:00	6	30	0	390	06:00-11:59
63900	06:39:00	6	39	0	399	06:00-11:59
64000	06:40:00	6	40	0	400	06:00-11:59
65000	06:50:00	6	50	0	410	06:00-11:59
70000	07:00:00	7	0	0	420	06:00-11:59
70900	07:09:00	7	9	0	429	06:00-11:59
71000	07:10:00	7	10	0	430	06:00-11:59
72000	07:20:00	7	20	0	440	06:00-11:59
73000	07:30:00	7	30	0	450	06:00-11:59
73900	07:39:00	7	39	0	459	06:00-11:59
74000	07:40:00	7	40	0	460	06:00-11:59
75000	07:50:00	7	50	0	470	06:00-11:59
80000	08:00:00	8	0	0	480	06:00-11:59
80900	08:09:00	8	9	0	489	06:00-11:59
81000	08:10:00	8	10	0	490	06:00-11:59
82000	08:20:00	8	20	0	500	06:00-11:59
83000	08:30:00	8	30	0	510	06:00-11:59
83900	08:39:00	8	39	0	519	06:00-11:59
84000	08:40:00	8	40	0	520	06:00-11:59
85000	08:50:00	8	50	0	530	06:00-11:59
90000	09:00:00	9	0	0	540	06:00-11:59
90900	09:09:00	9	9	0	549	06:00-11:59
91000	09:10:00	9	10	0	550	06:00-11:59
92000	09:20:00	9	20	0	560	06:00-11:59
93000	09:30:00	9	30	0	570	06:00-11:59
93900	09:39:00	9	39	0	579	06:00-11:59
94000	09:40:00	9	40	0	580	06:00-11:59
95000	09:50:00	9	50	0	590	06:00-11:59
100000	10:00:00	10	0	0	600	06:00-11:59
100900	10:09:00	10	9	0	609	06:00-11:59
101000	10:10:00	10	10	0	610	06:00-11:59
101648	10:16:48	10	16	48	616	06:00-11:59
102000	10:20:00	10	20	0	620	06:00-11:59
102653	10:26:53	10	26	53	626	06:00-11:59
103000	10:30:00	10	30	0	630	06:00-11:59
103155	10:31:55	10	31	55	631	06:00-11:59
103900	10:39:00	10	39	0	639	06:00-11:59
104000	10:40:00	10	40	0	640	06:00-11:59
104155	10:41:55	10	41	55	641	06:00-11:59
105000	10:50:00	10	50	0	650	06:00-11:59
110000	11:00:00	11	0	0	660	06:00-11:59
110900	11:09:00	11	9	0	669	06:00-11:59
111000	11:10:00	11	10	0	670	06:00-11:59
112000	11:20:00	11	20	0	680	06:00-11:59
113000	11:30:00	11	30	0	690	06:00-11:59
113900	11:39:00	11	39	0	699	06:00-11:59
114000	11:40:00	11	40	0	700	06:00-11:59
115000	11:50:00	11	50	0	710	06:00-11:59
120000	12:00:00	12	0	0	720	12:00-17:59
120900	12:09:00	12	9	0	729	12:00-17:59
121000	12:10:00	12	10	0	730	12:00-17:59
122000	12:20:00	12	20	0	740	12:00-17:59
123000	12:30:00	12	30	0	750	12:00-17:59
123900	12:39:00	12	39	0	759	12:00-17:59
124000	12:40:00	12	40	0	760	12:00-17:59
125000	12:50:00	12	50	0	770	12:00-17:59
130000	13:00:00	13	0	0	780	12:00-17:59
130900	13:09:00	13	9	0	789	12:00-17:59
131000	13:10:00	13	10	0	790	12:00-17:59
132000	13:20:00	13	20	0	800	12:00-17:59
133000	13:30:00	13	30	0	810	12:00-17:59
133900	13:39:00	13	39	0	819	12:00-17:59
134000	13:40:00	13	40	0	820	12:00-17:59
135000	13:50:00	13	50	0	830	12:00-17:59
140000	14:00:00	14	0	0	840	12:00-17:59
140900	14:09:00	14	9	0	849	12:00-17:59
141000	14:10:00	14	10	0	850	12:00-17:59
142000	14:20:00	14	20	0	860	12:00-17:59
143000	14:30:00	14	30	0	870	12:00-17:59
143900	14:39:00	14	39	0	879	12:00-17:59
144000	14:40:00	14	40	0	880	12:00-17:59
145000	14:50:00	14	50	0	890	12:00-17:59
150000	15:00:00	15	0	0	900	12:00-17:59
150900	15:09:00	15	9	0	909	12:00-17:59
151000	15:10:00	15	10	0	910	12:00-17:59
152000	15:20:00	15	20	0	920	12:00-17:59
153000	15:30:00	15	30	0	930	12:00-17:59
153900	15:39:00	15	39	0	939	12:00-17:59
154000	15:40:00	15	40	0	940	12:00-17:59
155000	15:50:00	15	50	0	950	12:00-17:59
160000	16:00:00	16	0	0	960	12:00-17:59
160900	16:09:00	16	9	0	969	12:00-17:59
161000	16:10:00	16	10	0	970	12:00-17:59
162000	16:20:00	16	20	0	980	12:00-17:59
163000	16:30:00	16	30	0	990	12:00-17:59
163900	16:39:00	16	39	0	999	12:00-17:59
164000	16:40:00	16	40	0	1000	12:00-17:59
165000	16:50:00	16	50	0	1010	12:00-17:59
170000	17:00:00	17	0	0	1020	12:00-17:59
170900	17:09:00	17	9	0	1029	12:00-17:59
171000	17:10:00	17	10	0	1030	12:00-17:59
172000	17:20:00	17	20	0	1040	12:00-17:59
173000	17:30:00	17	30	0	1050	12:00-17:59
173900	17:39:00	17	39	0	1059	12:00-17:59
174000	17:40:00	17	40	0	1060	12:00-17:59
175000	17:50:00	17	50	0	1070	12:00-17:59
180000	18:00:00	18	0	0	1080	18:00-23:59
180900	18:09:00	18	9	0	1089	18:00-23:59
181000	18:10:00	18	10	0	1090	18:00-23:59
182000	18:20:00	18	20	0	1100	18:00-23:59
183000	18:30:00	18	30	0	1110	18:00-23:59
183900	18:39:00	18	39	0	1119	18:00-23:59
184000	18:40:00	18	40	0	1120	18:00-23:59
185000	18:50:00	18	50	0	1130	18:00-23:59
190000	19:00:00	19	0	0	1140	18:00-23:59
190900	19:09:00	19	9	0	1149	18:00-23:59
191000	19:10:00	19	10	0	1150	18:00-23:59
192000	19:20:00	19	20	0	1160	18:00-23:59
193000	19:30:00	19	30	0	1170	18:00-23:59
193900	19:39:00	19	39	0	1179	18:00-23:59
194000	19:40:00	19	40	0	1180	18:00-23:59
195000	19:50:00	19	50	0	1190	18:00-23:59
200000	20:00:00	20	0	0	1200	18:00-23:59
200900	20:09:00	20	9	0	1209	18:00-23:59
201000	20:10:00	20	10	0	1210	18:00-23:59
202000	20:20:00	20	20	0	1220	18:00-23:59
203000	20:30:00	20	30	0	1230	18:00-23:59
203900	20:39:00	20	39	0	1239	18:00-23:59
204000	20:40:00	20	40	0	1240	18:00-23:59
205000	20:50:00	20	50	0	1250	18:00-23:59
210000	21:00:00	21	0	0	1260	18:00-23:59
210900	21:09:00	21	9	0	1269	18:00-23:59
211000	21:10:00	21	10	0	1270	18:00-23:59
212000	21:20:00	21	20	0	1280	18:00-23:59
213000	21:30:00	21	30	0	1290	18:00-23:59
213900	21:39:00	21	39	0	1299	18:00-23:59
214000	21:40:00	21	40	0	1300	18:00-23:59
215000	21:50:00	21	50	0	1310	18:00-23:59
220000	22:00:00	22	0	0	1320	18:00-23:59
220900	22:09:00	22	9	0	1329	18:00-23:59
221000	22:10:00	22	10	0	1330	18:00-23:59
222000	22:20:00	22	20	0	1340	18:00-23:59
223000	22:30:00	22	30	0	1350	18:00-23:59
223900	22:39:00	22	39	0	1359	18:00-23:59
224000	22:40:00	22	40	0	1360	18:00-23:59
225000	22:50:00	22	50	0	1370	18:00-23:59
230000	23:00:00	23	0	0	1380	18:00-23:59
230900	23:09:00	23	9	0	1389	18:00-23:59
231000	23:10:00	23	10	0	1390	18:00-23:59
232000	23:20:00	23	20	0	1400	18:00-23:59
233000	23:30:00	23	30	0	1410	18:00-23:59
233900	23:39:00	23	39	0	1419	18:00-23:59
234000	23:40:00	23	40	0	1420	18:00-23:59
235000	23:50:00	23	50	0	1430	18:00-23:59
\.


--
-- Data for Name: etl_batch; Type: TABLE DATA; Schema: ndbc_dw; Owner: -
--

COPY ndbc_dw.etl_batch (etl_batch_id, started_at, finished_at, status, source_station_count, source_scrape_run_count, source_observation_count, inserted_station_count, inserted_scrape_run_count, inserted_observation_count, total_station_count, total_scrape_run_count, total_observation_count) FROM stdin;
1	2026-07-23 22:11:47.61908+07	2026-07-23 22:11:47.61908+07	SUCCESS	90	3	573475	90	3	573475	90	3	573475
2	2026-07-23 22:12:58.785978+07	2026-07-23 22:12:58.785978+07	SUCCESS	90	3	573475	0	0	0	90	3	573475
3	2026-07-23 22:12:58.785978+07	2026-07-23 22:12:58.785978+07	SUCCESS	90	3	573475	0	0	0	90	3	573475
\.


--
-- Data for Name: fact_scrape_run; Type: TABLE DATA; Schema: ndbc_dw; Owner: -
--

COPY ndbc_dw.fact_scrape_run (scrape_run_fact_key, scrape_run_key, started_date_key, started_time_key, finished_date_key, finished_time_key, duration_second, target_station_count, source_candidate_count, processed_candidate_count, successful_station_count, skipped_non_buoy_count, skipped_no_data_count, failed_attempt_count, source_observation_count, duplicate_observation_count, dw_loaded_at) FROM stdin;
1	1	20260723	101648	20260723	102653	604.147	90	375	254	90	18	146	0	573334	0	2026-07-23 22:11:47.61908+07
2	2	20260723	61419	20260723	62410	590.906	90	375	254	90	18	146	0	571167	0	2026-07-23 22:11:47.61908+07
3	3	20260723	103155	20260723	104155	599.717	90	375	254	90	18	146	0	573463	0	2026-07-23 22:11:47.61908+07
\.


--
-- Name: dim_scrape_run_scrape_run_key_seq; Type: SEQUENCE SET; Schema: ndbc_dw; Owner: -
--

SELECT pg_catalog.setval('ndbc_dw.dim_scrape_run_scrape_run_key_seq', 9, true);


--
-- Name: dim_station_station_key_seq; Type: SEQUENCE SET; Schema: ndbc_dw; Owner: -
--

SELECT pg_catalog.setval('ndbc_dw.dim_station_station_key_seq', 270, true);


--
-- Name: etl_batch_etl_batch_id_seq; Type: SEQUENCE SET; Schema: ndbc_dw; Owner: -
--

SELECT pg_catalog.setval('ndbc_dw.etl_batch_etl_batch_id_seq', 3, true);


--
-- Name: fact_scrape_run_scrape_run_fact_key_seq; Type: SEQUENCE SET; Schema: ndbc_dw; Owner: -
--

SELECT pg_catalog.setval('ndbc_dw.fact_scrape_run_scrape_run_fact_key_seq', 9, true);


--
-- PostgreSQL database dump complete
--

\unrestrict qTS7jXzgNRnYwcQYyA1WUEHIdkyuuXIaIyzzD89zwc6p2IbWSHblIIEp4DcWOid

