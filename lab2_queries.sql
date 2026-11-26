-- Подготовка данных
ALTER TABLE senders ALTER COLUMN phone DROP NOT NULL;
UPDATE senders SET phone = NULL WHERE sender_id IN (7, 9);
UPDATE senders SET address = 'Омск, ул. Мира 10, ул. Ленина 3' WHERE sender_id = 4;

-- Запрос 1: отправители корреспонденции тяжелее 300 г
SELECT DISTINCT s.*
FROM senders s
JOIN correspondence c ON c.sender_id = s.sender_id
WHERE c.weight > 300;

-- Запрос 2: трек-номера от отправителей с неизвестным телефоном
SELECT c.track_number
FROM correspondence c
JOIN senders s ON s.sender_id = c.sender_id
WHERE s.phone IS NULL;

-- Задание 3: создание таблицы по запросу 2
SELECT c.track_number, c.type_id, c.weight, c.length_cm, c.width_cm, c.height_cm, c.stamps_sum,
       s.sender_id, s.last_name, s.first_name, s.middle_name, s.address, s.passport, s.phone
INTO unknown_phone_mail
FROM correspondence c
JOIN senders s ON s.sender_id = c.sender_id
WHERE s.phone IS NULL;

-- Задание 4: INSERT SELECT, отправители с двумя улицами
INSERT INTO unknown_phone_mail
SELECT c.track_number, c.type_id, c.weight, c.length_cm, c.width_cm, c.height_cm, c.stamps_sum,
       s.sender_id, s.last_name, s.first_name, s.middle_name, s.address, s.passport, s.phone
FROM correspondence c
JOIN senders s ON s.sender_id = c.sender_id
WHERE s.address LIKE '%ул.%ул.%';

-- Задание 5: UPDATE, убрать пробелы и спецсимволы из трек-номеров
UPDATE unknown_phone_mail SET track_number = 'RA 0000007-RU' WHERE track_number = 'RA0000007RU';
UPDATE unknown_phone_mail
SET track_number = regexp_replace(track_number, '[^A-Za-z0-9]', '', 'g');

-- Задание 6: DELETE
UPDATE unknown_phone_mail SET phone = '89005550005' WHERE sender_id = 4;
DELETE FROM unknown_phone_mail
WHERE phone IS NOT NULL
  AND substring(phone, 5, 1) = right(phone, 1);

-- Запрос 7: групповой запрос
SELECT s.sender_id, s.last_name,
       ROUND(AVG(c.weight), 2) AS avg_weight,
       MAX(c.length_cm) AS max_length,
       MAX(c.width_cm) AS max_width,
       MAX(c.height_cm) AS max_height,
       MAX(c.length_cm * c.width_cm * c.height_cm) AS max_volume
FROM senders s
JOIN correspondence c ON c.sender_id = s.sender_id
GROUP BY s.sender_id, s.last_name
ORDER BY s.sender_id;