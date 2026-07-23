-- Generated PostgreSQL export chunk
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;



--
-- Data for Name: scrape_run; Type: TABLE DATA; Schema: ndbc; Owner: -
--

COPY ndbc.scrape_run (scrape_run_id, started_at, finished_at, target_station_count, target_met, source_candidate_count, processed_candidate_count, successful_station_count, skipped_non_buoy_count, skipped_no_data_count, failed_attempt_count, total_observation_count, duplicate_observation_count, station_list_source_url, source_output_directory, loaded_at) FROM stdin;
ndbc-20260723-061419-0c3bbdce81	2026-07-23 13:14:19.412435+07	2026-07-23 13:24:10.318476+07	90	t	375	254	90	18	146	0	571167	0	https://www.ndbc.noaa.gov/to_station.shtml	D:\\ZIZAKAYA\\Asisten Basis Data\\Seleksi-2026-Tugas-1\\Data Scraping\\data	2026-07-23 15:41:00.918213+07
\.


--
-- Data for Name: station; Type: TABLE DATA; Schema: ndbc; Owner: -
--

COPY ndbc.station (station_id, provider_id, station_name, location, device_type, payload, latitude, longitude, water_depth_meter, status, detail_url, realtime_data_url, created_at, updated_at) FROM stdin;
51000	1	NORTHERN HAWAII ONE	245NM NE of Honolulu HI	3-meter foam buoy	SCOOP payload	23.534	-153.752	4848	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=51000	https://www.ndbc.noaa.gov/data/realtime2/51000.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46089	1	TILLAMOOK, OR	85 NM WNW of Tillamook, OR	3-meter discus buoy w/ seal cage	SCOOP payload	45.928	-125.815	2360	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46089	https://www.ndbc.noaa.gov/data/realtime2/46089.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46088	1	NEW DUNGENESS	17 NM NE of Port Angeles, WA	3-meter discus buoy w/ seal cage	SCOOP payload	48.332	-123.179	115.5	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46088	https://www.ndbc.noaa.gov/data/realtime2/46088.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46087	1	Neah Bay	6 NM North of Cape Flattery, WA (Traffic Separation Lighted Buoy)	3-meter discus buoy w/ seal cage	SCOOP payload	48.493	-124.727	259	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46087	https://www.ndbc.noaa.gov/data/realtime2/46087.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46086	1	SAN CLEMENTE BASIN	27NM SE Of San Clemente Is, CA	2.1-meter ionomer foam buoy	SCOOP payload	32.504	-118.029	1862	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46086	https://www.ndbc.noaa.gov/data/realtime2/46086.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46085	1	CENTRAL GULF OF ALASKA	265NM West of Cape Ommaney, AK	3-meter foam buoy	SCOOP payload	55.84	-142.895	3749	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46085	https://www.ndbc.noaa.gov/data/realtime2/46085.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46084	1	CAPE EDGECUMBE	25NM SSW of Cape Edgecumbe, AK	3-meter discus buoy w/ seal cage	SCOOP payload	56.614	-136.04	1149	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46084	https://www.ndbc.noaa.gov/data/realtime2/46084.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46083	1	FAIRWEATHER GROUND	105 NM West of Juneau, AK	3-meter discus buoy	SCOOP payload	58.276	-138.024	131	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46083	https://www.ndbc.noaa.gov/data/realtime2/46083.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46082	1	Cape Suckling	35 NM SE of Kayak Is, AK	3-meter discus buoy w/ seal cage	SCOOP payload	59.67	-143.353	296	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46082	https://www.ndbc.noaa.gov/data/realtime2/46082.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46081	1	Western Prince William Sound	\N	3-meter discus buoy w/ seal cage	SCOOP payload	60.802	-148.283	327	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46081	https://www.ndbc.noaa.gov/data/realtime2/46081.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46080	1	PORTLOCK BANK	76 NM ENE of Kodiak, AK	3-meter discus buoy w/ seal cage	SCOOP payload	57.91	-150.129	220	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46080	https://www.ndbc.noaa.gov/data/realtime2/46080.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46078	1	ALBATROSS BANK	104NM South of Kodiak Is., AK	3-meter discus buoy w/ seal cage	SCOOP payload	55.561	-152.599	5361	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46078	https://www.ndbc.noaa.gov/data/realtime2/46078.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46077	1	SHELIKOF STRAIT, AK	\N	3-meter discus buoy w/ seal cage	SCOOP payload	57.869	-154.211	200	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46077	https://www.ndbc.noaa.gov/data/realtime2/46077.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46076	1	CAPE CLEARE	17 NM South of Montague Is, AK	3-meter discus buoy w/ seal cage	SCOOP payload	59.508	-148.005	200	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46076	https://www.ndbc.noaa.gov/data/realtime2/46076.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46075	1	SHUMAGIN ISLANDS	85NM South of Sand Point, AK	3-meter discus buoy w/ seal cage	SCOOP payload	53.938	-160.735	2520	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46075	https://www.ndbc.noaa.gov/data/realtime2/46075.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46073	1	SOUTHEAST BERING SEA	205 NM WNW of Dutch Harbor, AK	3-meter discus buoy	SCOOP payload	54.985	-171.874	3445	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46073	https://www.ndbc.noaa.gov/data/realtime2/46073.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46072	1	CENTRAL ALEUTIANS 230 NM SW Dutch Harbor	\N	3-meter discus buoy	SCOOP payload	51.645	-172.145	3589	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46072	https://www.ndbc.noaa.gov/data/realtime2/46072.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46071	1	WESTERN ALEUTIANS	14NM SOUTH OF AMCHITKA IS, AK	3-meter discus buoy w/ seal cage	SCOOP payload	51.035	179.808	4058	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46071	https://www.ndbc.noaa.gov/data/realtime2/46071.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46070	1	SOUTHWEST BERING SEA	142NM NNE OF ATTU IS, AK	3-meter foam buoy	SCOOP payload	55.048	175.246	3848	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46070	https://www.ndbc.noaa.gov/data/realtime2/46070.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46069	1	SOUTH SANTA ROSA	14 NM SW of Santa Rosa Island, CA	3-meter foam buoy w/ seal cage	SCOOP payload	33.657	-120.227	985	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46069	https://www.ndbc.noaa.gov/data/realtime2/46069.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46066	1	SOUTH KODIAK	310NM SSW of Kodiak, AK	3-meter discus buoy	SCOOP payload	52.776	-154.992	4459	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46066	https://www.ndbc.noaa.gov/data/realtime2/46066.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46061	1	Seal Rocks	Between Montague and Hinchinbrook Islands, AK	3-meter discus buoy w/ seal cage	SCOOP payload	60.23	-146.837	215	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46061	https://www.ndbc.noaa.gov/data/realtime2/46061.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46060	1	WEST ORCA BAY	8NM NW of Hinchinbrook Is., AK	3-meter foam buoy w/ seal cage	SCOOP payload	60.571	-146.795	430	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46060	https://www.ndbc.noaa.gov/data/realtime2/46060.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46059	1	WEST CALIFORNIA	357NM West of San Francisco, CA	3-meter discus buoy	SCOOP payload	38.067	-129.895	4620	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46059	https://www.ndbc.noaa.gov/data/realtime2/46059.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46054	1	WEST SANTA BARBARA 38 NM West of Santa Barbara, CA	\N	3-meter discus buoy w/ seal cage	SCOOP payload	34.274	-120.468	454	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46054	https://www.ndbc.noaa.gov/data/realtime2/46054.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46053	1	EAST SANTA BARBARA	12NM Southwest of Santa Barbara, CA	3-meter foam buoy w/ seal cage	SCOOP payload	34.246	-119.842	417	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46053	https://www.ndbc.noaa.gov/data/realtime2/46053.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46050	1	STONEWALL BANK	20NM West of Newport, OR	3-meter foam buoy	SCOOP payload	44.679	-124.535	149	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46050	https://www.ndbc.noaa.gov/data/realtime2/46050.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46047	1	TANNER BANK	121 NM West of San Diego, CA	3-meter foam buoy	SCOOP payload	32.418	-119.535	1390	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46047	https://www.ndbc.noaa.gov/data/realtime2/46047.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46042	1	MONTEREY	27NM WNW of Monterey, CA	3-meter foam buoy w/ seal cage	SCOOP payload	36.787	-122.408	1710	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46042	https://www.ndbc.noaa.gov/data/realtime2/46042.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46041	1	CAPE ELIZABETH	45NM NW of Aberdeen, WA	3-meter discus buoy w/ seal cage	SCOOP payload	47.352	-124.739	131	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46041	https://www.ndbc.noaa.gov/data/realtime2/46041.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46035	1	CENTRAL BERING SEA	310 NM North of Adak, AK	3-meter foam buoy	SCOOP payload	57.034	-177.468	3696	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46035	https://www.ndbc.noaa.gov/data/realtime2/46035.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46029	1	COLUMBIA RIVER BAR	20NM West of Columbia River Mouth	2.1-meter ionomer foam buoy w/ seal cage	SCOOP payload	46.148	-124.508	135	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46029	https://www.ndbc.noaa.gov/data/realtime2/46029.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46028	1	CAPE SAN MARTIN	55NM West NW of Morro Bay, CA	3-meter foam buoy w/ seal cage	SCOOP payload	35.763	-121.9	1136	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46028	https://www.ndbc.noaa.gov/data/realtime2/46028.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46027	1	ST GEORGES	8 NM NW of Crescent City, CA	3-meter discus buoy w/ seal cage	SCOOP payload	41.84	-124.382	60	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46027	https://www.ndbc.noaa.gov/data/realtime2/46027.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46026	1	SAN FRANCISCO	18NM West of San Francisco, CA	3-meter foam buoy	SCOOP payload	37.75	-122.838	53	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46026	https://www.ndbc.noaa.gov/data/realtime2/46026.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46025	1	Santa Monica Basin	33NM WSW of Santa Monica, CA	3-meter discus buoy w/ seal cage	SCOOP payload	33.765	-119.077	868	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46025	https://www.ndbc.noaa.gov/data/realtime2/46025.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46022	1	EEL RIVER	17NM WSW of Eureka, CA	3-meter foam buoy w/ seal cage	SCOOP payload	40.716	-124.54	456	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46022	https://www.ndbc.noaa.gov/data/realtime2/46022.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46015	1	PORT ORFORD	15 NM West of Port Orford, OR	3-meter discus buoy w/ seal cage	SCOOP payload	42.754	-124.839	446	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46015	https://www.ndbc.noaa.gov/data/realtime2/46015.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46014	1	PT ARENA	19NM North of Point Arena, CA	3-meter discus buoy w/ seal cage	SCOOP payload	39.225	-123.98	335	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46014	https://www.ndbc.noaa.gov/data/realtime2/46014.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46013	1	BODEGA BAY	48NM NW of San Francisco, CA	3-meter discus buoy w/ seal cage	SCOOP payload	38.235	-123.317	128.3	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46013	https://www.ndbc.noaa.gov/data/realtime2/46013.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46011	1	SANTA MARIA	21NM NW of Point Arguello, CA	3-meter discus buoy w/ seal cage	SCOOP payload	34.937	-120.999	416	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46011	https://www.ndbc.noaa.gov/data/realtime2/46011.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46006	1	SOUTHEAST PAPA	600NM West of Eureka, CA	3-meter foam buoy	SCOOP payload	40.73	-137.42	4335	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46006	https://www.ndbc.noaa.gov/data/realtime2/46006.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46005	1	WEST WASHINGTON	300NM West of Aberdeen, WA	3-meter foam buoy	SCOOP payload	46.147	-131.077	2811	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46005	https://www.ndbc.noaa.gov/data/realtime2/46005.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46002	1	WEST OREGON	275NM West of Coos Bay, OR	3-meter foam buoy w/ seal cage	SCOOP payload	42.56	-130.523	3438	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46002	https://www.ndbc.noaa.gov/data/realtime2/46002.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
46001	1	WESTERN GULF OF ALASKA	175NM SE of Kodiak, AK	3-meter foam buoy w/ seal cage	SCOOP payload	56.296	-148.027	4123	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=46001	https://www.ndbc.noaa.gov/data/realtime2/46001.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
45012	1	EAST Lake Ontario	20NM North Northeast of Rochester, NY	2.3-meter foam discus buoy	SCOOP payload	43.621	-77.401	143.3	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=45012	https://www.ndbc.noaa.gov/data/realtime2/45012.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
45006	1	WEST SUPERIOR	30NM NE of Outer Island, WI	2.3-meter foam discus buoy	SCOOP payload	47.335	-89.793	194.5	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=45006	https://www.ndbc.noaa.gov/data/realtime2/45006.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
45005	1	WEST ERIE	16 NM NW of Lorain, OH	2.3-meter foam discus buoy	SCOOP payload	41.677	-82.398	9.8	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=45005	https://www.ndbc.noaa.gov/data/realtime2/45005.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
45004	1	EAST SUPERIOR -70 NM NE Marquette, MI	\N	2.3-meter foam discus buoy	SCOOP payload	47.583	-86.586	237.2	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=45004	https://www.ndbc.noaa.gov/data/realtime2/45004.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
45002	1	NORTH MICHIGAN- Halfway between North Manitou and Washington Islands.	\N	2.1-meter ionomer foam buoy	SCOOP payload	45.344	-86.411	181.4	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=45002	https://www.ndbc.noaa.gov/data/realtime2/45002.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
45001	1	MID SUPERIOR- 60 NM North Northeast Hancock, MI	\N	2.1-meter ionomer foam buoy	SCOOP payload	48.061	-87.793	247	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=45001	https://www.ndbc.noaa.gov/data/realtime2/45001.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
44065	1	New York Harbor Entrance	15 NM SE of Breezy Point , NY	3-meter foam buoy	SCOOP payload	40.368	-73.701	26	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=44065	https://www.ndbc.noaa.gov/data/realtime2/44065.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
44027	1	Jonesport, ME	20 NM SE of Jonesport, ME	3-meter foam buoy	SCOOP payload	44.284	-67.301	188	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=44027	https://www.ndbc.noaa.gov/data/realtime2/44027.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
44025	1	LONG ISLAND	30 NM South of Islip, NY	3-meter foam buoy	SCOOP payload	40.258	-73.175	40.2	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=44025	https://www.ndbc.noaa.gov/data/realtime2/44025.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
44020	1	NANTUCKET SOUND	\N	3-meter foam buoy	SCOOP payload	41.497	-70.283	16.5	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=44020	https://www.ndbc.noaa.gov/data/realtime2/44020.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
44014	1	VIRGINIA BEACH 64 NM East of Virginia Beach, VA	\N	2.1-meter ionomer foam buoy	SCOOP payload	36.603	-74.837	49.1	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=44014	https://www.ndbc.noaa.gov/data/realtime2/44014.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
44013	1	BOSTON 16 NM East of Boston, MA	\N	2.1-meter ionomer foam buoy	SCOOP payload	42.346	-70.651	64.6	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=44013	https://www.ndbc.noaa.gov/data/realtime2/44013.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
44011	1	GEORGES BANK 170 NM East of Hyannis, MA	\N	3-meter foam buoy	SCOOP payload	41.088	-66.546	90.2	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=44011	https://www.ndbc.noaa.gov/data/realtime2/44011.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
44009	1	DELAWARE BAY 26 NM Southeast of Cape May, NJ	\N	3-meter discus buoy	SCOOP payload	38.46	-74.692	24	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=44009	https://www.ndbc.noaa.gov/data/realtime2/44009.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
44008	1	NANTUCKET 54 NM Southeast of Nantucket	\N	3-meter discus buoy	SCOOP payload	40.5	-69.254	73	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=44008	https://www.ndbc.noaa.gov/data/realtime2/44008.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
44007	1	PORTLAND	12 NM Southeast of Portland,ME	3-meter discus buoy	SCOOP payload	43.525	-70.14	49	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=44007	https://www.ndbc.noaa.gov/data/realtime2/44007.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
42060	1	Caribbean Valley	63 NM WSW of Montserrat	3-meter foam buoy	SCOOP payload	16.428	-63.21	1556	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=42060	https://www.ndbc.noaa.gov/data/realtime2/42060.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
42059	1	Eastern Caribbean Sea	180 NM SSW of Ponce, PR	3-meter foam buoy	SCOOP payload	15.255	-67.621	4779	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=42059	https://www.ndbc.noaa.gov/data/realtime2/42059.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
42058	1	Central Caribbean	210 NM SSE of Kingston, Jamaica	3-meter foam buoy	SCOOP payload	14.114	-75.949	3953	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=42058	https://www.ndbc.noaa.gov/data/realtime2/42058.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
42057	1	Western Caribbean	195 NM WSW of Negril, Jamaica	3-meter discus buoy	SCOOP payload	16.975	-81.578	412	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=42057	https://www.ndbc.noaa.gov/data/realtime2/42057.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
42056	1	Yucatan Basin	120 NM ESE of Cozumel, MX	3-meter foam buoy	SCOOP payload	19.82	-84.98	4578	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=42056	https://www.ndbc.noaa.gov/data/realtime2/42056.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
42055	1	BAY OF CAMPECHE	214 NM NE of Veracruz, MX	3-meter foam buoy	SCOOP payload	22.14	-94.112	3608	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=42055	https://www.ndbc.noaa.gov/data/realtime2/42055.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
42040	1	LUKE OFFSHORE TEST PLATFORM	63 NM South of Dauphin Island, AL	3-meter foam buoy	SCOOP payload	29.207	-88.237	192	NO_RECENT_DATA	https://www.ndbc.noaa.gov/station_page.php?station=42040	https://www.ndbc.noaa.gov/data/realtime2/42040.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
42039	1	PENSACOLA	115NM SSE of Pensacola, FL	2.1-meter ionomer foam buoy	SCOOP payload	28.768	-86.024	297	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=42039	https://www.ndbc.noaa.gov/data/realtime2/42039.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
42036	1	WEST TAMPA	112 NM WNW of Tampa, FL	3-meter discus buoy	SCOOP payload	28.5	-84.505	53.3	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=42036	https://www.ndbc.noaa.gov/data/realtime2/42036.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
42035	1	GALVESTON,TX	22 NM East of Galveston, TX	3-meter foam buoy	SCOOP payload	29.235	-94.41	15.5	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=42035	https://www.ndbc.noaa.gov/data/realtime2/42035.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
42012	1	ORANGE BEACH	44 NM SE of Mobile, AL	3-meter discus buoy	Athena payload	30.061	-87.547	27	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=42012	https://www.ndbc.noaa.gov/data/realtime2/42012.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
42002	1	WEST GULF	207 NM East of Brownsville, TX	3-meter foam buoy	SCOOP payload	25.95	-93.78	3208	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=42002	https://www.ndbc.noaa.gov/data/realtime2/42002.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
42001	1	MID GULF	180 nm South of Southwest Pass, LA	3-meter foam buoy	SCOOP payload	25.922	-89.638	3195	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=42001	https://www.ndbc.noaa.gov/data/realtime2/42001.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41049	1	SOUTH BERMUDA	300 NM SSE of Bermuda	3-meter foam buoy	SCOOP payload	27.505	-62.271	5480	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41049	https://www.ndbc.noaa.gov/data/realtime2/41049.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41048	1	WEST BERMUDA	240 NM West of Bermuda	3-meter foam buoy	SCOOP payload	31.89	-69.708	5410	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41048	https://www.ndbc.noaa.gov/data/realtime2/41048.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41047	1	NE BAHAMAS	350 NM ENE of Nassau, Bahamas	3-meter foam buoy	SCOOP payload	27.557	-71.48	5328	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41047	https://www.ndbc.noaa.gov/data/realtime2/41047.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41046	1	EAST BAHAMAS	335 NM East of San Salvador Is, Bahamas	3-meter foam buoy	SCOOP payload	23.84	-68.34	5553	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41046	https://www.ndbc.noaa.gov/data/realtime2/41046.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41044	1	NE ST MARTIN	330 NM NE St Martin Is	3-meter discus buoy	SCOOP payload	21.582	-58.63	5419	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41044	https://www.ndbc.noaa.gov/data/realtime2/41044.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41043	1	NE PUERTO RICO	170 NM NNE of San Juan, PR	3-meter foam buoy	SCOOP payload	21.09	-64.864	5286	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41043	https://www.ndbc.noaa.gov/data/realtime2/41043.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41041	1	NORTH EQUATORIAL TWO	890 NM East of Martinique	2.1-meter ionomer foam buoy	SCOOP payload	14.259	-46.052	3506	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41041	https://www.ndbc.noaa.gov/data/realtime2/41041.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41040	1	NORTH EQUATORIAL ONE- 470 NM East of Martinique	\N	3-meter foam buoy	SCOOP payload	14.568	-53.037	5069	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41040	https://www.ndbc.noaa.gov/data/realtime2/41040.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41025	1	Diamond Shoals, NC	\N	3-meter foam buoy	SCOOP payload	35.026	-75.38	61	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41025	https://www.ndbc.noaa.gov/data/realtime2/41025.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41013	1	Frying Pan Shoals, NC	\N	3-meter discus buoy	SCOOP payload	33.436	-77.764	30.8	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41013	https://www.ndbc.noaa.gov/data/realtime2/41013.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41010	1	CANAVERAL EAST	120NM East of Cape Canaveral	2.1-meter ionomer foam buoy	SCOOP payload	28.86	-78.478	903.1	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41010	https://www.ndbc.noaa.gov/data/realtime2/41010.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41009	1	CANAVERAL 20 NM East of Cape Canaveral, FL	\N	3-meter discus buoy	SCOOP payload	28.508	-80.185	42	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41009	https://www.ndbc.noaa.gov/data/realtime2/41009.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41008	1	GRAYS REEF	40 NM Southeast of Savannah, GA	3-meter discus buoy	SCOOP payload	31.4	-80.866	16	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41008	https://www.ndbc.noaa.gov/data/realtime2/41008.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41004	1	EDISTO	41 NM Southeast of Charleston, SC	3-meter foam buoy	SCOOP payload	32.502	-79.099	35	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41004	https://www.ndbc.noaa.gov/data/realtime2/41004.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41002	1	SOUTH HATTERAS	225 NM South of Cape Hatteras	3-meter foam buoy	SCOOP payload	31.743	-74.955	3666	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41002	https://www.ndbc.noaa.gov/data/realtime2/41002.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
41001	1	EAST HATTERAS	150 NM East of Cape Hatteras	3-meter foam buoy	SCOOP payload	34.791	-72.42	4450	ACTIVE	https://www.ndbc.noaa.gov/station_page.php?station=41001	https://www.ndbc.noaa.gov/data/realtime2/41001.txt	2026-07-23 15:41:00.918213+07	2026-07-23 15:41:00.918213+07
\.


