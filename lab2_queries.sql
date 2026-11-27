-- 1. Вывести информацию обо всех отправителях корреспонденции весом больше 300 граммов.
SELECT DISTINCT s.*
FROM senders s
JOIN correspondence c ON c.sender_id = s.sender_id
WHERE c.weight > 300;

-- 2. Вывести трек-номера корреспонденции от отправителей с неизвестным контактным телефоном.
SELECT c.track_number
FROM correspondence c
JOIN senders s ON s.sender_id = c.sender_id
WHERE s.phone IS NULL OR TRIM(s.phone) = '';

-- 3. Создать таблицу, содержащую данные второго запроса с указанием информации об отправителях и параметров корреспонденции.
SELECT 
    c.track_number,
    c.type_id,
    c.weight,
    c.length_cm,
    c.width_cm,
    c.height_cm,
    c.stamps_sum,
    s.sender_id,
    s.last_name,
    s.first_name,
    s.middle_name,
    s.address,
    s.passport,
    s.phone
INTO unknown_phone_mail
FROM correspondence c
JOIN senders s ON s.sender_id = c.sender_id
WHERE s.phone IS NULL OR TRIM(s.phone) = '';

-- 4. Добавить в созданную таблицу всю корреспонденцию от отправителей, адреса которых содержат две улицы.
INSERT INTO unknown_phone_mail
SELECT 
    c.track_number,
    c.type_id,
    c.weight,
    c.length_cm,
    c.width_cm,
    c.height_cm,
    c.stamps_sum,
    s.sender_id,
    s.last_name,
    s.first_name,
    s.middle_name,
    s.address,
    s.passport,
    s.phone
FROM correspondence c
JOIN senders s ON s.sender_id = c.sender_id
WHERE s.address ~* '(ул\.|улица|пер\.|переулок|пр-т|проспект|ш\.|шоссе|б-р|бульвар).*?(ул\.|улица|пер\.|переулок|пр-т|проспект|ш\.|шоссе|б-р|бульвар)';
   AND NOT EXISTS (
   SELECT 1
   FROM unknown_phone_mail u
   WHERE u.track_number = c.track_number
 )
  RETURNING *;
-- Проверка содержимого таблицы после выполнения запроса:
SELECT * FROM unknown_phone_mail;

-- 5. В созданной таблице убрать все пробелы и спецсимволы из трек-номеров отправлений.
UPDATE unknown_phone_mail
SET track_number = regexp_replace(track_number, '[^A-Za-zА-Яа-я0-9]', '', 'g');

-- 6. Удалить всю корреспонденцию от отправителей с номером телефона, начинающимся и заканчивающимся на одинаковые цифры в части после кода.
DELETE FROM unknown_phone_mail
WHERE phone IS NOT NULL
  AND substring(regexp_replace(phone, '\D', '', 'g') FROM 5 FOR 1) = right(regexp_replace(phone, '\D', '', 'g'), 1);

-- 7. Посчитать средний вес и максимальные по объему параметры корреспонденции для каждого отправителя.
SELECT 
    s.sender_id,
    s.last_name,
    s.first_name,
    s.middle_name,
    ROUND(AVG(c.weight), 2) AS avg_weight,
    MAX(c.length_cm) AS max_length,
    MAX(c.width_cm) AS max_width,
    MAX(c.height_cm) AS max_height,
    MAX(c.length_cm * c.width_cm * c.height_cm) AS max_volume
FROM senders s
JOIN correspondence c ON c.sender_id = s.sender_id
GROUP BY s.sender_id, s.last_name, s.first_name, s.middle_name
ORDER BY s.sender_id; 