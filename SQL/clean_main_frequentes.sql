CREATE OR REPLACE TABLE `rj-cor-dev.clima_pluviometro.main_table_fields_1H_mais_frequentes` AS
SELECT *
FROM `rj-cor-dev.clima_pluviometro.main_table_fields_1H_mais_frequentes` AS m
WHERE (TIMESTAMP(DATETIME_TRUNC(m.data_hora, HOUR), 'UTC-2') = TIMESTAMP_TRUNC(m.alagamento_inicio, HOUR)OR m.alagamento_inicio IS NULL)
AND ((m.chuva_96h <> 0 AND m.alagamento_pop IS NOT NULL) OR m.alagamento_pop IS NULL);