--
-- Data for Name: station_extraction; Type: TABLE DATA; Schema: ndbc; Owner: -
--

COPY ndbc.station_extraction (scrape_run_id, station_id, extracted_at) FROM stdin;
ndbc-20260723-061419-0c3bbdce81	41001	2026-07-23 13:14:57.297474+07
ndbc-20260723-061419-0c3bbdce81	41002	2026-07-23 13:14:59.248819+07
ndbc-20260723-061419-0c3bbdce81	41004	2026-07-23 13:15:04.364909+07
ndbc-20260723-061419-0c3bbdce81	41008	2026-07-23 13:15:13.485937+07
ndbc-20260723-061419-0c3bbdce81	41009	2026-07-23 13:15:16.588516+07
ndbc-20260723-061419-0c3bbdce81	41010	2026-07-23 13:15:18.561794+07
ndbc-20260723-061419-0c3bbdce81	41013	2026-07-23 13:15:26.580542+07
ndbc-20260723-061419-0c3bbdce81	41025	2026-07-23 13:15:44.457952+07
ndbc-20260723-061419-0c3bbdce81	41040	2026-07-23 13:15:53.431165+07
ndbc-20260723-061419-0c3bbdce81	41041	2026-07-23 13:15:55.805405+07
ndbc-20260723-061419-0c3bbdce81	41043	2026-07-23 13:15:57.663128+07
ndbc-20260723-061419-0c3bbdce81	41044	2026-07-23 13:16:00.552627+07
ndbc-20260723-061419-0c3bbdce81	41046	2026-07-23 13:16:02.263925+07
ndbc-20260723-061419-0c3bbdce81	41047	2026-07-23 13:16:05.06536+07
ndbc-20260723-061419-0c3bbdce81	41048	2026-07-23 13:16:08.23431+07
ndbc-20260723-061419-0c3bbdce81	41049	2026-07-23 13:16:10.674438+07
ndbc-20260723-061419-0c3bbdce81	42001	2026-07-23 13:16:30.925787+07
ndbc-20260723-061419-0c3bbdce81	42002	2026-07-23 13:16:32.867093+07
ndbc-20260723-061419-0c3bbdce81	42012	2026-07-23 13:16:57.542541+07
ndbc-20260723-061419-0c3bbdce81	42035	2026-07-23 13:17:18.586009+07
ndbc-20260723-061419-0c3bbdce81	42036	2026-07-23 13:17:20.393729+07
ndbc-20260723-061419-0c3bbdce81	42039	2026-07-23 13:17:27.626007+07
ndbc-20260723-061419-0c3bbdce81	42040	2026-07-23 13:17:29.421389+07
ndbc-20260723-061419-0c3bbdce81	42055	2026-07-23 13:17:41.867891+07
ndbc-20260723-061419-0c3bbdce81	42056	2026-07-23 13:17:44.880946+07
ndbc-20260723-061419-0c3bbdce81	42057	2026-07-23 13:17:47.619974+07
ndbc-20260723-061419-0c3bbdce81	42058	2026-07-23 13:17:49.490513+07
ndbc-20260723-061419-0c3bbdce81	42059	2026-07-23 13:17:51.507874+07
ndbc-20260723-061419-0c3bbdce81	42060	2026-07-23 13:17:53.388394+07
ndbc-20260723-061419-0c3bbdce81	44007	2026-07-23 13:18:33.441003+07
ndbc-20260723-061419-0c3bbdce81	44008	2026-07-23 13:18:36.243612+07
ndbc-20260723-061419-0c3bbdce81	44009	2026-07-23 13:18:38.769193+07
ndbc-20260723-061419-0c3bbdce81	44011	2026-07-23 13:18:42.711134+07
ndbc-20260723-061419-0c3bbdce81	44013	2026-07-23 13:18:47.270966+07
ndbc-20260723-061419-0c3bbdce81	44014	2026-07-23 13:18:49.942055+07
ndbc-20260723-061419-0c3bbdce81	44020	2026-07-23 13:19:00.561265+07
ndbc-20260723-061419-0c3bbdce81	44025	2026-07-23 13:19:05.333781+07
ndbc-20260723-061419-0c3bbdce81	44027	2026-07-23 13:19:09.428994+07
ndbc-20260723-061419-0c3bbdce81	44065	2026-07-23 13:19:14.259129+07
ndbc-20260723-061419-0c3bbdce81	45001	2026-07-23 13:19:33.174558+07
ndbc-20260723-061419-0c3bbdce81	45002	2026-07-23 13:19:34.970072+07
ndbc-20260723-061419-0c3bbdce81	45004	2026-07-23 13:19:38.689853+07
ndbc-20260723-061419-0c3bbdce81	45005	2026-07-23 13:19:40.979534+07
ndbc-20260723-061419-0c3bbdce81	45006	2026-07-23 13:19:43.720028+07
ndbc-20260723-061419-0c3bbdce81	45012	2026-07-23 13:19:57.655791+07
ndbc-20260723-061419-0c3bbdce81	46001	2026-07-23 13:19:59.581665+07
ndbc-20260723-061419-0c3bbdce81	46002	2026-07-23 13:20:01.784026+07
ndbc-20260723-061419-0c3bbdce81	46005	2026-07-23 13:20:05.748224+07
ndbc-20260723-061419-0c3bbdce81	46006	2026-07-23 13:20:08.569016+07
ndbc-20260723-061419-0c3bbdce81	46011	2026-07-23 13:20:20.89016+07
ndbc-20260723-061419-0c3bbdce81	46013	2026-07-23 13:20:24.174277+07
ndbc-20260723-061419-0c3bbdce81	46014	2026-07-23 13:20:25.979986+07
ndbc-20260723-061419-0c3bbdce81	46015	2026-07-23 13:20:29.647004+07
ndbc-20260723-061419-0c3bbdce81	46022	2026-07-23 13:20:39.329198+07
ndbc-20260723-061419-0c3bbdce81	46025	2026-07-23 13:20:45.521946+07
ndbc-20260723-061419-0c3bbdce81	46026	2026-07-23 13:20:48.038672+07
ndbc-20260723-061419-0c3bbdce81	46027	2026-07-23 13:20:50.480846+07
ndbc-20260723-061419-0c3bbdce81	46028	2026-07-23 13:20:51.981075+07
ndbc-20260723-061419-0c3bbdce81	46029	2026-07-23 13:20:54.593959+07
ndbc-20260723-061419-0c3bbdce81	46035	2026-07-23 13:21:06.18904+07
ndbc-20260723-061419-0c3bbdce81	46041	2026-07-23 13:21:14.86139+07
ndbc-20260723-061419-0c3bbdce81	46042	2026-07-23 13:21:17.507262+07
ndbc-20260723-061419-0c3bbdce81	46047	2026-07-23 13:21:23.777937+07
ndbc-20260723-061419-0c3bbdce81	46050	2026-07-23 13:21:27.729043+07
ndbc-20260723-061419-0c3bbdce81	46053	2026-07-23 13:21:31.512332+07
ndbc-20260723-061419-0c3bbdce81	46054	2026-07-23 13:21:34.641337+07
ndbc-20260723-061419-0c3bbdce81	46059	2026-07-23 13:21:36.725025+07
ndbc-20260723-061419-0c3bbdce81	46060	2026-07-23 13:21:38.825752+07
ndbc-20260723-061419-0c3bbdce81	46061	2026-07-23 13:21:41.313772+07
ndbc-20260723-061419-0c3bbdce81	46066	2026-07-23 13:21:47.625246+07
ndbc-20260723-061419-0c3bbdce81	46069	2026-07-23 13:21:50.445429+07
ndbc-20260723-061419-0c3bbdce81	46070	2026-07-23 13:21:52.260391+07
ndbc-20260723-061419-0c3bbdce81	46071	2026-07-23 13:21:55.198812+07
ndbc-20260723-061419-0c3bbdce81	46072	2026-07-23 13:21:57.239622+07
ndbc-20260723-061419-0c3bbdce81	46073	2026-07-23 13:21:59.748713+07
ndbc-20260723-061419-0c3bbdce81	46075	2026-07-23 13:22:02.980961+07
ndbc-20260723-061419-0c3bbdce81	46076	2026-07-23 13:22:05.010776+07
ndbc-20260723-061419-0c3bbdce81	46077	2026-07-23 13:22:07.279802+07
ndbc-20260723-061419-0c3bbdce81	46078	2026-07-23 13:22:09.71069+07
ndbc-20260723-061419-0c3bbdce81	46080	2026-07-23 13:22:13.713071+07
ndbc-20260723-061419-0c3bbdce81	46081	2026-07-23 13:22:16.980534+07
ndbc-20260723-061419-0c3bbdce81	46082	2026-07-23 13:22:18.70245+07
ndbc-20260723-061419-0c3bbdce81	46083	2026-07-23 13:22:20.980169+07
ndbc-20260723-061419-0c3bbdce81	46084	2026-07-23 13:22:22.92044+07
ndbc-20260723-061419-0c3bbdce81	46085	2026-07-23 13:22:25.133201+07
ndbc-20260723-061419-0c3bbdce81	46086	2026-07-23 13:22:27.548625+07
ndbc-20260723-061419-0c3bbdce81	46087	2026-07-23 13:22:29.67963+07
ndbc-20260723-061419-0c3bbdce81	46088	2026-07-23 13:22:32.210829+07
ndbc-20260723-061419-0c3bbdce81	46089	2026-07-23 13:22:33.974418+07
ndbc-20260723-061419-0c3bbdce81	51000	2026-07-23 13:23:53.811507+07
\.


