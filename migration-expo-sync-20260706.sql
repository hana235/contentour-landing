-- ══════════════════════════════════════════════════════════════
-- 60_해외전시회DB 노션 동기화 (2026-07-06)
-- 원본: 노션 "해외 전시회_DB" 미래 전시회(2026-07-01 이후) 534건
-- 정리: 내부 중복 병합 → 467건 / 기존 일치 날짜갱신 56건 + 신규 388건
-- 적용: Supabase Dashboard > SQL Editor에 전체 붙여넣기 → Run
-- ══════════════════════════════════════════════════════════════

BEGIN;

-- ── 기존 전시회 최신 회차로 날짜 갱신 (56건) ──
-- Drupa 2028 (기존 2028-05-09 → 2028-05-23)
UPDATE "60_해외전시회DB" SET start_date='2028-05-23', end_date='2028-06-02', city='뒤셀도르프', is_active=true, updated_at=now() WHERE id=30;
-- Arab Health 2027 (기존 2026-01-26 → 2027-01-25)
UPDATE "60_해외전시회DB" SET start_date='2027-01-25', end_date='2027-01-28', city='두바이', is_active=true, updated_at=now() WHERE id=65;
-- IPACK-IMA 2028 (기존 2028-05-27 → 2028-05-29)
UPDATE "60_해외전시회DB" SET start_date='2028-05-29', end_date='2028-06-01', city='밀라노', is_active=true, updated_at=now() WHERE id=77;
-- Beautyworld Middle East 2026 (기존 2026-10-27 → 2026-10-06)
UPDATE "60_해외전시회DB" SET start_date='2026-10-06', end_date='2026-10-08', city='두바이', is_active=true, updated_at=now() WHERE id=68;
-- OSEA 2026 (기존 2026-11-17 → 2026-11-24)
UPDATE "60_해외전시회DB" SET start_date='2026-11-24', end_date='2026-11-26', city='싱가포르', is_active=true, updated_at=now() WHERE id=94;
-- Anuga 2026 (기존 2027-10-09 → 2026-10-10)
UPDATE "60_해외전시회DB" SET start_date='2026-10-10', end_date='2026-10-14', city='쾰른', is_active=true, updated_at=now() WHERE id=25;
-- BioJapan (기존 2026-10-14 → 2026-10-07)
UPDATE "60_해외전시회DB" SET start_date='2026-10-07', end_date='2026-10-09', city='요코하마', is_active=true, updated_at=now() WHERE id=257;
-- ITS World Congress 2026 (기존 2028-10-08 → 2026-10-19)
UPDATE "60_해외전시회DB" SET start_date='2026-10-19', end_date='2026-10-23', city='강릉', is_active=true, updated_at=now() WHERE id=284;
-- DSEI 2027 (기존 2027-09-14 → 2027-09-07)
UPDATE "60_해외전시회DB" SET start_date='2027-09-07', end_date='2027-09-10', city='런던', is_active=true, updated_at=now() WHERE id=112;
-- MIPCOM 2026 (기존 2026-10-10 → 2026-10-12)
UPDATE "60_해외전시회DB" SET start_date='2026-10-12', end_date='2026-10-15', city='칸', is_active=true, updated_at=now() WHERE id=292;
-- Cosmoprof North America Las Vegas 2026 (기존 2026-07-21 → 2026-07-13)
UPDATE "60_해외전시회DB" SET start_date='2026-07-13', end_date='2026-07-15', city='라스베이거스', is_active=true, updated_at=now() WHERE id=60;
-- Aquatech Amsterdam 2026 (기존 2027-11-02 → 2026-11-03)
UPDATE "60_해외전시회DB" SET start_date='2026-11-03', end_date='2026-11-06', city='암스테르담', is_active=true, updated_at=now() WHERE id=217;
-- SIAL Paris 2026 (기존 2026-10-17 → 2026-10-18)
UPDATE "60_해외전시회DB" SET start_date='2026-10-18', end_date='2026-10-22', city='파리', is_active=true, updated_at=now() WHERE id=84;
-- Middle East Energy 2026 (기존 2026-03-03 → 2026-09-01)
UPDATE "60_해외전시회DB" SET start_date='2026-09-01', end_date='2026-09-03', city='두바이', is_active=true, updated_at=now() WHERE id=204;
-- NAB Show 2027 (기존 2026-04-18 → 2027-04-03)
UPDATE "60_해외전시회DB" SET start_date='2027-04-03', end_date='2027-04-07', city='라스베이거스', is_active=true, updated_at=now() WHERE id=51;
-- IFA Berlin 2026 (기존 2026-09-04 → 2026-09-04)
UPDATE "60_해외전시회DB" SET start_date='2026-09-04', end_date='2026-09-08', city='베를린', is_active=true, updated_at=now() WHERE id=26;
-- CEATEC 2026 (기존 2026-10-20 → 2026-10-13)
UPDATE "60_해외전시회DB" SET start_date='2026-10-13', end_date='2026-10-16', city='치바', is_active=true, updated_at=now() WHERE id=4;
-- PackExpo International 2026 (기존 2026-10-25 → 2026-11-08)
UPDATE "60_해외전시회DB" SET start_date='2026-11-08', end_date='2026-11-11', city='시카고', is_active=true, updated_at=now() WHERE id=55;
-- CPhI Worldwide Milan 2026 (기존 2026-10-13 → 2026-10-06)
UPDATE "60_해외전시회DB" SET start_date='2026-10-06', end_date='2026-10-08', city='밀라노', is_active=true, updated_at=now() WHERE id=91;
-- METALEX Vietnam 2026 (기존 2026-10-08 → 2026-10-01)
UPDATE "60_해외전시회DB" SET start_date='2026-10-01', end_date='2026-10-03', city='호치민', is_active=true, updated_at=now() WHERE id=197;
-- Medical Fair India 2026 (Mumbai) (기존 2026-03-19 → 2026-09-17)
UPDATE "60_해외전시회DB" SET start_date='2026-09-17', end_date='2026-09-19', city='뭄바이', is_active=true, updated_at=now() WHERE id=262;
-- Bio International Convention 2027 (기존 2026-06-08 → 2027-06-07)
UPDATE "60_해외전시회DB" SET start_date='2027-06-07', end_date='2027-06-10', city='필라델피아', is_active=true, updated_at=now() WHERE id=252;
-- interzum 2027 (기존 2027-05-20 → 2027-05-11)
UPDATE "60_해외전시회DB" SET start_date='2027-05-11', end_date='2027-05-14', city='쾰른', is_active=true, updated_at=now() WHERE id=39;
-- Cosmoprof Worldwide Bologna 2027 (기존 2026-03-19 → 2027-03-18)
UPDATE "60_해외전시회DB" SET start_date='2027-03-18', end_date='2027-03-21', city='볼로냐', is_active=true, updated_at=now() WHERE id=76;
-- Canton Fair Autumn 2026 (제140회 중국수출입상품교역회) (기존 2026-04-15 → 2026-10-15)
UPDATE "60_해외전시회DB" SET start_date='2026-10-15', end_date='2026-11-04', city='광저우', is_active=true, updated_at=now() WHERE id=14;
-- JIMTOF 2026 (기존 2026-11-02 → 2026-10-26)
UPDATE "60_해외전시회DB" SET start_date='2026-10-26', end_date='2026-10-31', city='도쿄', is_active=true, updated_at=now() WHERE id=5;
-- GITEX 2026 (기존 2026-10-12 → 2026-10-01)
UPDATE "60_해외전시회DB" SET start_date='2026-10-01', end_date='2026-10-03', city='하노이', is_active=true, updated_at=now() WHERE id=64;
-- Medical Fair Asia (기존 2026-09-02 → 2026-09-09)
UPDATE "60_해외전시회DB" SET start_date='2026-09-09', end_date='2026-09-11', city='싱가포르', is_active=true, updated_at=now() WHERE id=155;
-- Natural Products Expo West 2027 (기존 2026-03-03 → 2027-03-02)
UPDATE "60_해외전시회DB" SET start_date='2027-03-02', end_date='2027-03-05', city='애너하임', is_active=true, updated_at=now() WHERE id=53;
-- IFT FIRST 2026 (기존 2026-07-19 → 2026-07-12)
UPDATE "60_해외전시회DB" SET start_date='2026-07-12', end_date='2026-07-15', city='시카고', is_active=true, updated_at=now() WHERE id=54;
-- ITB Berlin 2027 (기존 2026-03-04 → 2027-03-16)
UPDATE "60_해외전시회DB" SET start_date='2027-03-16', end_date='2027-03-18', city='베를린', is_active=true, updated_at=now() WHERE id=304;
-- CPhI India 2026 (기존 2026-11-24 → 2026-11-23)
UPDATE "60_해외전시회DB" SET start_date='2026-11-23', end_date='2026-11-25', city='델리', is_active=true, updated_at=now() WHERE id=305;
-- FABTECH 2026 (기존 2026-10-18 → 2026-10-21)
UPDATE "60_해외전시회DB" SET start_date='2026-10-21', end_date='2026-10-23', city='라스베이거스', is_active=true, updated_at=now() WHERE id=63;
-- Fine Food Australia 2026 (기존 2026-09-07 → 2026-08-31)
UPDATE "60_해외전시회DB" SET start_date='2026-08-31', end_date='2026-09-03', city='멜버른', is_active=true, updated_at=now() WHERE id=107;
-- SEMICON Japan 2026 (기존 2026-12-16 → 2026-12-09)
UPDATE "60_해외전시회DB" SET start_date='2026-12-09', end_date='2026-12-11', city='도쿄', is_active=true, updated_at=now() WHERE id=8;
-- Renewable Energy India Expo 2026 (기존 2026-10-07 → 2026-10-22)
UPDATE "60_해외전시회DB" SET start_date='2026-10-22', end_date='2026-10-24', city='그레이터노이다', is_active=true, updated_at=now() WHERE id=238;
-- HANNOVER MESSE 2027 (기존 2026-04-20 → 2027-04-05)
UPDATE "60_해외전시회DB" SET start_date='2027-04-05', end_date='2027-04-09', city='하노버', is_active=true, updated_at=now() WHERE id=24;
-- Fruit Logistica 2027 (기존 2026-02-04 → 2027-02-03)
UPDATE "60_해외전시회DB" SET start_date='2027-02-03', end_date='2027-02-05', city='베를린', is_active=true, updated_at=now() WHERE id=181;
-- Cosmoprof Asia Hong Kong 2026 (기존 2026-11-10 → 2026-11-11)
UPDATE "60_해외전시회DB" SET start_date='2026-11-11', end_date='2026-11-13', city='홍콩', is_active=true, updated_at=now() WHERE id=296;
-- EUROSHOP 2029 (기존 2026-02-22 → 2029-02-18)
UPDATE "60_해외전시회DB" SET start_date='2029-02-18', end_date='2029-02-22', city='뒤셀도르프', is_active=true, updated_at=now() WHERE id=33;
-- World of Concrete 2027 (기존 2026-01-20 → 2027-01-19)
UPDATE "60_해외전시회DB" SET start_date='2027-01-19', end_date='2027-01-21', city='라스베이거스', is_active=true, updated_at=now() WHERE id=299;
-- Gulfood 2027 (기존 2026-02-17 → 2027-03-15)
UPDATE "60_해외전시회DB" SET start_date='2027-03-15', end_date='2027-03-19', city='두바이', is_active=true, updated_at=now() WHERE id=66;
-- CES 2027 (기존 2026-01-06 → 2027-01-05)
UPDATE "60_해외전시회DB" SET start_date='2027-01-05', end_date='2027-01-09', city='라스베이거스', is_active=true, updated_at=now() WHERE id=50;
-- IntermatConstruction 2027 (기존 2027-04-19 → 2027-04-21)
UPDATE "60_해외전시회DB" SET start_date='2027-04-21', end_date='2027-04-24', city='파리', is_active=true, updated_at=now() WHERE id=211;
-- All-Energy Australia 2026 (기존 2026-10-21 → 2026-10-28)
UPDATE "60_해외전시회DB" SET start_date='2026-10-28', end_date='2026-10-29', city='멜버른', is_active=true, updated_at=now() WHERE id=108;
-- ADIPEC (기존 2026-11-09 → 2026-11-02)
UPDATE "60_해외전시회DB" SET start_date='2026-11-02', end_date='2026-11-05', city='아부다비', is_active=true, updated_at=now() WHERE id=67;
-- Drinktec 2028 (기존 2029-09-15 → 2028-09-11)
UPDATE "60_해외전시회DB" SET start_date='2028-09-11', end_date='2028-09-15', city='뮌헨', is_active=true, updated_at=now() WHERE id=34;
-- KBIS 2027 (기존 2026-02-17 → 2027-02-02)
UPDATE "60_해외전시회DB" SET start_date='2027-02-02', end_date='2027-02-04', city='라스베이거스', is_active=true, updated_at=now() WHERE id=52;
-- Expo Med 2026 (기존 2026-06-03 → 2026-08-18)
UPDATE "60_해외전시회DB" SET start_date='2026-08-18', end_date='2026-08-20', city='멕시코시티', is_active=true, updated_at=now() WHERE id=126;
-- IDEX 2027 (기존 2026-04-02 → 2027-01-25)
UPDATE "60_해외전시회DB" SET start_date='2027-01-25', end_date='2027-01-29', city='아부다비', is_active=true, updated_at=now() WHERE id=222;
-- EuroTier 2026 (기존 2026-11-17 → 2026-11-10)
UPDATE "60_해외전시회DB" SET start_date='2026-11-10', end_date='2026-11-13', city='하노버', is_active=true, updated_at=now() WHERE id=40;
-- SHOT Show 2027 (기존 2026-01-20 → 2027-01-19)
UPDATE "60_해외전시회DB" SET start_date='2027-01-19', end_date='2027-01-22', city='라스베이거스', is_active=true, updated_at=now() WHERE id=187;
-- Automechanika Dubai 2026 (기존 2026-06-08 → 2026-11-10)
UPDATE "60_해외전시회DB" SET start_date='2026-11-10', end_date='2026-11-12', city='두바이', is_active=true, updated_at=now() WHERE id=203;
-- Maison&Objet Paris September 2026 (기존 2026-01-22 → 2026-09-10)
UPDATE "60_해외전시회DB" SET start_date='2026-09-10', end_date='2026-09-14', city='파리', is_active=true, updated_at=now() WHERE id=85;
-- Texcare International 2029 (기존 2028-11-08 → 2029-02-18)
UPDATE "60_해외전시회DB" SET start_date='2029-02-18', end_date='2029-02-22', city='프랑크푸르트', is_active=true, updated_at=now() WHERE id=278;
-- Fitur 2027 (기존 2026-01-21 → 2027-01-20)
UPDATE "60_해외전시회DB" SET start_date='2027-01-20', end_date='2027-01-24', city='마드리드', is_active=true, updated_at=now() WHERE id=303;