--
-- Name: data_provider_provider_id_seq; Type: SEQUENCE SET; Schema: ndbc; Owner: -
--

SELECT pg_catalog.setval('ndbc.data_provider_provider_id_seq', 33, true);


--
-- Name: data_provider pk_data_provider; Type: CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.data_provider
    ADD CONSTRAINT pk_data_provider PRIMARY KEY (provider_id);


--
-- Name: observation pk_observation; Type: CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.observation
    ADD CONSTRAINT pk_observation PRIMARY KEY (station_id, observed_at_utc);


--
-- Name: scrape_run pk_scrape_run; Type: CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.scrape_run
    ADD CONSTRAINT pk_scrape_run PRIMARY KEY (scrape_run_id);


--
-- Name: station pk_station; Type: CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.station
    ADD CONSTRAINT pk_station PRIMARY KEY (station_id);


--
-- Name: station_extraction pk_station_extraction; Type: CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.station_extraction
    ADD CONSTRAINT pk_station_extraction PRIMARY KEY (scrape_run_id, station_id);


--
-- Name: data_provider uq_data_provider_base_url; Type: CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.data_provider
    ADD CONSTRAINT uq_data_provider_base_url UNIQUE (base_url);


--
-- Name: data_provider uq_data_provider_name; Type: CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.data_provider
    ADD CONSTRAINT uq_data_provider_name UNIQUE (provider_name);


--
-- Name: station uq_station_detail_url; Type: CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.station
    ADD CONSTRAINT uq_station_detail_url UNIQUE (detail_url);


--
-- Name: station uq_station_realtime_data_url; Type: CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.station
    ADD CONSTRAINT uq_station_realtime_data_url UNIQUE (realtime_data_url);


--
-- Name: station_extraction trg_station_extraction_validate_time; Type: TRIGGER; Schema: ndbc; Owner: -
--

CREATE TRIGGER trg_station_extraction_validate_time BEFORE INSERT OR UPDATE ON ndbc.station_extraction FOR EACH ROW EXECUTE FUNCTION ndbc.validate_station_extraction_time();


--
-- Name: station trg_station_set_updated_at; Type: TRIGGER; Schema: ndbc; Owner: -
--

CREATE TRIGGER trg_station_set_updated_at BEFORE UPDATE ON ndbc.station FOR EACH ROW EXECUTE FUNCTION ndbc.set_updated_at();


--
-- Name: observation fk_observation_first_seen_run; Type: FK CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.observation
    ADD CONSTRAINT fk_observation_first_seen_run FOREIGN KEY (first_seen_run_id) REFERENCES ndbc.scrape_run(scrape_run_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: observation fk_observation_first_seen_extraction; Type: FK CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.observation
    ADD CONSTRAINT fk_observation_first_seen_extraction FOREIGN KEY (first_seen_run_id, station_id) REFERENCES ndbc.station_extraction(scrape_run_id, station_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: observation fk_observation_station; Type: FK CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.observation
    ADD CONSTRAINT fk_observation_station FOREIGN KEY (station_id) REFERENCES ndbc.station(station_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: station_extraction fk_station_extraction_run; Type: FK CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.station_extraction
    ADD CONSTRAINT fk_station_extraction_run FOREIGN KEY (scrape_run_id) REFERENCES ndbc.scrape_run(scrape_run_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: station_extraction fk_station_extraction_station; Type: FK CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.station_extraction
    ADD CONSTRAINT fk_station_extraction_station FOREIGN KEY (station_id) REFERENCES ndbc.station(station_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: station fk_station_provider; Type: FK CONSTRAINT; Schema: ndbc; Owner: -
--

ALTER TABLE ONLY ndbc.station
    ADD CONSTRAINT fk_station_provider FOREIGN KEY (provider_id) REFERENCES ndbc.data_provider(provider_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

\unrestrict L8ft73GpqjCi7qbo33KEI87exUtxhA0gHVX2CFTibGZoyESydRdISPW2fWYTyon