-- ── 신규 전시회 추가 (388건) ──
INSERT INTO "60_해외전시회DB" (name, country, city, venue, field, start_date, end_date, is_active) VALUES
('ISH Frankfurt 2027', '독일', '프랑크푸르트', '', '에너지·건설', '2027-03-15', '2027-03-19', true),
('Tokyo Game Show 2026', '일본', '치바', '', 'IT', '2026-09-17', '2026-09-21', true),
('SiGMA World 2026', '이탈리아', '로마', '', '기타', '2026-11-02', '2026-11-05', true),
('World CITYTech Expo 2026', '한국', '고양', '', '산업기술', '2026-09-01', '2026-09-30', true),
('TURKCHEM Eurasia 2026', '터키', '이스탄불', '', '산업기술', '2026-11-25', '2026-11-27', true),
('IDEF 2027', '터키', '이스탄불', '', '보안', '2027-05-03', '2027-05-09', true),
('Autumn Fair Home 2026', '영국', '버밍엄', '', '인테리어·라이프스타일', '2026-09-06', '2026-09-09', true),
('Expo 2030 Riyadh', '사우디아라비아', '리야드', '', '기타', '2030-10-01', '2031-03-31', true),
('FETC 2027 (Future of Education Technology Conference)', '미국', '올랜도', '', '교육', '2027-01-26', '2027-01-29', true),
('Tokyo International Gift Show Autumn 2026', '일본', '도쿄', '', '라이프스타일·인테리어', '2026-09-02', '2026-09-04', true),
('VIETSTOCK Expo & Forum 2026', '베트남', '호치민', '', '식음료·제조', '2026-10-21', '2026-10-23', true),
('ADF (Congrès de l''ADF) 2026', '프랑스', '파리', '', '의료', '2026-11-25', '2026-11-28', true),
('Productronica 2026', '독일', '뮌헨', '', 'IT·전자·제조', '2026-11-10', '2026-11-13', true),
('Furniture China', '중국', '상하이', '', '제조', '2026-09-08', '2026-09-11', true),
('SLUSH 2026', '핀란드', '헬싱키', '', 'IT', '2026-11-18', '2026-11-19', true),
('ADM Toronto 2027 (Advanced Design & Manufacturing Toronto)', '캐나다', '토론토', '', '제조·산업기술', '2027-11-09', '2027-11-11', true),
('IMDEX Asia 2027', '싱가포르', '싱가포르', '', '보안·안전', '2027-05-05', '2027-05-07', true),
('FoodWeek Korea 2026', '한국', '서울', '', '식음료', '2026-11-04', '2026-11-07', true),
('POLECO 2026', '폴란드', '포즈난', '', '에너지', '2026-10-06', '2026-10-08', true),
('EuroBLECH 2026', '독일', '하노버', '', '산업기술·제조', '2026-10-20', '2026-10-23', true),
('Udon Thani International Horticultural Expo 2026', '태국', '우돈타니', '', '문화·기타', '2026-11-01', '2027-03-14', true),
('Global Food Expo 2026', '폴란드', '바르샤바', '', '식음료', '2026-11-17', '2026-11-19', true),
('Cannes Yachting Festival 2026', '프랑스', '칸', '', '라이프스타일', '2026-09-08', '2026-09-13', true),
('White Label World Expo', '영국', '런던', '', '라이프스타일·기타', '2026-11-11', '2026-11-12', true),
('Routes World 2026', '사우디아라비아', '리야드', '', 'IT', '2026-10-27', '2026-10-29', true),
('WOMEX - World Music Expo 2026', '스페인', '그란카나리아', '', '문화', '2026-10-21', '2026-10-25', true),
('LOPEC 2027', '독일', '뮌헨', '', '전자·IT', '2027-03-03', '2027-03-04', true),
('Gulfood Manufacturing 2026', '아랍에미리트', '두바이', '', '식음료·제조', '2026-11-03', '2026-11-05', true),
('Hydrogen Technology World Expo 2026', '독일', '함부르크', '', '에너지·배터리', '2026-10-20', '2026-10-22', true),
('PLASTIMAGEN MEXICO 2026', '멕시코', '멕시코시티', '', '제조·산업기술', '2026-11-10', '2026-11-13', true),
('BEX Asia 2026', '싱가포르', '싱가포르', '', '건설·건축', '2026-09-02', '2026-09-04', true),
('Beauty Days 2026', '폴란드', '바르샤바', '', '뷰티', '2026-09-04', '2026-09-06', true),
('IAAPA Expo Europe 2026', '영국', '런던', '', '문화', '2026-09-21', '2026-09-25', true),
('Expo 2027 Yokohama (GREEN×EXPO 2027)', '일본', '요코하마', '', '문화·산업기술', '2027-03-19', '2027-09-26', true),
('IWA OutdoorClassics 2027', '독일', '뉘른베르크', '', '기타', '2027-03-04', '2027-03-07', true),
('CAFERES JAPAN 2026', '일본', '도쿄', '', '식음료·외식', '2026-08-04', '2026-08-06', true),
('Taipei International Plastics and Rubber Industry Show 2026', '대만', '타이페이', '', '제조·산업기술', '2026-09-15', '2026-09-19', true),
('Fi Asia Thailand 2027', '태국', '방콕', '', '식음료', '2027-09-01', '2027-09-03', true),
('BEAUTY FORUM Festival Munich 2026', '독일', '뮌헨', '', '뷰티', '2026-10-24', '2026-10-25', true),
('Gartner IT Symposium/Xpo 2026 Barcelona', '스페인', '바르셀로나', '', 'IT', '2026-11-09', '2026-11-12', true),
('Cosmoprof Bologna Asia 2026', '중국', '상하이', '', '뷰티', '2026-11-10', '2026-11-12', true),
('WODKAN Tech 2026', '폴란드', '바르샤바', '', '산업기술', '2026-09-08', '2026-09-10', true),
('ABISS (Industrial Digital Transformation Summit)', '벨기에', '코르트라이크', '', 'IT·산업기술', '2026-10-08', '2026-10-08', true),
('ITMA ASIA + CITME 2026', '중국', '상하이', '', '제조·산업기술', '2026-11-20', '2026-11-24', true),
('Comic-Con International 2026', '미국', '샌디에이고', '', '문화·예술', '2026-07-23', '2026-07-26', true),
('Dreamforce 2026', '미국', '샌프란시스코', '', 'IT', '2026-09-15', '2026-09-17', true),
('Japan Mobility Show 2026', '일본', '도쿄', '', '제조·산업기술', '2026-10-30', '2026-11-09', true),
('CIFF Shanghai 2026', '중국', '상하이', '', '인테리어', '2026-09-05', '2026-09-08', true),
('Flash Memory Conference & Expo 2026', '미국', '산타클라라', '', '반도체·IT', '2026-08-04', '2026-08-06', true),
('HostMilano', '이탈리아', '밀라노', '', '식음료', '2026-10-16', '2026-10-20', true),
('RE+ 2026', '미국', '라스베이거스', '', '에너지', '2026-11-16', '2026-11-19', true),
('ProWine Shanghai 2026', '중국', '상하이', '', '식음료', '2026-11-10', '2026-11-12', true),
('Jeddah International Beauty Expo 2026', '사우디아라비아', '제다', '', '뷰티', '2026-09-06', '2026-09-08', true),
('VIV Asia 2027', '태국', '방콕', '', '기타', '2027-03-10', '2027-03-12', true),
('Vehicle Tech Week North America 2026', '미국', '디트로이트', '', '제조·산업기술', '2026-10-27', '2026-10-29', true),
('PRI Trade Show 2026', '미국', NULL, '', '제조', '2026-12-10', '2026-12-12', true),
('Anime NYC 2026', '미국', '뉴욕', '', '문화·IT', '2026-08-20', '2026-08-23', true),
('The Battery Show India 2026', '인도', '그레이터노이다', '', '에너지·배터리', '2026-10-22', '2026-10-24', true),
('InnoTrans 2026', '독일', '베를린', '', '제조·산업기술', '2026-09-22', '2026-09-25', true),
('INHORGENTA MUNICH 2027', '독일', '뮌헨', '', '라이프스타일', '2027-02-19', '2027-02-22', true),
('TechCrunch Disrupt 2026', '미국', '샌프란시스코', '', 'IT', '2026-10-13', '2026-10-15', true),
('ISM Middle East 2026', '아랍에미리트', '두바이', '', '식음료', '2026-09-15', '2026-09-17', true),
('ITMA 2027', '독일', '하노버', '', '제조·산업기술', '2027-09-16', '2027-09-22', true),
('Food Analytics Conference 2026', '덴마크', '코펜하겐', '', '식음료', '2026-11-19', '2026-11-20', true),
('IBC2026', '네덜란드', '암스테르담', '', 'IT·문화', '2026-09-11', '2026-09-14', true),
('Horecava 2027', '네덜란드', '암스테르담', '', '식음료', '2027-01-11', '2027-01-14', true),
('FAKUMA 2026', '독일', '프리드리히스하펜', '', '제조', '2026-10-12', '2026-10-16', true),
('MEDTEC China 2026', '중국', '상하이', '', '의료·헬스케어', '2026-09-01', '2026-09-03', true),
('Salon International 2026', '영국', '런던', '', '뷰티·패션', '2026-10-04', '2026-10-05', true),
('IAAF Istanbul Art Fair 2026', '터키', '이스탄불', '', '문화·예술', '2026-12-03', '2026-12-06', true),
('VINITECH-SIFEL 2026', '프랑스', '보르도', '', '식음료', '2026-12-01', '2026-12-03', true),
('electronica China 2026', '중국', '상하이', '', 'IT·전자', '2026-07-01', '2026-07-03', true),
('Tokyo Dental Show 2026', '일본', '도쿄', '', '의료', '2026-11-07', '2026-11-08', true),
('Design Miami 2026', '미국', '마이애미', '', '예술·문화', '2026-12-01', '2026-12-06', true),
('Iraq Home & Hotel Expo 2026', '이라크', '바그다드', '', '건축·인테리어', '2026-10-07', '2026-10-10', true),
('WindEnergy Hamburg 2026', '독일', '함부르크', '', '에너지·전력·배터리', '2026-09-22', '2026-09-25', true),
('ISPO Munich 2026', '독일', '뮌헨', '', '라이프스타일·기타', '2026-11-03', '2026-11-05', true),
('SEMICON West 2026', '미국', '샌프란시스코', '', '반도체·제조', '2026-07-14', '2026-07-16', true),
('GITEX Technology Week 2026', '아랍에미리트', '두바이', '', 'IT', '2026-10-11', '2026-10-15', true),
('Enforce Tac 2026', '독일', '뉘른베르크', '', '안전·보안', '2027-03-01', '2027-03-03', true),
('AIMEX (Australasian Mining Exhibition) 2026', '호주', '시드니', '', '제조·산업기술', '2026-08-25', '2026-08-27', true),
('The Battery Show Indonesia 2026', '인도네시아', '자카르타', '', '에너지·배터리', '2026-09-02', '2026-09-05', true),
('The Battery Show North America 2026', '미국', '디트로이트', '', '에너지·배터리', '2026-10-12', '2026-10-15', true),
('WBE 2026 (World Battery Industry Expo)', '중국', '광저우', '', '에너지·배터리', '2026-09-16', '2026-09-18', true),
('TFWA World Exhibition & Conference 2026', '프랑스', '칸', '', '기타', '2026-10-04', '2026-10-08', true),
('Security Essen 2026', '독일', '에센', '', '안전·보안', '2026-09-22', '2026-09-25', true),
('Valve World Expo 2026', '독일', '뒤셀도르프', '', '제조·산업기술', '2026-12-01', '2026-12-03', true),
('SEMICON Europa 2026', '독일', '뮌헨', '', '반도체·제조', '2026-11-17', '2026-11-20', true),
('Dubai World Trade Centre Autumn Fair 2026', '아랍에미리트', '두바이', '', '기타', '2026-09-13', '2026-09-16', true),
('Greenbuild 2026', '미국', '로스앤젤레스', '', '건설·건축', '2026-10-20', '2026-10-22', true),
('ProWine Hong Kong 2027', '홍콩', '홍콩', '', '식음료', '2027-05-10', '2027-05-12', true),
('IMEX Asia 2026', '싱가포르', '싱가포르', '', NULL, '2026-10-21', '2026-10-23', true),
('UFI Global Congress 2026', '바레인', '사킈르', '', '기타', '2026-11-02', '2026-11-05', true),
('ADF 프랑스 치과 전시회 (Congrès de l''ADF)', '프랑스', '파리', '', '의료·헬스케어', '2026-11-24', '2026-11-28', true),
('GulfHost 2026', '아랍에미리트', '두바이', '', '식음료·외식', '2026-11-03', '2026-11-05', true),
('게임스컴 아시아 (Gamescom Asia) 2026', '태국', '방콕', '', '기타', '2026-10-29', '2026-11-01', true),
('FOODtech Week Tokyo 2026 (FOODtech JAPAN)', '일본', '도쿄', '', '식음료', '2026-11-18', '2026-11-20', true),
('Asia Food Expo (AFEX) 2026', '필리핀', '마닐라', '', '식음료', '2026-09-09', '2026-09-12', true),
('TCT2026', '미국', '샌디에이고', '', '의료', '2026-11-01', '2026-11-03', true),
('HKTDC Food Expo', '중국', '홍콩', '', '식음료·외식', '2026-08-13', '2026-08-17', true),
('Smart Work & Contact Center Expo', '한국', '서울', '', 'IT·산업기술', '2026-09-09', '2026-09-11', true),
('ENERGY TAIWAN', '대만', '타이페이', '', '에너지·전력', '2026-10-14', '2026-10-16', true),
('Moulding Expo 2027', '독일', '슈투트가르트', '', '산업기술·제조', '2027-05-01', '2027-05-04', true),
('NY NOW 미국 뉴욕 NOW 홈 리빙 박람회 2026 (하계)', '미국', '뉴욕', '', '라이프스타일·패션·뷰티', '2026-08-02', '2026-08-04', true),
('Future of Education Technology Conference (FETC) 2027', '미국', '올랜도', '', '교육', '2027-01-26', '2027-01-29', true),
('Big 5 Global 2026', '아랍에미리트', '두바이', '', '건설·건축', '2026-11-23', '2026-11-26', true),
('India Machine Tools Show 2027', '인도', '벵갈루루', '', '제조', '2027-05-14', '2027-05-17', true),
('DAC - Design Automation Conference 2026', '미국', '롱비치', '', 'IT·전자', '2026-07-26', '2026-07-29', true),
('ITB Asia 2026', '싱가포르', '싱가포르', '', '기타', '2026-10-21', '2026-10-23', true),
('Geneva Watch Days 2026', '스위스', '제네바', '', '패션·라이프스타일', '2026-09-02', '2026-09-06', true),
('홍콩코스모프로', '홍콩', '홍콩', '', '뷰티', '2026-11-10', '2026-11-13', true),
('Expo Camacol 2026', '콜롬비아', '메데인', '', '건설·건축·인테리어', '2026-08-26', '2026-08-29', true),
('health.tech global summit 2027', '스위스', '바젤', '', '의료', '2027-03-02', '2027-03-04', true),
('Expoalimentaria 2026', '페루', '리마', '', '식음료·외식', '2026-09-23', '2026-09-25', true),
('InPrint 2027', '독일', '뮌헨', '', 'IT·제조', '2027-03-09', '2027-03-11', true),
('Heimtextil 2027', '독일', '프랑크푸르트', '', '패션', '2027-01-12', '2027-01-15', true),
('Seatrade Cruise Med 2026', '스페인', '라스팔마스', '', '라이프스타일', '2026-09-16', '2026-09-17', true),
('Intermot Cologne 2026', '독일', '쾰른', '', '제조', '2026-12-03', '2026-12-06', true),
('DSEI Japan 2027', '일본', '치바', '', '안전', '2027-04-28', '2027-04-30', true),
('ICMIF Biennial Conference 2026', '캐나다', '토론토', '', '의료', '2026-11-03', '2026-11-06', true),
('Gartner IT Symposium/Xpo 2026 Orlando', '미국', '올랜도', '', 'IT', '2026-10-19', '2026-10-22', true),
('SIGMA Eurasia 2027', '아랍에미리트', '두바이', '', 'IT', '2027-03-01', '2027-03-31', true),
('IPF Japan 2026', '일본', '치바', '', '제조', '2026-12-01', '2026-12-05', true),
('PMRExpo 2026', '독일', '쾰른', '', '보안', '2026-11-24', '2026-11-26', true),
('Europort', '네덜란드', '암스테르담', '', '제조·산업기술', '2026-11-03', '2026-11-05', true),
('London Book Fair 2027', '영국', '런던', '', '출판', '2027-03-16', '2027-03-18', true),
('ELEKTROTEC 2026', '인도', '코임바토르', '', '전자·전력·에너지·산업기술', '2026-08-21', '2026-08-24', true),
('Pharmtech Ingredients 2026', '러시아', '모스크바', '', '의료·헬스케어', '2026-11-24', '2026-11-27', true),
('Amsterdam Dance Event 2026', '네덜란드', '암스테르담', '', '문화·예술', '2026-10-21', '2026-10-25', true),
('Intec 2027', '독일', NULL, '', '제조·산업기술', '2027-03-02', '2027-03-05', true),
('Intra-African Trade Fair (IATF) 2027', '나이지리아', '라고스', '', '기타', '2027-11-05', '2027-11-11', true),
('BruCON 2026 (Security Conference)', '벨기에', '메헬렌', '', 'IT·보안', '2026-09-24', '2026-09-25', true),
('CorruTec ASIA 2027', '태국', '방콕', '', '제조·산업기술', '2027-09-15', '2027-09-18', true),
('gamescom 2026', '독일', '쾰른', '', 'IT', '2026-08-26', '2026-08-30', true),
('JAPAN BUILD 2026 - International Building & Home Week (Osaka)', '일본', '오사카', '', '건축·건설', '2026-08-26', '2026-08-28', true),
('Saudi Industrial Expo 2026', '사우디아라비아', '리야드', '', '산업기술·제조', '2026-09-08', '2026-09-10', true),
('Decorex International 2026', '영국', '런던', '', '인테리어·라이프스타일', '2026-10-11', '2026-10-14', true),
('Lighting Design & Technology Expo 2026', '사우디아라비아', '리야드', '', '건축·인테리어', '2026-09-06', '2026-09-08', true),
('PDAC 2027', '캐나다', '토론토', '', '산업기술', '2027-03-07', '2027-03-10', true),
('IMEX America 2026', '미국', '라스베이거스', '', '교육', '2026-10-13', '2026-10-15', true),
('EXPO REAL 2026', '독일', '뮌헨', '', '건설·건축', '2026-10-05', '2026-10-07', true),
('Saudi Agriculture 2026', '사우디아라비아', '리야드', '', '제조', '2026-10-19', '2026-10-22', true),
('NEPCON Vietnam 2026', '베트남', '하노이', '', '전자·제조', '2026-08-05', '2026-08-07', true),
('FachPack 2026', '독일', '뉘른베르크', '', '제조·기타', '2026-09-29', '2026-10-01', true),
('Anuga FoodTec 2027', '독일', '쾰른', '', '식음료·제조', '2027-02-23', '2027-02-26', true),
('World Music Expo (WOMEX) 2026', '스페인', '그란카나리아', '', '문화', '2026-10-21', '2026-10-25', true),
('WOFEX - World Food Expo 2026', '필리핀', '마닐라', '', '식음료', '2026-07-29', '2026-08-01', true),
('TOKYO PACK 2026', '일본', '도쿄', '', '제조', '2026-10-14', '2026-10-16', true),
('ISPE Annual Meeting & Expo 2026', '미국', '워싱턴', '', '의료', '2026-10-18', '2026-10-21', true),
('11th World Congress on Food Science & Beverages 2026', '일본', '도쿄', '', '식음료', '2026-10-19', '2026-10-20', true),
('Motion + Power Technology Expo', '미국', '디트로이트', '', '제조·에너지', '2026-09-09', '2026-09-11', true),
('MTA Vietnam 2026', '베트남', '호치민', '', '제조·산업기술', '2026-07-01', '2026-07-04', true),
('Salon International de la Lingerie', '프랑스', '파리', '', '패션·뷰티', '2027-01-16', '2027-01-18', true),
('Coverings 2027', '미국', '올랜도', '', '건설·인테리어', '2027-04-06', '2027-04-09', true),
('2028 Ulsan International Garden Expo', '한국', '울산', '', '문화·기타', '2028-04-01', '2028-10-31', true),
('International Green Week (Grüne Woche) 2027', '독일', '베를린', '', '식음료·산업기술', '2027-01-15', '2027-01-24', true),
('Photonix (Laser & Photonics Expo)', '일본', '치바', '', '전자·산업기술', '2026-09-30', '2026-10-02', true),
('Automotive World Tokyo 2027', '일본', '도쿄', '', '제조', '2027-02-17', '2027-02-19', true),
('World of Quantum 2027', '독일', '뮌헨', '', 'IT', '2027-06-22', '2027-06-25', true),
('Japan Home Show & Building Show 2026', '일본', '도쿄', '', '건설·건축', '2026-11-18', '2026-11-20', true),
('Fastener Fair Global 2027', '독일', '슈투트가르트', '', '산업기술·제조', '2027-04-06', '2027-04-08', true),
('Expopharm 2026', '독일', '뮌헨', '', '의료·헬스케어', '2026-09-15', '2026-09-17', true),
('Battery India Expo 2026', '인도', '푸네', '', '에너지·배터리', '2026-10-02', '2026-10-04', true),
('Hydrogen Technology Expo North America 2027', '미국', '휴스턴', '', '에너지·배터리', '2027-02-10', '2027-02-11', true),
('Battery Cells & Systems Expo 2026', '영국', '버밍엄', '', '배터리·에너지', '2026-07-08', '2026-07-09', true),
('+INDUSTRY 2027', '독일', '하노버', '', '제조·산업기술', '2027-02-23', '2027-02-25', true),
('Breakbulk Middle East 2027', '아랍에미리트', '두바이', '', '제조', '2027-02-02', '2027-02-03', true),
('Auto Guangzhou 2026', '중국', '광저우', '', '제조·산업기술', '2026-11-27', '2026-12-06', true),
('GIFA 2027', '독일', '뒤셀도르프', '', '제조·산업기술', '2027-06-21', '2027-06-25', true),
('FesPack 2026', '모로코', '카사블랑카', '', '제조·식음료', '2026-10-13', '2026-10-16', true),
('IMM Cologne 2027', '독일', '쾰른', '', '라이프스타일·인테리어', '2027-01-19', '2027-01-22', true),
('GAIKINDO Indonesia International Auto Show 2026', '인도네시아', '자카르타', '', '기타', '2026-07-30', '2026-08-09', true),
('International Plastic Fair Japan (IPF Japan) 2026', '일본', '치바', '', '제조', '2026-12-01', '2026-12-05', true),
('MILIPOL Qatar 2026', '카타르', '도하', '', '보안', '2026-10-20', '2026-10-22', true),
('Loop Wellbeing Mallorca', '스페인', '팔마', '', '라이프스타일', '2026-10-22', '2026-10-25', true),
('MINExpo International 2026', '미국', '라스베이거스', '', '산업기술·제조', '2026-09-21', '2026-09-23', true),
('Expo Belgrade 2027', '세르비아', '베오그라드', '', '문화·예술·교육', '2027-05-15', '2027-08-15', true),
('WGC2028 (World Gas Conference 2028)', '영국', '런던', '', '에너지·전력', '2028-05-15', '2028-05-18', true),
('IPB 2026 (Shanghai)', '중국', '상하이', '', '제조', '2026-07-22', '2026-07-24', true),
('Paperworld Middle East 2026', '아랍에미리트', '두바이', '', '기타', '2026-10-13', '2026-10-15', true),
('SMM Hamburg 2026', '독일', '함부르크', '', '제조·산업기술', '2026-09-01', '2026-09-04', true),
('Singapore FinTech Festival 2026', '싱가포르', '싱가포르', '', 'IT·전자', '2026-11-18', '2026-11-20', true),
('Toronto International Film Festival 2026', '캐나다', '토론토', '', '문화·예술', '2026-09-10', '2026-09-20', true),
('ICE Europe 2027', '독일', '뮌헨', '', '제조·산업기술', '2027-03-09', '2027-03-11', true),
('BIOFACH 2027', '독일', '뉘른베르크', '', '식음료', '2027-02-16', '2027-02-19', true),
('Future Forces Exhibition 2028', '체코', '프라하', '', '산업기술', '2028-10-01', '2028-10-31', true),
('Hydrogen Technology Expo Europe 2026', '독일', '쾰른', '', '에너지', '2026-09-16', '2026-09-18', true),
('IDS 2027 (International Dental Show)', '독일', '쾰른', '', '의료·헬스케어', '2027-03-16', '2027-03-20', true),
('HKTDC Hong Kong Electronics Fair (Autumn Edition) 2026', '홍콩', '홍콩', '', 'IT·전자', '2026-10-13', '2026-10-16', true),
('MAGIC Las Vegas 2026', '미국', '라스베이거스', '', '패션·라이프스타일', '2026-08-10', '2026-08-12', true),
('Fi Europe 2026 (Food Ingredients Europe)', '독일', '프랑크푸르트', '', '식음료', '2026-11-17', '2026-11-19', true),
('WOFX (World Furniture Expo) 2026', '인도', '뭄바이', '', '라이프스타일·인테리어', '2026-12-08', '2026-12-10', true),
('La Feria De Diseño 2026', '콜롬비아', '메데인', '', '건축·인테리어', '2026-09-10', '2026-09-12', true),
('Fashion Tokyo 2026', '일본', '도쿄', '', '패션', '2026-10-07', '2026-10-09', true),
('Orgatec 2026', '독일', '쾰른', '', '인테리어', '2026-10-27', '2026-10-30', true),
('Frieze London 2026', '영국', '런던', '', '예술', '2026-10-14', '2026-10-18', true),
('European Manufacturing Conference 2026', '벨기에', '브뤼셀', '', '제조·산업기술', '2026-09-16', '2026-09-17', true),
('BeverTech', '이탈리아', '밀라노', '', '식음료', '2026-11-17', '2026-11-20', true),
('Food Ingredients Europe 2026', '독일', '프랑크푸르트', '', '식음료', '2026-11-17', '2026-11-19', true),
('MOVIMAT 2026', '브라질', '상파울루', '', '제조·산업기술', '2026-11-09', '2026-11-13', true),
('Seattle Art Fair 2026', '미국', '시애틀', '', '문화·예술', '2026-07-23', '2026-07-26', true),
('K-Beauty Expo Taiwan 2026', '대만', '타이페이', '', '뷰티', '2026-08-14', '2026-08-17', true),
('Gastech 2026', '태국', '방콕', '', '에너지', '2026-09-15', '2026-09-18', true),
('GlassBuild America 2026', '미국', '라스베이거스', '', '건설·건축', '2026-09-23', '2026-09-25', true),
('LIGHTEXPO Kenya 2026', '케냐', '나이로비', '', '전자', '2026-07-08', '2026-07-10', true),
('HIX Europe 2026', '영국', '런던', '', '인테리어·라이프스타일', '2026-11-25', '2026-11-26', true),
('Cosmoprof North America Miami 2027', '미국', '마이애미', '', '뷰티', '2027-01-26', '2027-01-28', true),
('Miami Art Basel 2026', '미국', '마이애미', '', '예술·문화', '2026-12-04', '2026-12-06', true),
('Automechanika Johannesburg 2026', '남아프리카공화국', '요하네스버그', '', '제조·산업기술', '2026-10-27', '2026-10-29', true),
('INTERBUILD Near East Exhibition 2026', '요르단', '암만', '', '건설·건축', '2026-09-07', '2026-09-10', true),
('DeveloperWeek 2027', '미국', '산타클라라', '', 'IT', '2027-02-09', '2027-02-11', true),
('China International Import Expo (CIIE) 2026', '중국', '상하이', '', 'IT·식음료·의료', '2026-11-05', '2026-11-10', true),
('INA PAACE Automechanika Mexico 2026', '멕시코', '멕시코시티', '', '기타', '2026-07-08', '2026-07-10', true),
('Fruit Attraction 2026', '스페인', '마드리드', '', '식음료', '2026-10-06', '2026-10-08', true),
('HOFEX 2027', '홍콩', '홍콩', '', '식음료·외식', '2027-05-10', '2027-05-12', true),
('ODA Annual Spring Meeting (ASM) 2027', '캐나다', '토론토', '', '의료', '2027-05-06', '2027-05-07', true),
('Asia Business Show 2026', '싱가포르', '싱가포르', '', 'IT', '2026-08-26', '2026-08-27', true),
('EMAX - Electronics Manufacturing Expo 2026', '말레이시아', '페낭', '', '전자·제조·반도체', '2026-07-22', '2026-07-24', true),
('A+A 2027', '독일', '뒤셀도르프', '', '안전·산업기술', '2027-10-19', '2027-10-22', true),
('SEMICON West San Jose', '미국', '샌프란시스코', '', '전자·반도체', '2026-10-13', '2026-10-15', true),
('K 2028 (Plastics and Rubber)', '독일', '뒤셀도르프', '', '제조·산업기술', '2028-10-18', '2028-10-25', true),
('Fashion Week Tokyo 2026', '일본', '도쿄', '', '패션', '2026-10-05', '2026-10-13', true),
('Restaurant Asia 2026', '싱가포르', '싱가포르', '', '식음료·외식', '2026-07-15', '2026-07-17', true),
('Dubai International Boat Show 2026', '아랍에미리트', '두바이', '', '제조·라이프스타일', '2026-11-25', '2026-11-29', true),
('EMO Hannover 2027', '독일', '하노버', '', '제조·산업기술', '2027-09-22', '2027-09-26', true),
('EQUITANA 2027', '독일', '에센', '', '라이프스타일', '2027-03-18', '2027-03-24', true),
('2026 Canadian National Exhibition (CNE)', '캐나다', '토론토', '', '라이프스타일·기타', '2026-08-21', '2026-09-07', true),
('Nigeria Oil & Gas 2026', '나이지리아', NULL, '', '에너지', '2026-07-05', '2026-07-09', true),
('ATEM FAIR/ACFEX KOREA 2026', '한국', '고양', '', '전자·산업기술', '2026-07-08', '2026-07-10', true),
('Tokyo Toy Show 2026', '일본', '도쿄', '', '라이프스타일', '2026-08-27', '2026-08-30', true),
('Textile Exchange Conference 2026', '캐나다', '밴쿠버', '', '패션', '2026-10-13', '2026-10-15', true),
('Korea Build Week 2026', '한국', '서울', '', '건설·건축·인테리어', '2026-08-05', '2026-08-08', true),
('All for Pack Emballage Paris 2026', '프랑스', '파리', '', '제조', '2026-11-24', '2026-11-26', true),
('Seafood Show Latin America 2026', '브라질', '상파울루', '', '식음료', '2026-10-20', '2026-10-22', true),
('AGRI WEEK', '일본', '치바', '', '식음료', '2026-10-07', '2026-10-09', true),
('World Vape Show Chile 2026', '칠레', '산티아고', '', '기타', '2026-09-04', '2026-09-05', true),
('Factory Innovation Week Tokyo 2027', '일본', '도쿄', '', '제조', '2027-02-17', '2027-02-19', true),
('Dubai World Trade Centre Mega Event 2026', '아랍에미리트', '두바이', '', '기타', '2026-10-01', '2026-10-31', true),
('International Hospital Federation World Congress 2026', '한국', '서울', '', '의료·헬스케어', '2026-10-19', '2026-10-22', true),
('MWC Doha 2026', '아랍에미리트', '도하', '', 'IT·전자', '2026-11-08', '2026-11-11', true),
('Web Summit Lisbon 2026', '포르투갈', '리스본', '', 'IT', '2026-11-09', '2026-11-12', true),
('Cologne International Games Expo (Gamescom) 2026', '독일', '쾰른', '', 'IT', '2026-08-26', '2026-08-30', true),
('Intersolar Mexico 2026', '멕시코', '멕시코시티', '', '에너지·전력', '2026-09-01', '2026-09-03', true),
('IAAPA Expo Middle East 2027', '아랍에미리트', '아부다비', '', '기타', '2027-04-12', '2027-04-15', true),
('GroceryShop 2026', '미국', '라스베이거스', '', 'IT·식음료', '2026-09-22', '2026-09-24', true),
('WETEX', '아랍에미리트', '두바이', '', NULL, '2026-10-20', '2026-10-22', true),
('Art Basel Miami Beach 2026', '미국', '마이애미', '', '예술·문화', '2026-12-04', '2026-12-06', true),
('MEBAA Show 2026', '아랍에미리트', '두바이', '', '제조', '2026-12-08', '2026-12-10', true),
('EIMA International 2026', '이탈리아', '볼로냐', '', '제조·산업기술', '2026-11-10', '2026-11-14', true),
('EuroCIS 2027', '독일', '뒤셀도르프', '', 'IT', '2027-02-16', '2027-02-18', true),
('TECHSPO New York 2027', '미국', '뉴욕', '', 'IT', '2027-04-22', '2027-04-23', true),
('World Travel Market 2026', '영국', '런던', '', '라이프스타일', '2026-11-03', '2026-11-05', true),
('Luxepack Monaco 2026', '모나코', '모나코', '', '제조·산업기술', '2026-09-28', '2026-09-30', true),
('Las Vegas Apparel 2026', '미국', '라스베이거스', '', '패션', '2026-08-09', '2026-08-12', true),
('Farnborough International Airshow 2026', '영국', '판버러', '', '산업기술', '2026-07-20', '2026-07-24', true),
('MICAM Milano Autumn 2026', '이탈리아', '밀라노', '', '패션', '2026-09-13', '2026-09-15', true),
('The Aerospace Event 2026 - Washington DC', '미국', '워싱턴', '', '산업기술·보안', '2026-10-12', '2026-10-13', true),
('Asia Fashion Thailand Show 2026', '태국', '방콕', '', '패션', '2026-07-09', '2026-07-11', true),
('Interfilière Paris', '프랑스', '파리', '', '패션', '2027-01-16', '2027-01-18', true),
('India Health 2026', '인도', '뉴델리', '', '의료·헬스케어', '2026-08-21', '2026-08-23', true),
('SICAM 2026', '이탈리아', '포르데노네', '', '건축·인테리어', '2026-10-20', '2026-10-23', true),
('Intersec 2027', '아랍에미리트', '두바이', '', '보안·안전', '2027-01-11', '2027-01-13', true),
('Warsaw Medical Expo 2026', '폴란드', '바르샤바', '', '의료·헬스케어', '2026-09-01', '2026-09-03', true),
('RETAIL EXPO Tokyo 2026', '일본', '도쿄', '', '기타', '2026-10-08', '2026-10-09', true),
('GDC 2027 (Game Developers Conference)', '미국', '샌프란시스코', '', 'IT·문화', '2027-03-01', '2027-03-05', true),
('bauma China 2026', '중국', '상하이', '', '건설·제조', '2026-11-24', '2026-11-27', true),
('VIATT (Vietnam International Apparel and Textile Trade Fair) 2027', '베트남', '호치민', '', '패션', '2027-02-24', '2027-02-26', true),
('PMW Expo 2026', '독일', '쾰른', '', '제조', '2026-11-11', '2026-11-12', true),
('Agritechnica 2027', '독일', '하노버', '', '제조', '2027-11-14', '2027-11-20', true),
('Japan Build', '일본', '도쿄', '', '건설·건축', '2026-12-02', '2026-12-04', true),
('World Aviation Festival 2026', '포르투갈', '리스본', '', 'IT', '2026-10-13', '2026-10-15', true),
('World Biomaterials Congress 2028', '미국', '워싱턴', '', '의료·산업기술', '2028-04-24', '2028-04-29', true),
('SiGMA Euro-Mediterranean 2027', '몰타', '타칼리', '', 'IT', '2027-05-03', '2027-05-05', true),
('Mondial de l''Auto Paris 2026', '프랑스', '파리', '', '제조', '2026-10-12', '2026-10-18', true),
('ICIS 2026 - International Conference on Information Systems', '포르투갈', '리스본', '', 'IT', '2026-12-13', '2026-12-16', true),
('DealerCon 2026', '남아프리카공화국', '요하네스버그', '', '제조', '2026-09-17', '2026-09-17', true),
('IGEEKS Annual Summit 2026', '싱가포르', '싱가포르', '', 'IT', '2026-09-15', '2026-09-17', true),
('Warsaw Home & Contract 2026', '폴란드', '바르샤바', '', '인테리어·건축', '2026-10-21', '2026-10-24', true),
('SupplySide Global Las Vegas 2026', '미국', '라스베이거스', '', '식음료', '2026-10-28', '2026-10-30', true),
('EATS (Equipment, Automation and Technology Show) 2027', '미국', '시카고', '', '식음료·제조', '2027-10-26', '2027-10-28', true),
('Vitafoods Asia 2026', '태국', '방콕', '', '의료·헬스케어·식음료', '2026-09-02', '2026-09-04', true),
('IFTM Top Resa 2026', '프랑스', '파리', '', '문화·라이프스타일', '2026-09-15', '2026-09-17', true),
('New York Comic Con 2026', '미국', '뉴욕', '', '문화·예술', '2026-10-08', '2026-10-11', true),
('Meteorological Technology World Expo 2026', '네덜란드', '암스테르담', '', '산업기술', '2026-10-06', '2026-10-08', true),
('AMB Stuttgart 2026', '독일', '슈투트가르트', '', '제조·산업기술', '2026-09-15', '2026-09-19', true),
('Manufacturing World Tokyo 2026', '일본', '도쿄', '', '제조·산업기술', '2026-07-01', '2026-07-03', true),
('IPLAS ECUADOR', '에콰도르', '과야킬', '', '제조·산업기술', '2026-09-01', '2026-09-01', true),
('Mobile World Congress (MWC) Barcelona 2027', '스페인', '바르셀로나', '', 'IT·전자', '2027-03-01', '2027-03-04', true),
('UN Climate Change Conference (COP31) 2026', '터키', NULL, '', '기타', '2026-11-09', '2026-11-20', true),
('IAAPA Expo 2026', '미국', '올랜도', '', '기타', '2026-11-16', '2026-11-20', true),
('Möbelmässan 2026', '스웨덴', '예테보리', '', '인테리어', '2026-09-08', '2026-09-10', true),
('Paris Motor Show 2026', '프랑스', '파리', '', '제조', '2026-10-12', '2026-10-18', true),
('iVT Off-Highway Vehicle Technology Expo 2026', '미국', '시카고', '', '제조·산업기술', '2026-08-19', '2026-08-20', true),
('SiGMA South Asia 2026', '태국', '방콕', '', '기타', '2026-11-30', '2026-12-02', true),
('NRF 2027: Retail''s Big Show', '미국', '뉴욕', '', 'IT', '2027-01-10', '2027-01-12', true),
('PACK EXPO Las Vegas 2027', '미국', '라스베이거스', '', '제조·산업기술', '2027-09-27', '2027-09-29', true),
('CAMX 2026', '미국', '애틀랜타', '', '제조·산업기술', '2026-09-21', '2026-09-24', true),
('LOUPE Americas', '미국', '시카고', '', '제조', '2026-09-15', '2026-09-17', true),
('HIMSS Global Health Conference & Exhibition 2027', '미국', '시카고', '', '의료·IT', '2027-04-05', '2027-04-08', true),
('PAX West 2026', '미국', '시애틀', '', 'IT', '2026-09-04', '2026-09-07', true),
('IADC Drilling Middle East 2026', '아랍에미리트', '아부다비', '', '에너지', '2026-09-29', '2026-09-30', true),
('National Plastics Conference 2026', '미국', '휴스턴', '', '제조', '2026-09-14', '2026-09-17', true),
('bauma Conexpo India 2026', '인도', '그레이터노이다', '', '건설·제조', '2026-09-28', '2026-10-01', true),
('POWTECH TECHNOPHARM 2026', '독일', '뉘른베르크', '', '제조·산업기술', '2026-09-29', '2026-10-01', true),
('PTC Asia 2026', '중국', '상하이', '', '제조·산업기술', '2026-11-03', '2026-11-06', true),
('LMT LAB DAY Chicago 2027', '미국', '시카고', '', '의료', '2027-02-25', '2027-02-27', true),
('EXPOMIN 2026', '멕시코', '멕시코시티', '', '산업기술', '2027-04-20', '2027-04-24', true),
('Monaco Yacht Show 2026', '모나코', '모나코', '', '문화', '2026-09-23', '2026-09-26', true),
('ASEAN Food & Beverage Exhibition 2026', '말레이시아', '쿠알라룸푸르', '', '식음료·외식', '2026-09-10', '2026-09-12', true),
('Expo SICAM Pordenone 2026', '이탈리아', '포르데노네', '', '건축·인테리어', '2026-10-20', '2026-10-23', true),
('Formnext 2026', '독일', '프랑크푸르트', '', '제조·산업기술', '2026-11-17', '2026-11-20', true),
('NATEXPO 2026', '프랑스', '리옹', '', '식음료', '2026-09-28', '2026-09-29', true),
('MAPIC 2026', '프랑스', '칸', '', '기타', '2026-11-03', '2026-11-04', true),
('SIAL China Shenzhen 2026', '중국', '선전', '', '식음료', '2026-08-31', '2026-09-02', true),
('ASEAN SHOP 2026', '말레이시아', '쿠알라룸푸르', '', '식음료·라이프스타일·제조', '2026-09-10', '2026-09-12', true),
('Manufacturing World Osaka 2026', '일본', '오사카', '', '제조·산업기술', '2026-10-07', '2026-10-09', true),
('LogiMAT 2027', '독일', '슈투트가르트', '', '제조·산업기술', '2027-03-16', '2027-03-18', true),
('Africa Tech Festival 2026', '남아프리카공화국', '케이프타운', '', 'IT', '2026-11-17', '2026-11-19', true),
('Electricity Transformation Canada 2026', '캐나다', '토론토', '', '에너지', '2026-10-19', '2026-10-21', true),
('SXSW 2027 (South by Southwest)', '미국', '오스틴', '', 'IT·문화·예술', '2027-03-07', '2027-03-15', true),
('Web Summit Qatar 2027', '아랍에미리트', '도하', '', 'IT', '2027-01-31', '2027-02-03', true),
('CARAVAN SALON Düsseldorf 2026', '독일', '뒤셀도르프', '', '제조', '2026-08-28', '2026-09-06', true),
('IDS Cologne 2027', '독일', '쾰른', '', '의료', '2027-03-16', '2027-03-20', true),
('Pet Fair South East Asia 2026', '태국', '방콕', '', '기타', '2026-10-28', '2026-10-30', true),
('BAU 2027 (Munich)', '독일', '뮌헨', '', '건축·건설', '2027-01-11', '2027-01-15', true),
('World Economic Forum Annual Meeting 2027', '스위스', NULL, '', '기타', '2027-01-18', '2027-01-22', true),
('IT&CM Asia 2026', '태국', '방콕', '', NULL, '2026-09-22', '2026-09-24', true),
('BATIMAT 2026', '프랑스', '파리', '', '건축·건설·인테리어', '2026-09-28', '2026-10-01', true),
('ChinaJoy 2026', '중국', '상하이', '', 'IT', '2026-07-31', '2026-08-03', true),
('DEFEA 2027', '그리스', '아테네', '', '보안', '2027-05-18', '2027-05-20', true),
('IHRSA/Fitness Brasil 2026', '브라질', '상파울루', '', '헬스케어·라이프스타일', '2026-08-27', '2026-08-29', true),
('PharmaLab EXPO Osaka 2026', '일본', '오사카', '', '의료·헬스케어', '2026-09-30', '2026-10-02', true),
('EXPO FLOR ECUADOR', '에콰도르', '키토', '', '기타', '2026-10-06', '2026-10-08', true),
('IBTM World 2026', '스페인', '바르셀로나', '', '라이프스타일', '2026-11-17', '2026-11-19', true),
('WorldFood Expo 2026', '러시아', '모스크바', '', '식음료', '2026-09-15', '2026-09-18', true),
('ASEAN Expo 2026', '사우디아라비아', '제다', '', '기타', '2026-08-06', '2026-08-08', true),
('DMEXCO 2026', '독일', '쾰른', '', 'IT', '2026-09-23', '2026-09-24', true),
('ICAST 2026', '미국', '올랜도', '', 'IT·전자', '2026-07-14', '2026-07-17', true),
('Texworld Paris 2026', '프랑스', '파리', '', '패션', '2026-08-31', '2026-09-02', true),
('Lightweight Asia 2026', '중국', '상하이', '', '제조·산업기술', '2026-07-08', '2026-07-10', true),
('VIV MEA 2027', '아랍에미리트', '아부다비', '', '제조', '2027-11-23', '2027-11-25', true),
('Gartner IT Symposium/Xpo 2026 Gold Coast', '호주', '골드코스트', '', 'IT', '2026-09-14', '2026-09-16', true),
('ArabPlast 2027', '아랍에미리트', '두바이', '', '제조', '2027-03-24', '2027-03-26', true),
('Seafood Directions 2026', '호주', '시드니', '', '식음료', '2026-07-28', '2026-07-30', true),
('Paris Photo 2026', '프랑스', '파리', '', '문화·예술', '2026-11-12', '2026-11-15', true),
('SiGMA North America 2026', '멕시코', '멕시코시티', '', '기타', '2026-09-01', '2026-09-03', true),
('Intersolar Middle East 2026', '아랍에미리트', '두바이', '', '에너지·전력', '2026-09-01', '2026-09-03', true),
('Black Hat USA 2026', '미국', '라스베이거스', '', 'IT·보안', '2026-08-01', '2026-08-06', true),
('ExpoNaval 2026', '칠레', '발파라이소', '', '건설', '2026-12-01', '2026-12-03', true),
('Essence of Africa 2026', '탄자니아', '잔지바르', '', '문화·라이프스타일', '2026-10-20', '2026-10-22', true),
('Frankfurt Book Fair 2026', '독일', '프랑크푸르트', '', '출판·문화', '2026-10-07', '2026-10-11', true),
('Motek 2026', '독일', '슈투트가르트', '', '제조·산업기술', '2026-10-06', '2026-10-08', true),
('Detroit Auto Show 2027', '미국', '디트로이트', '', '제조', '2027-01-12', '2027-01-24', true),
('Paperworld China 2026', '중국', '상하이', '', '라이프스타일', '2026-11-20', '2026-11-22', true),
('Singapore Beauty & Wellness Expo 2026', '싱가포르', '싱가포르', '', '뷰티', '2026-08-13', '2026-08-15', true),
('IAA TRANSPORTATION 2026', '독일', '하노버', '', '제조·산업기술', '2026-09-15', '2026-09-20', true),
('BI-MU 2026', '이탈리아', '밀라노', '', '제조·산업기술', '2026-10-13', '2026-10-16', true),
('CPHI Korea 2026', '한국', '서울', '', '의료·헬스케어', '2026-08-25', '2026-08-27', true),
('Gwangju International Biennale 2026', '한국', '광주', '', '문화·예술', '2026-09-03', '2026-11-08', true),
('GIFA Southeast Asia 2027', '태국', '방콕', '', '산업기술·제조', '2027-09-15', '2027-09-17', true),
('spoga horse 2027', '독일', '쾰른', '', '라이프스타일', '2027-01-30', '2027-02-01', true),
('Hong Kong Cat Fans Expo 2026', '홍콩', '홍콩', '', '기타', '2026-08-01', '2026-08-03', true),
('COSME Week OSAKA 2026', '일본', '오사카', '', '뷰티', '2026-09-30', '2026-10-02', true),
('IAA Mobility 2027', '독일', '뮌헨', '', '제조·산업기술·에너지·전력·배터리·IT', '2027-09-07', '2027-09-12', true),
('transport logistic 2027', '독일', '뮌헨', '', 'IT·산업기술', '2027-04-26', '2027-04-29', true),
('LOUPE Europe 2027 (formerly Labelexpo Europe)', '스페인', '바르셀로나', '', '제조·출판', '2027-10-05', '2027-10-08', true),
('2026 Shanghai International Metal Recycling Expo', '중국', '상하이', '', '산업기술·제조·에너지', '2026-07-08', '2026-07-10', true),
('Oracle AI World 2026', '미국', '라스베이거스', '', 'IT', '2026-10-25', '2026-10-28', true),
('Florida SuperCon 2026', '미국', '마이애미', '', '문화·예술', '2026-07-10', '2026-07-12', true),
('The smarter E South America 2026', '브라질', '상파울루', '', '에너지·전력', '2026-08-25', '2026-08-27', true),
('Zak Glass Technology Expo 2026', '인도', '뉴델리', '', '제조', '2026-12-10', '2026-12-12', true),
('Labelexpo Europe 2027 (Barcelona)', '스페인', '바르셀로나', '', '제조', '2027-10-05', '2027-10-08', true),
('UN Ocean Conference 2028', '한국', '서울', '', '문화', '2028-06-01', '2028-06-30', true),
('World Health Expo Osaka 2026', '일본', '오사카', '', '의료·헬스케어', '2026-07-02', '2026-07-04', true),
('SIRHA Lyon 2027', '프랑스', '리옹', '', '식음료·외식', '2027-01-21', '2027-01-25', true),
('Smart Manufacturing Week U.S. 2027', '미국', '디트로이트', '', '제조', '2027-04-19', '2027-04-22', true),
('European Coatings Show 2027', '독일', '뉘른베르크', '', '산업기술·제조', '2027-04-27', '2027-04-29', true),
('Vogue World Milano 2026', '이탈리아', '밀라노', '', '패션', '2026-09-22', '2026-09-22', true),
('Vitrum 2026', '이탈리아', '밀라노', '', '제조', '2026-09-16', '2026-09-19', true),
('African Mining Week 2026', '남아프리카공화국', '케이프타운', '', '에너지', '2026-10-14', '2026-10-16', true),
('Highly-functional Material Week', '일본', '치바', '', '제조·산업기술', '2026-09-30', '2026-10-02', true),
('Sunbelt Agricultural Exposition 2026', '미국', '조지아', '', '제조·산업기술', '2026-10-20', '2026-10-22', true),
('SENSOR EXPO JAPAN 2026', '일본', '도쿄', '', '전자·IT', '2026-09-16', '2026-09-18', true),
('World Building Congress 2028', '중국', '베이징', '', '건축·건설', '2028-05-21', '2028-05-26', true),
('Vietnam Foodexpo 2026 (베트남 호치민 국제 식품산업 박람회)', '베트남', '호치민', '', '식음료', '2026-11-11', '2026-11-14', true),
('MobilityTech Asia Bangkok 2026', '태국', '방콕', '', '제조·전자·기타', '2026-07-01', '2026-07-03', true),
('IBIE 2026 (International Baking Industry Expo)', '미국', '라스베이거스', '', '식음료', '2026-09-13', '2026-09-16', true),
('Shanghai Design Week 2026', '중국', '상하이', '', '문화', '2026-09-10', '2026-09-20', true);

COMMIT;